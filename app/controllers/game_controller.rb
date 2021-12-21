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

    game.build_timer.save

    unless justDriving
      game.players.push(
        { user_id: @current_user.id, user_name: @current_user.username },
      )
      game.save!
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

          if game.driving['user_id'] != user.id
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
    invitationId = params['invitation_id']
    gameId = params['game_id']

    invitation =
      if invitationId.nil?
        InvitationToTheGame.where(game_id: gameId, user_id: @current_user.id)[0]
      else
        InvitationToTheGame.find(params['invitation_id'])
      end

    game = Game.find(gameId)

    if @current_user.id == invitation.user_id && game.id == invitation.game_id
      stories = game.stories
      invitation.update(to_the_game: true)
      game.users_joined.push(
        { user_id: @current_user.id, user_name: @current_user.username },
      )
      game.save!
      ActionCable.server.broadcast "game_channel_#{gameId}", game

      answers = {}
      stories.map do |story|
        answers[story.id] =
          if game['selected_story'] && game['selected_story']['id']
            []
          else
            story.answers
          end
      end

      render json: {
               join_the_game: true,
               game: game,
               invitation_id: invitation.id,
               stories: stories,
               answers: answers,
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
      invitation.destroy
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
      newUserJoined =
        game.users_joined.reject do |user|
          user['user_id'] == invitation.user_id
        end
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

    if invitation.nil?
      render json: { join_the_game: false }
    else
      game = Game.find(invitation.game_id)
      stories = game.stories
      answers = {}
      stories.map do |story|
        answers[story.id] =
          if game['selected_story'] && game['selected_story']['id'] == story.id
            []
          else
            story.answers
          end
      end
      render json: {
               join_the_game: true,
               game: game,
               invitation_id: invitation.id,
               stories: stories,
               answers: answers,
             }
    end
  end

  def startAPoll
    storyId = params['storyId']
    gameId = params['gameId']

    story = Story.find(storyId)
    game = Game.find(gameId)

    answers = story.answers.length

    if game.driving['user_id'] == @current_user.id && answers == 0
      game.update(selected_story: { id: story.id, body: story.body })
      ActionCable.server.broadcast "game_channel_#{story.game_id}", game
    end
  end

  def finishAPoll
    gameId = params['gameId']
    game = Game.find(gameId)

    if game.driving['user_id'] == @current_user.id
      game.update(selected_story: {}, id_players_responded: [])
      stories = game.stories
      answers = {}
      stories.map { |story| answers[story.id] = story.answers }
      ActionCable.server.broadcast "answers_channel_#{gameId}",
                                   { answers: answers, game: game }
    end
  end

  def giveAnAnswer
    fibonacci = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 'pass']
    story = Story.find(params['storyId'])
    game = Game.find(story.game_id)

    playersOnline =
      game
        .users_joined
        .each_with_object([]) do |user, newArr|
          game.players.each do |value|
            newArr << user if user['user_id'] == value['user_id']
          end
        end

    unless game
             .players
             .detect { |user| user['user_id'] == @current_user.id }
             .nil?
      story.users << @current_user
      answer = Answer.find_by(story_id: story.id, user_id: @current_user.id)

      if fibonacci.include? params['answer']
        answer.update(body: params['answer'])
        game.id_players_responded.push(@current_user.id)
        game.save!

        if game.id_players_responded.length == playersOnline.length
          game.update(selected_story: {}, id_players_responded: [])
          stories = game.stories
          answers = {}
          stories.map { |story| answers[story.id] = story.answers }
          ActionCable.server.broadcast "answers_channel_#{story.game_id}",
                                       { answers: answers, game: game }
        else
          ActionCable.server.broadcast "game_channel_#{story.game_id}", game
        end
      end
    end
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
end
