require_relative "../application_system_test_case"

class PaginateWorkersTest < ApplicationSystemTestCase
  setup do
    perform_jobs
    perform_enqueued_jobs

    visit application_workers_path(:hey, :server_id => "solid_queue")
  end

  test "paginate workers" do
    assert_text "Next page"
    assert_text "Previous page"
    
    assert_text "worker 1"
  end

  private
    def perform_jobs
      20.times do |index|
        DummyJob.perform_later(index)

        worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0)
        worker.mode = :inline
        worker.start
      end
    end
end
