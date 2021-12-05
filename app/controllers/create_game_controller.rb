class CreateGameController < ApplicationController
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

    unless justDriving
      game.players.push(
        { user_id: @current_user.id, user_name: @current_user.username },
      )
    end

    users.map do |user|
      user = User.find(user['id'])

      game.users << user
      inv = InvitationToTheGame.where(user_id: user.id, game_id: game.id)[0]

      game.players.push({ user_id: user.id, user_name: user.username })
      game.save!
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
      InvitationToTheGame
        .where(game_id: params['game_id'])
        .map do |inv|
          user = User.find(inv['user_id'])

          if (game.driving['user_id'] != user.id)
            DeleteInvitationChannel.broadcast_to user,
                                                 { invitation_id: inv['id'] }
          end
        end

      game.destroy
      render json: { status: 200, delete_game: true }
    else
      render json: { status: 400, delete_game: false }
    end
  end

  def invitedGames
    games = []

    InvitationToTheGame
      .where(user_id: @current_user.id)
      .map do |inv|
        game = Game.find(inv.game_id)
        if game.driving['user_id'] != @current_user.id
          games.push(
            {
              invitation_id: inv.id,
              game_id: inv.game_id,
              game_name: game.name_game,
            },
          )
        end
      end

    render json: games
  end

  def joinTheGame
    invitationId = params['invitation_id']
    gameId = params['game_id']

    if !!invitationId
      invitation = InvitationToTheGame.find(params['invitation_id'])
    else
      invitation =
        InvitationToTheGame.where(game_id: gameId, user_id: @current_user.id)[0]
    end

    game = Game.find(gameId)

    if @current_user.id == invitation.user_id && game.id == invitation.game_id
      invitation.update(to_the_game: true)

      game.users_joined.push(@current_user.id)
      game.save!
      ActionCable.server.broadcast "game_channel_#{gameId}", game
      render json: {
               join_the_game: true,
               game: game,
               invitation_id: invitation.id,
             }
    else
      render json: { join_the_game: false }
    end
  end

  def deleteInvited
    invitation = InvitationToTheGame.find(params['invitation_id'])
    gameId = invitation.game_id
    game = Game.find(gameId)

    if @current_user.id == invitation.user_id
      plauers =
        game.players.select { |user| user['user_id'] != invitation.user_id }
      game.update(players: plauers)
      invitation.destroy
      ActionCable.server.broadcast "game_channel_#{gameId}", game
      render json: { delete_invited: true }
    else
      render json: { delete_invited: false }
    end
  end

  def leaveTheGame
    gameId = params['game_id']
    game = Game.find(gameId)
    invitation = InvitationToTheGame.find(params['invitation_id'])

    if (@current_user.id == invitation.user_id)
      newUserJoined =
        game.users_joined.select { |user_id| user_id != invitation.user_id }
      invitation.update(to_the_game: false)
      game.update(users_joined: newUserJoined)
      ActionCable.server.broadcast "game_channel_#{gameId}", game
      render json: { leavet_he_game: true }
    else
      render json: { leavet_he_game: false }
    end
  end

  def searchGameYouHaveJoined
    invitation =
      InvitationToTheGame.where(user_id: @current_user, to_the_game: true)[0]

    if !!invitation
      game = Game.find(invitation.game_id)
      render json: {
               join_the_game: true,
               game: game,
               invitation_id: invitation.id,
             }
    else
      render json: { join_the_game: false }
    end
  end
end
