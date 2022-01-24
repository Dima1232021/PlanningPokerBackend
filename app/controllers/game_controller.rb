# frozen_string_literal: true

class GameController < ApplicationController
  before_action :findGame, except: %i[joinTheGame leaveTheGame findGameYouHaveJoined removeStory]

  # слідуючі 4 блоки описують функціонал: приєднання та виходу із гри, видалиння та пошуку запрошення до гри
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
    ActionCableDataUsersChannel(game.id)

    findAnswers(game)

    render json: {
             joinTheGame: true,
             stories: @stories,
             answers: @answers,
             onlineUsers: @onlineUsers,
             game: game,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { joinTheGame: false }
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

    checkFlipСardsAutomatically(game)

    dataUsers(game)

    ActionCableDataUsersChannel(game.id)

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

  # слідуючі 3 блоки описують функціонал: почтку, закунчення та рестарту гри
  def startPoll
    storyId = params['storyId']

    story = Story.find(storyId)

    answers = story.answers.length

    findPlayers = InvitationToTheGame.where(game_id: @gameId, player: true)

    if @game.driving['user_id'] == @current_user.id && answers == 0 && findPlayers.size != 0
      @game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      ActionCableGameChannel()
    end
  end

  def flipCard
    if @game.driving['user_id'] == @current_user.id && @game.poll
      @game.update(history_poll: {}, poll: false, id_players_answers: [])

      ActionCableAnswersChannel(@game)
    end
  end

  def resetCards
    storyId = params['storyId']
    story = Story.find(storyId)

    allAnswers = story.answers

    findPlayers = InvitationToTheGame.where(game_id: @gameId, player: true)

    if @game.driving['user_id'] == @current_user.id && allAnswers.length != 0 && !@game.poll &&
         findPlayers.size != 0
      allAnswers.destroy_all

      @game.update(history_poll: { id: story.id, body: story.body }, poll: true)

      ActionCableAnswersChannel(@game)
    end
  end

  # слідуючий  блок описує функціонал: запису відповіді
  def giveAnAnswer
    fibonacci = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 'pass']

    # шукаю всіх гравців гри
    players = InvitationToTheGame.where(game_id: @gameId, join_the_game: true, player: true)

    # перевіряю чи поточний гравець може давати відповідь
    players.find_by!(user_id: @current_user.id)

    # шукаю всі ІД гравців які дали відповідь
    findIdWhoGivenAnswer = @game.id_players_answers

    # шукаю  ІД поточного гравця щоб зрозуміти чи давав він відповідь
    findIdPlayer = findIdWhoGivenAnswer.find { |id| id == @current_user.id }

    # перевіряю на правельність відповіді і чи не давав поточний гравець відповіді
    if fibonacci.include?(params['answer']) && !findIdPlayer
      # створюю відповідь і також додаю ІД в схему гри і зберігаю зміни
      Answer.create(
        body: params['answer'],
        story_id: @game.history_poll['id'],
        user_id: @current_user.id,
        user_name: @current_user.username,
      )
      @game.id_players_answers.push(@current_user.id)
      @game.save

      #  перевіряю чи ведучий хоче автоматичне перевернення карт якщо да то перевіряю чи всі гравці  дали відповідь
      if @game.flipСardsAutomatically && players.size <= findIdWhoGivenAnswer.size
        @game.update(history_poll: {}, poll: false, id_players_answers: [])
        ActionCableAnswersChannel(@game)
      else
        ActionCableGameChannel()
      end
    end
  end

  # слідуючі 3 блоки описують функціонал: створення, редагування та видалення історії для гри
  def addHistory
    body = params['body']
    if @game.driving['user_id'] == @current_user.id
      @game.stories.build(body: body).save
      findAnswers(@game)
      ActionCable.server.broadcast "stories_channel_#{@gameId}",
                                   { stories: @stories, answers: @answers }
    end
  end

  def editHistory
    storyId = params['storyId']
    body = params['body']
    story = Story.find(storyId)

    if @game.driving['user_id'] == @current_user.id && story.body != body &&
         @game.history_poll['id'] != storyId
      story.update(body: body)
      stories = @game.stories
      ActionCable.server.broadcast "stories_channel_#{@gameId}", { stories: stories }
    end
  end

  def removeStory
    storyId = params['storyId']
    story = Story.find(storyId)
    game = Game.find(story.game_id)

    if game.driving['user_id'] == @current_user.id && game.history_poll['id'] != storyId
      story.destroy
      findAnswers(game)
      ActionCable.server.broadcast "stories_channel_#{game.id}",
                                   { stories: @stories, answers: @answers }
    end
  end

  # слідуючі 3 блоки описують функціонал: зміни настройок автоматичного перевертання карт і зміни приймання участі у грі та зміна дозволу приймання участі у грі

  def changeGameSettingsAutoFlipCards
    if @game.driving['user_id'] == @current_user.id
      @game.update(flipСardsAutomatically: !@game.flipСardsAutomatically)

      checkFlipСardsAutomatically(@game)

      ActionCable.server.broadcast "setings_game_channel_#{@gameId}",
                                   { flipСardsAutomatically: @game.flipСardsAutomatically }
    end
  end

  def changeGameSettingsStatusChange
    if @game.driving['user_id'] == @current_user.id
      @game.update(statusChange: !@game.statusChange)

      ActionCable.server.broadcast "setings_game_channel_#{@gameId}",
                                   { statusChange: @game.statusChange }
    end
  end

  def changeStatusUser
    userId = params['userId']
    if @game.driving['user_id'] == @current_user.id || userId == @current_user.id
      invitation = InvitationToTheGame.find_by!(user_id: userId, game_id: @gameId)
      invitation.update(player: !invitation.player)
      dataUsers(@game)

      checkFlipСardsAutomatically(@game)

      ActionCableDataUsersChannel(@gameId)
    end
  end

  private

  def findGame
    @gameId = params['gameId']
    @game = Game.find(@gameId)
  end

  def findAnswers(game)
    @stories = game.stories.select('stories.id, stories.body')
    @answers = {}
    @stories.map do |story|
      @answers[story.id] = story.answers.select('answers.id, answers.body,  answers.user_name')
    end
  end

  def dataUsers(game)
    @onlineUsers = []

    game
      .users
      .select(
        'users.id, users.username, invitation_to_the_games.join_the_game,invitation_to_the_games.player',
      )
      .map do |user|
        user.join_the_game &&
          @onlineUsers.push(id: user.id, username: user.username, player: user.player)
      end
  end

  def ActionCableGameChannel
    ActionCable.server.broadcast "game_channel_#{@gameId}",
                                 {
                                   game: {
                                     historyPoll: @game.history_poll,
                                     idPlayersResponded: @game.id_players_answers,
                                     poll: @game.poll,
                                   },
                                 }
  end

  def ActionCableAnswersChannel(game)
    findAnswers(game)

    ActionCable.server.broadcast "answers_channel_#{game.id}",
                                 {
                                   answers: @answers,
                                   game: {
                                     historyPoll: game.history_poll,
                                     idPlayersResponded: game.id_players_answers,
                                     poll: game.poll,
                                   },
                                 }
  end

  def ActionCableDataUsersChannel(gameId)
    ActionCable.server.broadcast "data_users_channel_#{gameId}", { onlineUsers: @onlineUsers }
  end

  def checkFlipСardsAutomatically(game)
    if game.flipСardsAutomatically
      players = InvitationToTheGame.where(game_id: game.id, join_the_game: true, player: true)
      findIdWhoGivenAnswer = game.id_players_answers

      if players.size <= findIdWhoGivenAnswer.size
        game.update(history_poll: {}, poll: false, id_players_answers: [])
        answers = {}
        game.stories.map { |story| answers[story.id] = story.answers }

        ActionCable.server.broadcast "answers_channel_#{game.id}",
                                     {
                                       answers: answers,
                                       game: {
                                         historyPoll: game.history_poll,
                                         idPlayersResponded: game.id_players_answers,
                                         poll: game.poll,
                                       },
                                     }
      end
    end
  end
end
