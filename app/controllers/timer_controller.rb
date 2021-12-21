class TimerController < ApplicationController
  def setTimer
    gameId = params['gameId']
    timer = params['timer']

    Game.find(1).timer.update(timer: timer)
  end
end
