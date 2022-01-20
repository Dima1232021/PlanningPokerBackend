# frozen_string_literal: true

class GameController < ApplicationController
  before_action :findGame,
                except: %i[joinTheGame leaveTheGame findGameYouHaveJoined giveAnAnswer removeStory]
  before_action :findInvitaion, only: %i[changeDrivingSetings]

  def joinTheGame
    urlGame = params['urlGame']
    game = Game.find_by!(url: urlGame)

    invitation = InvitationToTheGame.find_by(game_id: game.id, user_id: @current_user.id)

    unless invitation
      game.users << @current_user
      invitation = InvitationToTheGame.find_by(game_id: game.id, user_id: @current_user.id)
      ActionCable.server.broadcast "invitation_channel_#{@current_user.id}",
                                   {
                                     id: game.id,
                                     name_game: game.name_game,
                                     url: game.url,
                                     drivingName: game.driving['user_name'],
                                   }
    end

    invitation.update(join_the_game: true)

    dataUsers(game)

    stories = game.stories.select('stories.id, stories.body')
    answers = {}
    stories.map { |story| answers[story.id] = game.poll ? [] : story.answers }

    ActionCable.server.broadcast "change_players_online_channel_#{game.id}",
                                 { onlineUsers: @onlineUsers, onlinePlayers: @onlinePlayers }

    render json: {
             joinTheGame: true,
             gameId: game.id,
             driving: game.driving,
             nameGame: game.name_game,
             urlGame: game.url,
             game: {
               flipСardsAutomatically: game.flipСardsAutomatically,
               historyPoll: game.history_poll,
               idPlayersResponded: game.id_players_answers,
               poll: game.poll,
             },
             stories: stories,
             answers: answers,
             onlineUsers: @onlineUsers,
             onlinePlayers: @onlinePlayers,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { join_the_game: false }
  end

  def deleteInvited
    invitation = InvitationToTheGame.find_by!(user_id: @current_user.id, game_id: @gameId)
    invitation.destroy

    render json: { delete_invited: true }
  rescue ActiveRecord::RecordNotFound
    render json: { delete_invited: false }
  end

  def leaveTheGame
    invitation = InvitationToTheGame.find_by!(join_the_game: true, user_id: @current_user.id)
    game = Game.find(invitation.game_id)
    invitation.update(join_the_game: false)

    dataUsers(game)
    ActionCable.server.broadcast "change_players_online_channel_#{game.id}",
                                 { onlineUsers: @onlineUsers, onlinePlayers: @onlinePlayers }

    render json: { leavetTheGame: true }
  rescue ActiveRecord::RecordNotFound
    render json: { leavet_he_game: false }
  end

  def findGameYouHaveJoined
    invitation = InvitationToTheGame.find_by!(user_id: @current_user, join_the_game: true)

    game = Game.find(invitation.game_id)

    render json: {
             gameYouHaveJoined: {
               joinTheGame: true,
               urlGame: game.url,
               nameGame: game.name_game,
             },
           }
  rescue ActiveRecord::RecordNotFound
    render json: { gameYouHaveJoined: { joinTheGame: false } }
  end

  def startPoll
    storyId = params['storyId']

    story = Story.find(storyId)

    answers = story.answers.length

    if @game.driving['user_id'] == @current_user.id && answers == 0
      @game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      ActionCable.server.broadcast "game_channel_#{@gameId}", @game
    end
  end

  def flipCard
    if @game.driving['user_id'] == @current_user.id && @game.poll
      @game.update(history_poll: {}, poll: false, id_players_answers: [])

      stories = @game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "answers_channel_#{@gameId}", { answers: answers, game: @game }
    end
  end

  def resetCards
    storyId = params['storyId']
    story = Story.find(storyId)

    answers = story.answers

    if @game.driving['user_id'] == @current_user.id && answers.length != 0 && !@game.poll
      answers.destroy_all

      @game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      answer = { storyId => [] }
      ActionCable.server.broadcast "answers_channel_#{@gameId}", { game: @game, answers: answer }
    end
  end

  def giveAnAnswer
    fibonacci = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 'pass']
    storyId = params['storyId']
    game = Game.joins(:stories).find_by('stories.id = ?', storyId)

    # шукаю всіх гравців гри
    players = InvitationToTheGame.where(game_id: game.id, join_the_game: true, player: true)

    # перевіряю чи поточний гравець може давати відповідь
    players.find_by!(user_id: @current_user.id)

    # шукаю всі ІД гравців які дали відповідь
    findIdWhoGivenAnswer = game.id_players_answers

    # шукаю  ІД поточного гравця
    findIdPlayer = findIdWhoGivenAnswer.find { |id| id == @current_user.id }

    # перевіряю на правельність відповіді і чи не давав поточний гравець відповіді
    if fibonacci.include?(params['answer']) && !findIdPlayer
      # створюю відповідь і також додаю ІД в схему гри і зберігаю зміни
      Answer.create(
        body: params['answer'],
        story_id: storyId,
        user_id: @current_user.id,
        user_name: @current_user.username,
      )
      game.id_players_answers.push(@current_user.id)
      game.save

      #  перевіряю чи ведучий хоче автоматичне перевернення карт якщо да то то перевіряю чи всі гравці  дали відповідь
      if game.flipСardsAutomatically && players.size == findIdWhoGivenAnswer.size
        game.update(history_poll: {}, poll: false, id_players_answers: [])
        stories = game.stories
        answers = {}
        stories.map { |story| answers[story.id] = story.answers }
        ActionCable.server.broadcast "answers_channel_#{game.id}", { answers: answers, game: game }
      else
        ActionCable.server.broadcast "game_channel_#{game.id}", game
      end
    end
  rescue ActiveRecord::RecordNotFound
    render json: { giveAnAnswer: false }
  end

  def addHistory
    body = params['body']
    if @game.driving['user_id'] == @current_user.id
      @game.stories.build(body: body).save
      stories = @game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "stories_channel_#{@gameId}",
                                   { stories: stories, answers: answers }
    end
  end

  def editHistory
    storyId = params['storyId']
    body = params['body']
    story = Story.find(storyId)

    if @game.driving['user_id'] == @current_user.id && story.body != body
      story.update(body: body)
      stories = @game.stories
      ActionCable.server.broadcast "stories_channel_#{@gameId}", { stories: stories }
    end
  end

  def removeStory
    storyId = params['storyId']
    story = Story.find(storyId)
    game = Game.find(story.game_id)

    if game.driving['user_id'] == @current_user.id
      story.destroy
      stories = game.stories.select('stories.id, stories.body')
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "stories_channel_#{game.id}",
                                   { stories: stories, answers: answers }
    end
  end

  def changeDrivingSetings
    if @game.driving['user_id'] == @current_user.id && !@game.poll
      @invitation.update(player: !@invitation.player)
      dataUsers(@game)

      ActionCable.server.broadcast "change_players_online_channel_#{@gameId}",
                                   { onlineUsers: @onlineUsers, onlinePlayers: @onlinePlayers }
    end
  end

  def changeGameSettings
    if @game.driving['user_id'] == @current_user.id
      @game.update(flipСardsAutomatically: !@game.flipСardsAutomatically)
      ActionCable.server.broadcast "game_channel_#{@gameId}",
                                   {
                                     game: {
                                       flipСardsAutomatically: @game.flipСardsAutomatically,
                                       historyPoll: @game.history_poll,
                                       idPlayersResponded: @game.id_players_answers,
                                       poll: @game.poll,
                                     },
                                   }
    end
  end

  private

  def findGame
    @gameId = params['gameId']
    @game = Game.find(@gameId)
  end

  def findInvitaion
    @invitation = InvitationToTheGame.find_by!(game_id: @gameId, user_id: @current_user.id)
  end

  def dataUsers(game)
    @onlineUsers = []
    @onlinePlayers = []

    game
      .users
      .select(
        'users.id, users.username, invitation_to_the_games.join_the_game,invitation_to_the_games.player',
      )
      .map do |user|
        user.join_the_game && @onlineUsers.push(id: user.id, username: user.username)
        user.join_the_game && user.player &&
          @onlinePlayers.push(id: user.id, username: user.username)
      end
  end
end
