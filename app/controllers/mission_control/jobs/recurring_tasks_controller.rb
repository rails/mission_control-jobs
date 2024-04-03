class MissionControl::Jobs::RecurringTasksController < MissionControl::Jobs::ApplicationController
  before_action :ensure_supported_recurring_tasks
  before_action :set_recurring_task, only: :show

  def index
    @recurring_tasks = MissionControl::Jobs::Current.server.recurring_tasks
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@recurring_task.jobs, page: params[:page].to_i)
  end

  private
    def ensure_supported_recurring_tasks
      unless recurring_tasks_supported?
        redirect_to root_url, alert: "This server doesn't support recurring tasks"
      end
    end

    def set_recurring_task
      @recurring_task = MissionControl::Jobs::Current.server.find_recurring_task(params[:id])
    end
end
