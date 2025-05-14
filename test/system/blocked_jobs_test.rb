require_relative "../application_system_test_case"

class BlockedJobsTest < ApplicationSystemTestCase
  setup do
    # Find a SolidQueue server to use for this test
    @solid_queue_server = MissionControl::Jobs.applications.first.servers.find { |s| s.queue_adapter_name == :solid_queue }
    
    # Skip if SolidQueue is not available
    skip "SolidQueue adapter not available for testing" unless @solid_queue_server
    
    # Use the SolidQueue server's activating method to switch adapters temporarily
    @solid_queue_server.activating do
      # Create jobs with SolidQueue adapter
      BlockingJob.perform_later(10)
      BlockingJob.perform_later(20)
      
      # Get the last job
      job = ActiveJob.jobs.blocked.last
      
      # Make sure the job has nil blocked_until
      if job.respond_to?(:blocked_execution) && job.blocked_execution
        job.blocked_execution.update!(expires_at: nil)
      end
    end
    
    # Visit the blocked jobs page with SolidQueue active
    @solid_queue_server.activating do
      visit jobs_path(:blocked)
    end
  end

  test "displays blocked jobs with expiration date" do
    @solid_queue_server.activating do
      assert_text "10"
      assert_text "Expires"
    end
  end

  test "displays blocked jobs without expiration date" do
    @solid_queue_server.activating do
      assert_text "20"
      
      within_job_row "20" do
        # The expiration message should be empty when blocked_until is nil
        assert page.has_selector?(".has-text-grey.is-size-7", text: "")
      end
    end
  end

  test "run now button works for blocked jobs" do
    @solid_queue_server.activating do
      assert_equal 2, job_row_elements.length
      
      within_job_row "10" do
        click_on "Run now"
      end
      
      assert_text "Dispatched"
      assert_equal 1, job_row_elements.length
    end
  end
end 
