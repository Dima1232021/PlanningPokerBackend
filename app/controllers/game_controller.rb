class GameController < ApplicationController
  def create
    username = params['name']
    game = @current_user.games.create(name: username, driving: @current_user.id)

    invitation =
      InvitationToTheGame
        .where(user: @current_user.id, game: game.id)
        .update(invitation: true)

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
end
