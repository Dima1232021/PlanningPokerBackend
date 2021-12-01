class GameController < ApplicationController
  def create
    name_game = params['nameGame']
    users = params['users']
    stories = params['stories']
    justDriving = params['justDriving']

    game =
      @current_user.games.create(
        name_game: name_game,
        driving_id: @current_user.id,
      )

    # game.invitation_to_the_games.update(to_the_game: true)

    unless justDriving
      game.update(
        users: [
          { user_id: @current_user.id, user_name: @current_user.username },
        ],
      )
    end

    users.map do |user|
      user = User.find(user['id'])
      
      game.users << user
      inv = InvitationToTheGame.where(user_id: user.id, game_id: game.id)[0]
      data = {
        invitation_id: inv['id'],
        game_id: game.id,
        game_name: game.name_game,
      }

      ShowingGameRequestsChannel.broadcast_to user, data
    end

    render json: { status: :created, game: game }
  end

  def yourGames
    games = Game.where(driving_id: @current_user.id)
    render json: games
  end

  def deleteGame
    game = Game.find(params['game_id'])

    if game.driving_id == @current_user.id
      InvitationToTheGame
        .where(game_id: params['game_id'])
        .map do |inv|
          user = User.find(inv['user_id'])
          if (game.driving_id != user.id)
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
    games =
      InvitationToTheGame
        .where(user_id: @current_user.id)
        .map do |inv|
          game = Game.find(inv.game_id)
          next {
            invitation_id: inv.id,
            game_id: inv.game_id,
            game_name: game.name_game,
          }
        end

    render json: games
  end

  def joinTheGame
    invitation = InvitationToTheGame.find(params['invitation_id'])
    game = Game.find(params['game_id'])

    if @current_user.id == invitation.user_id && game.id == invitation.game_id
      invitation.update(invitation: true)
      game.users_joined.push(
        { user_id: @current_user.id, user_name: @current_user.username },
      )
      game.save!
      render json: { status: 200, join_the_game: true, game: game }
    else
      render json: { status: 400, join_the_game: false }
    end
  end

  # def gamesYouHaveJoined
  #   games = []

  #   InvitationToTheGame
  #     .where(user_id: @current_user.id, invitation: true)
  #     .each do |inv|
  #       game = Game.find(inv.game_id)

  #       if game.driving_id != @current_user.id
  #         next games.push(
  #           {
  #             game_id: game.id,
  #             game_name: game.name_game,
  #             invitation_id: inv.id,
  #           },
  #         )
  #       end
  #     end
  #   render json: games
  # end

  def leaveTheGame; end

  def deleteInvited
    InvitationToTheGame.find(params['invitation_id']).destroy
    render json: { status: 200, delete_invited: true }
  end
end
