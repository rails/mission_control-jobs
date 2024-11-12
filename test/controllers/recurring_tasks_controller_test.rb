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
    travel_to Time.parse("2024-10-30 19:07:10 UTC") do
      schedule_recurring_tasks_async(wait: 2.seconds) do
        get mission_control_jobs.application_recurring_tasks_url(@application)
        assert_response :ok

        assert_select "tr.recurring_task", 1
        assert_select "td a", "periodic_pause_job"
        assert_select "td", "PauseJob"
        assert_select "td", "every second"
        assert_select "td", /2024-10-30 19:07:1\d\.\d{3}/
        assert_select "button", "Run now"
      end
    end
  end

  test "get recurring task details and job list" do
    travel_to Time.parse("2024-10-30 19:07:10 UTC") do
      schedule_recurring_tasks_async(wait: 1.seconds) do
        get mission_control_jobs.application_recurring_task_url(@application, "periodic_pause_job")
        assert_response :ok

        assert_select "h1", /periodic_pause_job/
        assert_select "h2", "1 job"
        assert_select "tr.job", 1
        assert_select "td a", "PauseJob"
        assert_select "td", /2024-10-30 19:07:1\d\.\d{3}/
      end
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

  test "get recurring task with undefined class" do
    # simulate recurring task inserted from another app, no validations or callbacks
    SolidQueue::RecurringTask.insert({ key: "missing_class_task", class_name: "MissingJob", schedule: "every minute" })
    get mission_control_jobs.application_recurring_tasks_url(@application)
    assert_response :ok

    assert_select "tr.recurring_task", 1
    assert_select "td a", "missing_class_task"
    assert_select "td", "MissingJob"
    assert_select "td", "every minute"
    assert_select "button", text: "Run now", count: 0 # Can't be run because the class doesn't exist
  end

  test "enqueue recurring task successfully" do
    schedule_recurring_tasks_async(wait: 0.1.seconds)

    assert_difference -> { ActiveJob.jobs.pending.count } do
      put mission_control_jobs.application_recurring_task_url(@application, "periodic_pause_job")
      assert_response :redirect
    end

    job = ActiveJob.jobs.pending.last
    assert_equal "PauseJob", job.job_class_name
    assert_match /jobs\/#{job.job_id}\?server_id=solid_queue\z/, response.location
  end

  test "fail to enqueue recurring task with undefined class" do
    # simulate recurring task inserted from another app, no validations or callbacks
    SolidQueue::RecurringTask.insert({ key: "missing_class_task", class_name: "MissingJob", schedule: "every minute" })

    assert_no_difference -> { ActiveJob.jobs.pending.count } do
      put mission_control_jobs.application_recurring_task_url(@application, "missing_class_task")
      assert_response :redirect

      follow_redirect!
      assert_select "article.is-danger", /This task can.t be enqueued/
    end
  end
end
