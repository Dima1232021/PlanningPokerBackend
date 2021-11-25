class GameController < ApplicationController
  def create
    name_game = params['nameGame']
    users_joined = params['users']
    stories = params['stories']
    justDriving = params['justDriving']

    game =
      @current_user.games.create(
        name_game: name_game,
        driving_id: @current_user.id,
      )

    game.invitation_to_the_games.update(invitation: true)

    unless justDriving
      game.update(
        users_joined: [
          { username: @current_user.id, email: @current_user.email },
        ],
      )
    end

    users_joined.map do |user|
      user = User.find(user['id'])
      game.users << user
      inv = InvitationToTheGame.where(user_id: user.id, game_id: game.id)[0]
      ShowingGameRequestsChannel.broadcast_to user,
                                              {
                                                invitation_id: inv['id'],
                                                game_id: game.id,
                                                game_name: game.name_game,
                                              }
    end

    render json: { status: :created, game: game }
  end

  def yourGames
    games = Game.where(driving_id: @current_user.id)
    render json: games
  end

  def invitedGames
    games =
      InvitationToTheGame
        .where(user_id: @current_user.id, invitation: false)
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

  def deleteGame
    Game.find(params['game_id']).destroy
    render json: { status: 200, delete_game: true }
  end

  def deleteInvited
    InvitationToTheGame.find(params['invitation_id']).destroy
    render json: { status: 200, delete_invited: true }
  end

  def joinTheGame
    invitation = InvitationToTheGame.find(params['invitation_id'])
    game = Game.find(params['game_id'])

    invitation.update(invitation: true)

    game.joined.push(
      { user_id: @current_user.id, username: @current_user.username },
    )
    game.save!

    render json: { status: 200, join_the_game: true }
  end

  def gamesYouHaveJoined
    games = []

    InvitationToTheGame
      .where(user_id: @current_user.id, invitation: true)
      .each do |inv|
        game = Game.find(inv.game_id)

        if game.driving_id != @current_user.id
          next games.push(
            {
              game_id: game.id,
              game_name: game.name_game,
              invitation_id: inv.id,
            },
          )
        end
      end
    render json: games
  end
end
