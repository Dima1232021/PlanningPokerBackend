class GamesController < ApplicationController
  before_action :findGame, only: %i[deleteGame]

  def games
    userId = @current_user.id
    ownGames = Game.where("driving->>'user_id' = '?'", userId).select('id, name_game, url')

    gamesInvitation =
      Game
        .joins(:invitation_to_the_games)
        .where("driving->>'user_id' != '?' AND invitation_to_the_games.user_id = ?", userId, userId)
        .map do |game|
          {
            id: game.id,
            name_game: game.name_game,
            url: game.url,
            drivingName: game.driving['user_name'],
          }
        end

    render json: { ownGames: ownGames, gamesInvitation: gamesInvitation }
  end

  def createGame
    nameGame = params['nameGame']
    stories = params['stories']
    player = params['player']
    autoFlip = params['autoFlip']

    createUrl = ''
    characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    (1..30).each { |i| createUrl += characters[rand(characters.size)] }

    game =
      @current_user.games.create(
        url: createUrl,
        name_game: nameGame,
        flipСardsAutomatically: autoFlip,
        driving: {
          user_id: @current_user.id,
          user_name: @current_user.username,
        },
      )

    game.save!

    InvitationToTheGame.find_by!(user_id: @current_user.id, game_id: game.id).update(player: player)

    stories.map { |story| game.stories.build(body: story).save }

    render json: { create: true, game: game }
  end

  def deleteGame
    if @game.driving['user_id'] == @current_user.id
      @game.invitation_to_the_games.each do |inv|
        if @game.driving['user_id'] != inv.user_id
          ActionCable.server.broadcast "delete_invited_channel_#{inv.user_id}",
                                       { invitationId: inv['id'] }
        end
      end

      @game.destroy
      render json: { delete_game: true }
    else
      render json: { delete_game: false }
    end
  end

  private

  def findGame
    @gameId = params['gameId']
    @game = Game.find(@gameId)
  end
end
