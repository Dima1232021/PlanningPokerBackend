# frozen_string_literal: true

class GameController < ApplicationController
  before_action :findGame,
                only: %i[
                  deleteGame
                  joinTheGame
                  deleteInvited
                  leaveTheGame
                  startAPoll
                  flipCard
                  resetCards
                  addHistory
                  editHistory
                  deleteHistory
                  playerSettings
                  changeCardFlipSettings
                ]
  before_action :findInvitaion,
                only: %i[joinTheGame leaveTheGame playerSettings]

  def create
    name_game = params['nameGame']
    users = params['users']
    stories = params['stories']
    justDriving = params['justDriving']

    game =
      @current_user.games.create(
        name_game: name_game,
        driving: {
          user_id: @current_user.id,
          user_name: @current_user.username,
        },
      )

    InvitationToTheGame
      .find_by!(user_id: @current_user.id, game_id: game.id)
      .update(player: !justDriving)

    users.map do |user|
      user = User.find(user['id'])

      game.users << user
      inv = InvitationToTheGame.find_by(user_id: user.id, game_id: game.id)

      data = {
        invitation_id: inv['id'],
        game_id: game.id,
        game_name: game.name_game,
      }

      ShowingGameRequestsChannel.broadcast_to user, data
    end

    stories.map { |story| game.stories.build(body: story).save }

    render json: { status: :created, game: game }
  end

  def yourGames
    games = Game.where("driving->>'user_id' = '?'", @current_user.id)

    render json: games
  end

  def deleteGame
    if @game.driving['user_id'] == @current_user.id
      @game.invitation_to_the_games.each do |inv|
        if @game.driving['user_id'] != inv.user_id
          ActionCable.server.broadcast "delete_game_channel_#{inv.user_id}",
                                       { invitation_id: inv['id'] }
        end
      end

      @game.destroy
      render json: { delete_game: true }
    else
      render json: { delete_game: false }
    end
  end

  def invitedGames
    games = []

    InvitationToTheGame
      .where(user_id: @current_user.id)
      .map do |inv|
        game = Game.find(inv.game_id)
        next unless game.driving['user_id'] != @current_user.id

        games.push(
          {
            invitation_id: inv.id,
            game_id: inv.game_id,
            game_name: game.name_game,
          },
        )
      end

    render json: games
  end

  def joinTheGame
    stories = @game.stories
    @invitation.update(join_the_game: true)

    dataUsers(@game)

    ActionCable.server.broadcast "change_players_online_channel_#{@gameId}",
                                 {
                                   onlineUsers: @onlineUsers,
                                   onlinePlayers: @onlinePlayers,
                                 }

    answers = {}
    stories.map { |story| answers[story.id] = @game.poll ? [] : story.answers }

    render json: {
             join_the_game: true,
             game: @game,
             invitation_id: @invitation.id,
             stories: stories,
             answers: answers,
             invitedUsers: @invitedUsers,
             onlineUsers: @onlineUsers,
             onlinePlayers: @onlinePlayers,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { join_the_game: false }
  end

  def deleteInvited
    invitation =
      InvitationToTheGame.find_by!(
        id: params['invitation_id'],
        user_id: @current_user.id,
      )

    invitation.destroy

    invitedPlayers =
      @game.users.select(
        'users.id, users.username, invitation_to_the_games.player',
      )

    playersOnline =
      User
        .select('users.id, users.username, invitation_to_the_games.player')
        .joins(:invitation_to_the_games)
        .where(
          'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
          @gameId,
          true,
        )

    ActionCable.server.broadcast "delete_invited_channel_#{@gameId}",
                                 {
                                   invited_players: invitedPlayers,
                                   players_online: playersOnline,
                                 }

    render json: { delete_invited: true }
  rescue ActiveRecord::RecordNotFound
    render json: { delete_invited: false }
  end

  def leaveTheGame
    @invitation.update(join_the_game: false)

    dataUsers(@game)

    ActionCable.server.broadcast "change_players_online_channel_#{@gameId}",
                                 {
                                   onlineUsers: @onlineUsers,
                                   onlinePlayers: @onlinePlayers,
                                 }

    render json: { leavet_he_game: true }
  rescue ActiveRecord::RecordNotFound
    render json: { leavet_he_game: false }
  end

  def searchGameYouHaveJoined
    invitation =
      InvitationToTheGame.find_by!(user_id: @current_user, join_the_game: true)

    game = Game.find(invitation.game_id)

    dataUsers(game)

    stories = game.stories
    answers = {}
    stories.map { |story| answers[story.id] = game.poll ? [] : story.answers }
    render json: {
             join_the_game: true,
             game: game,
             invitation_id: invitation.id,
             stories: stories,
             answers: answers,
             invitedUsers: @invitedUsers,
             onlineUsers: @onlineUsers,
             onlinePlayers: @onlinePlayers,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { join_the_game: false }
  end

  def startAPoll
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
      ActionCable.server.broadcast "answers_channel_#{@gameId}",
                                   { answers: answers, game: @game }
    end
  end

  def resetCards
    storyId = params['storyId']
    story = Story.find(storyId)

    answers = story.answers

    if @game.driving['user_id'] == @current_user.id && answers.length != 0 &&
         !@game.poll
      answers.destroy_all

      @game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      answer = { storyId => [] }
      ActionCable.server.broadcast "answers_channel_#{@gameId}",
                                   { game: @game, answers: answer }
    end
  end

  def giveAnAnswer
    fibonacci = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 'pass']
    storyId = params['storyId']
    game = Game.joins(:stories).find_by('stories.id = ?', storyId)

    # шукаю всіх гравців гри
    players =
      InvitationToTheGame.where(
        game_id: game.id,
        join_the_game: true,
        player: true,
      )

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
      if game.flipСardsAutomatically &&
           players.size == findIdWhoGivenAnswer.size
        game.update(history_poll: {}, poll: false, id_players_answers: [])
        stories = game.stories
        answers = {}
        stories.map { |story| answers[story.id] = story.answers }
        ActionCable.server.broadcast "answers_channel_#{game.id}",
                                     { answers: answers, game: game }
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

    if @game.driving['user_id'] == @current_user.id
      story.update(body: body)
      stories = @game.stories
      ActionCable.server.broadcast "stories_channel_#{@gameId}",
                                   { stories: stories }
    end
  end

  def deleteHistory
    storyId = params['storyId']
    story = Story.find(storyId)

    if @game.driving['user_id'] == @current_user.id
      story.destroy
      stories = @game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "stories_channel_#{@gameId}",
                                   { stories: stories, answers: answers }
    end
  end

  def playerSettings
    if @game.driving['user_id'] == @current_user.id && !@game.poll
      @invitation.update(player: !@invitation.player)
      dataUsers(@game)

      ActionCable.server.broadcast "change_players_online_channel_#{@gameId}",
                                   {
                                     onlineUsers: @onlineUsers,
                                     onlinePlayers: @onlinePlayers,
                                   }
    end
  end
  def changeCardFlipSettings
    if @game.driving['user_id'] == @current_user.id
      @game.update(flipСardsAutomatically: !@game.flipСardsAutomatically)
      ActionCable.server.broadcast "game_channel_#{@gameId}", @game
    end
  end

  private

  def findGame
    @gameId = params['gameId']
    @game = Game.find(@gameId)
  end

  def findInvitaion
    @invitation =
      InvitationToTheGame.find_by!(game_id: @gameId, user_id: @current_user.id)
  end

  def dataUsers(game)
    @invitedUsers = []
    @onlineUsers = []
    @onlinePlayers = []

    game
      .users
      .select(
        'users.id, users.username, invitation_to_the_games.join_the_game,invitation_to_the_games.player',
      )
      .map do |user|
        @invitedUsers.push(id: user.id, username: user.username)

        user.join_the_game &&
          @onlineUsers.push(id: user.id, username: user.username)
        user.join_the_game && user.player &&
          @onlinePlayers.push(id: user.id, username: user.username)
      end
  end
end
