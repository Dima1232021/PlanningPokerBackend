# frozen_string_literal: true

class GameController < ApplicationController
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
      .find_by(user_id: @current_user.id, game_id: game.id)
      .update(player: !justDriving)

    users.map do |user|
      user = User.find(user['id'])

      game.users << user
      inv = InvitationToTheGame.find_by(user_id: user.id, game_id: game.id)

      # game.players.push({ user_id: user.id, user_name: user.username })
      # game.save!

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
    game = Game.find(params['game_id'])

    if game.driving['user_id'] == @current_user.id
      game.invitation_to_the_games.each do |inv|
        if game.driving['user_id'] != inv.user_id
          ActionCable.server.broadcast "delete_game_channel_#{inv.user_id}",
                                       { invitation_id: inv['id'] }
        end
      end

      game.destroy
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
    gameId = params['game_id']

    invitation =
      InvitationToTheGame.find_by(game_id: gameId, user_id: @current_user.id)

    game = Game.find(gameId)
    stories = game.stories
    invitation.update(join_the_game: true)

    invitedPlayers = game.users.select('users.id, users.username')

    playersOnline =
      User
        .select('users.id, users.username, invitation_to_the_games.player')
        .joins(:invitation_to_the_games)
        .where(
          'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
          game.id,
          true,
        )

    ActionCable.server.broadcast "change_players_online_channel_#{gameId}",
                                 playersOnline

    answers = {}
    stories.map { |story| answers[story.id] = game.poll ? [] : story.answers }

    render json: {
             join_the_game: true,
             game: game,
             invitation_id: invitation.id,
             stories: stories,
             answers: answers,
             invited_players: invitedPlayers,
             players_online: playersOnline,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { join_the_game: false }
  end

  def deleteInvited
    invitation = InvitationToTheGame.find(params['invitation_id'])
    gameId = invitation.game_id
    game = Game.find(gameId)

    if @current_user.id == invitation.user_id
      invitation.destroy

      invitedPlayers = game.users.select('users.id, users.username')

      playersOnline =
        User
          .select('users.id, users.username, invitation_to_the_games.player')
          .joins(:invitation_to_the_games)
          .where(
            'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
            game.id,
            true,
          )

      ActionCable.server.broadcast "delete_invited_channel_#{gameId}",
                                   {
                                     invited_players: invitedPlayers,
                                     players_online: playersOnline,
                                   }

      render json: { delete_invited: true }
    else
      render json: { delete_invited: false }
    end
  end

  def leaveTheGame
    gameId = params['game_id']
    game = Game.find(gameId)
    invitation = InvitationToTheGame.find(params['invitation_id'])

    if @current_user.id == invitation.user_id
      invitation.update(join_the_game: false)
      playersOnline =
        User
          .select('users.id, users.username, invitation_to_the_games.player')
          .joins(:invitation_to_the_games)
          .where(
            'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
            gameId,
            true,
          )

      ActionCable.server.broadcast "change_players_online_channel_#{gameId}",
                                   playersOnline

      render json: { leavet_he_game: true }
    else
      render json: { leavet_he_game: false }
    end

    invitation =
      InvitationToTheGame.find_by!(game_id: gameId, user_id: @current_user.id)

    invitation.update(join_the_game: false)

    playersOnline =
      User
        .select('users.id, users.username, invitation_to_the_games.player')
        .joins(:invitation_to_the_games)
        .where(
          'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
          gameId,
          true,
        )

    ActionCable.server.broadcast "change_players_online_channel_#{gameId}",
                                 playersOnline

    render json: { leavet_he_game: true }
  rescue ActiveRecord::RecordNotFound
    render json: { leavet_he_game: false }
  end

  def searchGameYouHaveJoined
    invitation =
      InvitationToTheGame.find_by!(user_id: @current_user, join_the_game: true)

    game = Game.find(invitation.game_id)

    invitedPlayers =
      game.users.select(
        'users.id, users.username, invitation_to_the_games.player',
      )

    playersOnline =
      User
        .select('users.id, users.username, invitation_to_the_games.player')
        .joins(:invitation_to_the_games)
        .where(
          'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
          game.id,
          true,
        )

    stories = game.stories
    answers = {}
    stories.map { |story| answers[story.id] = game.poll ? [] : story.answers }
    render json: {
             join_the_game: true,
             game: game,
             invitation_id: invitation.id,
             stories: stories,
             answers: answers,
             invited_players: invitedPlayers,
             players_online: playersOnline,
           }
  rescue ActiveRecord::RecordNotFound
    render json: { join_the_game: false }
  end

  def startAPoll
    storyId = params['storyId']
    gameId = params['gameId']

    story = Story.find(storyId)
    game = Game.find(gameId)

    answers = story.answers.length

    if game.driving['user_id'] == @current_user.id && answers == 0
      game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      ActionCable.server.broadcast "game_channel_#{story.game_id}", game
    end
  end

  def flipCard
    gameId = params['gameId']
    game = Game.find(gameId)

    if game.driving['user_id'] == @current_user.id && game.poll
      game.update(history_poll: {}, poll: false, id_players_answers: [])

      stories = game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "answers_channel_#{gameId}",
                                   { answers: answers, game: game }
    end
  end

  def resetCards
    storyId = params['storyId']
    gameId = params['gameId']

    story = Story.find(storyId)
    game = Game.find(gameId)

    answers = story.answers

    if game.driving['user_id'] == @current_user.id && answers.length != 0 &&
         !game.poll
      answers.destroy_all
      game.update(history_poll: { id: story.id, body: story.body }, poll: true)
      ActionCable.server.broadcast "answers_channel_#{gameId}",
                                   { game: game, answers: answers }
    end
  end

  def giveAnAnswer
    fibonacci = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 'pass']
    storyId = params['storyId']
    story = Story.find(storyId)
    game = Game.find(story.game_id)

    players =
      InvitationToTheGame.find_by!(
        user_id: @current_user.id,
        game_id: game.id,
        join_the_game: true,
        player: true,
      )

    playerAnswer = game.id_players_answers.find { |id| id == @current_user.id }

    if fibonacci.include?(params['answer']) && !playerAnswer
      Answer.create(
        body: params['answer'],
        story_id: storyId,
        user_id: @current_user.id,
        user_name: @current_user.username,
      )
      game.id_players_answers += [@current_user.id]
      game.save!
      ActionCable.server.broadcast "game_channel_#{game.id}", game
    end
  rescue ActiveRecord::RecordNotFound
    render json: { giveAnAnswer: false }
  end

  def addHistory
    gameId = params['gameId']
    body = params['body']
    game = Game.find(gameId)
    if game.driving['user_id'] == @current_user.id
      game.stories.build(body: body).save
      stories = game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "stories_channel_#{gameId}",
                                   { stories: stories, answers: answers }
    end
  end

  def editHistory
    storyId = params['storyId']
    gameId = params['gameId']
    body = params['body']

    story = Story.find(storyId)
    game = Game.find(gameId)

    if game.driving['user_id'] == @current_user.id
      story.update(body: body)
      stories = game.stories
      ActionCable.server.broadcast "stories_channel_#{gameId}",
                                   { stories: stories }
    end
  end

  def deleteHistory
    gameId = params['gameId']
    storyId = params['storyId']
    story = Story.find(storyId)
    game = Game.find(gameId)

    if game.driving['user_id'] == @current_user.id
      story.destroy
      stories = game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "stories_channel_#{gameId}",
                                   { stories: stories, answers: answers }
    end
  end

  def changeHostSettings
    gameId = params['gameId']
    game = Game.find!(gameId)

    if game.driving['user_id'] == @current_user.id
      puts '|||||||||||||||||||'
      p game.driving['user_id']
    end

    # invitation =
    #   InvitationToTheGame.find_by!(
    #     game_id: gameId,
    #     user_id: @current_user.id.id,
    #   )

    # player = invitation.player

    # if game.driving['user_id'] == @current_user.id
    #   invitation.update(player: !player)
    #   playersOnline =
    #     User
    #       .select('users.id, users.username, invitation_to_the_games.player')
    #       .joins(:invitation_to_the_games)
    #       .where(
    #         'invitation_to_the_games.game_id = ? AND invitation_to_the_games.join_the_game = ?',
    #         game.id,
    #         true,
    #       )
    #   ActionCable.server.broadcast "change_players_online_channel_#{gameId}",
    #                                playersOnline
    # end
  end
end
