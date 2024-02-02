require_relative "../application_system_test_case"
require "test_helper"


class PaginateWorkersTest < ApplicationSystemTestCase
  setup do
    perform_enqueued_jobs_async
  end

  test "paginate workers" do
    visit application_workers_path(:hey, :server_id => "solid_queue")

    assert_text "Next page"
    assert_text "Previous page"
    assert_text "worker 1"
  end
end
