require_relative "../application_system_test_case"

class ShowFailedJobsTest < ApplicationSystemTestCase
  setup do
    10.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs
    visit jobs_path(:failed)
  end

  test "click on a failed job to see its details" do
    within_job_row /FailingJob\s*2/ do
      click_on "FailingJob"
    end

    assert_text /arguments\s*2/i
    assert_text /failing_job.rb/
  end

  test "filtered arguments are hidden" do
    ActiveJob.jobs.failed.discard_all
    FailingPostJob.perform_later(Post.create(title: "hello_world"), 1.year.ago, author: "Jorge")
    perform_enqueued_jobs
    @previous_filter_arguments, MissionControl::Jobs.filter_arguments = MissionControl::Jobs.filter_arguments, %w[ author ]

    visit jobs_path(:failed)
    click_on "FailingPostJob"

    assert_text /dummy\/post/i
    assert_text /\[FILTERED\]/
    assert_no_text /Jorge/
  ensure
    MissionControl::Jobs.filter_arguments = @previous_filter_arguments
  end

  test "click on a failed job error to see its error information" do
    within_job_row /FailingJob\s*2/ do
      click_on "RuntimeError: This always fails!"
    end

    assert_text /failing_job.rb/
  end

  test "show empty notice when no jobs" do
    ActiveJob.jobs.failed.discard_all
    visit jobs_path(:failed)
    assert_text /there are no failed jobs/i
  end

  test "Has Clean/Full buttons when a backtrace cleaner is configured" do
    visit jobs_path(:failed)
    within_job_row(/FailingJob\s*2/) do
      click_on "RuntimeError: This always fails!"
    end

    assert_selector ".backtrace-toggle-selector"
  end

  test "Does not offer Clean/Full buttons when a backtrace cleaner is not configured" do
    setup do
      # grab the current state
      @backtrace_cleaner = MissionControl::Jobs.backtrace_cleaner
      @applications = MissionControl::Jobs.backtrace_cleaner

      # reset the state
      MissionControl::Jobs.backtrace_cleaner = nil
      MissionControl::Jobs.applications = Applications.new

      # Setup the application with what we had before *minus* a backtrace cleaner
      @applications.each do |application|
        MissionControl::Jobs.applications.add(application.name).tap do |it|
          application.servers.each do |server|
            it.add_servers(server.name, server.queue_adapter)
          end
        end
      end
    end

    teardown do
      # reset back to the known state before the start of the test
      MissionControl::Jobs.backtrace_cleaner = @backtrace_cleaner
      MissionControl::Jobs.applications = @application
    end

    visit jobs_path(:failed)
    within_job_row(/FailingJob\s*2/) do
      click_on "RuntimeError: This always fails!"
    end

    assert_no_selector ".backtrace-toggle-selector"
  end

  test "click on 'clean' shows a backtrace cleaned by the Rails default backtrace cleaner" do
    visit jobs_path(:failed)
    within_job_row /FailingJob\s*2/ do
      click_on "RuntimeError: This always fails!"
    end

    assert_selector ".backtrace-toggle-selector"

    within ".backtrace-toggle-selector" do
      click_on "Clean"
    end

    assert_selector "pre.backtrace-content", text: /.*/, visible: true

    within ".backtrace-toggle-selector" do
      click_on "Full"
    end

    assert_selector "pre.backtrace-content", text: /.*/, visible: true
  end
end
