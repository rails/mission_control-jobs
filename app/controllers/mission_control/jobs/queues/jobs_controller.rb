class MissionControl::Jobs::Queues::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobsScoped, MissionControl::Jobs::QueueScoped

  def show
  end

  private
    def jobs_relation
      @queue.jobs.pending
    end
end
