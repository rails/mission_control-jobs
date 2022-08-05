class MissionControl::Jobs::Queues::StatusController < ApplicationController
  before_action :set_queue

  def pause
    @queue.pause
    redirect_to queues_url
  end

  def resume
    @queue.resume
    redirect_to queues_url
  end

  private
    def set_queue
      @queue = ActiveJob::Base.queue(params[:queue_id])
    end
end
