require "test_helper"

class MissionControl::Jobs::RecurringTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Work around a bug in Active Job's test helpers, whereby the test adapter is returned
    # when it's set, but the queue adapter name remains to be the previous adapter, bypassing
    # the set test adapter. This can be removed once the bug is fixed in Active Job
    PauseJob.queue_adapter = :solid_queue
  end

  teardown do
    PauseJob.queue_adapter = :resque
  end

  test "get recurring task list" do
    schedule_recurring_tasks_async(wait: 2.seconds) do
      get mission_control_jobs.application_recurring_tasks_url(@application)
      assert_response :ok

      assert_select "tr.recurring_task", 1
      assert_select "td a", "periodic_pause_job"
      assert_select "td", "PauseJob"
      assert_select "td", "every second"
      assert_select "td", /less than \d+ seconds ago/
      assert_select "td.next_time", /less than \d+ seconds ago/
    end
  end

  test "get recurring task details and job list" do
    schedule_recurring_tasks_async(wait: 1.seconds) do
      get mission_control_jobs.application_recurring_task_url(@application, "periodic_pause_job")
      assert_response :ok

      assert_select "h1", /periodic_pause_job/
      assert_select "h2", "1 job"
      assert_select "tr.job", 1
      assert_select "td a", "PauseJob"
      assert_select "td div", /Enqueued less than a minute ago/
    end
  end

  test "redirect to recurring tasks list when recurring task doesn't exist" do
    schedule_recurring_tasks_async do
      get mission_control_jobs.application_recurring_task_url(@application, "invalid_key")
      assert_redirected_to mission_control_jobs.application_recurring_tasks_url(@application)

      follow_redirect!

      assert_select "article.is-danger", /Recurring task with id 'invalid_key' not found/
    end
  end
end
