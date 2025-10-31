class MissionControl::Jobs::RecurringTasksController < MissionControl::Jobs::ApplicationController
  before_action :ensure_supported_recurring_tasks
  before_action :set_recurring_task, only: [ :show, :update ]
  before_action :ensure_recurring_task_can_be_enqueued, only: :update

  def index
    @recurring_tasks = MissionControl::Jobs::Current.server.recurring_tasks
  end

  def show
    @jobs_page = MissionControl::Jobs::Page.new(@recurring_task.jobs, page: params[:page].to_i)
  end

  def update
    if (job = @recurring_task.enqueue) && job.successfully_enqueued?
      redirect_to application_job_path(@application, job.job_id), notice: "Enqueued recurring task #{@recurring_task.id}"
    else
      redirect_to application_recurring_task_path(@application, @recurring_task.id), alert: "Something went wrong enqueuing this recurring task"
    end
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

    def ensure_recurring_task_can_be_enqueued
      unless @recurring_task.runnable?
        redirect_to application_recurring_task_path(@application, @recurring_task.id), alert: "This task can't be enqueued"
      end
    end
end
