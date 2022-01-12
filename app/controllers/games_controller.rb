class GamesController < ApplicationController
    def games
        ownGames = Game.where("driving->>'user_id' = '?'", @current_user.id).select('id, name_game')

        # linksToGames = Game.joins(:invitation_to_the_games).where("driving->>'user_id' != '?' AND invitation_to_the_games.user_id = ?", 7,7)

        render json: {ownGames: ownGames}
      end
end