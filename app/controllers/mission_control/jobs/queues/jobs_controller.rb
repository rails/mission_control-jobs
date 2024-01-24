class MissionControl::Jobs::Queues::JobsController < MissionControl::Jobs::ApplicationController
  include MissionControl::Jobs::JobScoped, MissionControl::Jobs::QueueScoped

  def show
  end

  private
    def jobs_relation
      ApplicationJob.jobs.where(queue_name: @queue.name)
    end
end
