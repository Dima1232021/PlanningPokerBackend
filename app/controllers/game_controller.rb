class GameController < ApplicationController
  def create
    username = params['name']
    users = params['users']

    game = @current_user.games.create(name: username, driving: @current_user.id)

    invitation =
      InvitationToTheGame
        .where(user: @current_user.id, game: game.id)
        .update(invitation: true)

    users.map { |user| game.users << User.find(user['id']) }

    render json: { status: :created, game: game, invitation: invitation }
  end

  def yourGames
    games = Game.where(driving: @current_user.id)
    render json: games
  end

  def invitedGames
    games =
      InvitationToTheGame
        .where(user: @current_user.id, invitation: false)
        .map do |inv|
          game = Game.find(inv.game_id)
          next {
            invitation_id: inv.id,
            game_id: inv.game_id,
            game_name: game.name,
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

        if game.driving != @current_user.id
          next games.push(
            { game_id: game.id, game_name: game.name, invitation_id: inv.id },
          )
        end
      end
    render json: games
  end
end
