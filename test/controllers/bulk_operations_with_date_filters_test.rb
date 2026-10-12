require "test_helper"

class MissionControl::Jobs::BulkOperationsWithDateFiltersTest < ActionDispatch::IntegrationTest
  setup do
    FailingJob.perform_later(:old)
    FailingJob.perform_later(:new)
    perform_enqueued_jobs_async

    SolidQueue::Job.order(:id).first.update!(created_at: 2.days.ago)
  end

  test "discard a selection of failed jobs filtered by enqueued_at date" do
    get mission_control_jobs.application_jobs_url(@application, :failed, filter: { enqueued_at_end: 1.day.ago.strftime("%Y-%m-%dT%H:%M") })
    assert_select "tr.job", 1

    post bulk_action_url("Discard selection")
    follow_redirect!

    assert_select "article.is-success", /Discarded 1 jobs/
    assert_equal 1, ActiveJob.jobs.failed.count
  end

  test "retry a selection of failed jobs filtered by enqueued_at date" do
    get mission_control_jobs.application_jobs_url(@application, :failed, filter: { enqueued_at_end: 1.day.ago.strftime("%Y-%m-%dT%H:%M") })
    assert_select "tr.job", 1

    post bulk_action_url("Retry selection")
    follow_redirect!

    assert_select "article.is-success", /Retried 1 jobs/
    assert_equal 1, ActiveJob.jobs.failed.count
  end

  test "pagination keeps the enqueued_at date filter" do
    get mission_control_jobs.application_jobs_url(@application, :failed, filter: { enqueued_at_end: 1.day.ago.strftime("%Y-%m-%dT%H:%M") })

    css_select("a.pagination-next, a.pagination-previous").each do |link|
      assert_includes CGI.unescape(link["href"]), "filter[enqueued_at_end]"
    end
  end

  private
    def bulk_action_url(label)
      css_select("form.button_to").find { |form| form.text.strip == label }["action"]
    end
end
