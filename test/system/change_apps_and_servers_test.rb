require_relative "../application_system_test_case"

class ChangeAppsAndServersTest < ApplicationSystemTestCase
  include ResqueHelper

  test "switch apps" do
    within_job_server "hey" do
      DummyJob.queue_as :hey_queue
      10.times { |index| DummyJob.perform_later(index) }
    end

    visit queues_path
    assert_empty job_row_elements

    hover_app_selector and_click: /hey/i
    assert_equal 1, queue_row_elements.length

    click_on "hey_queue"
    assert_equal 10, job_row_elements.length
  end

  test "switch job servers" do
    DummyJob.queue_as :bc3_queue

    within_job_server "bc3", server: "ashburn" do
      5.times { |index| DummyJob.perform_later(index) }
    end

    within_job_server "bc3", server: "chicago" do
      DummyJob.queue_as :bc3_queue_chicago
      10.times { |index| DummyJob.perform_later(index) }
    end

    visit queues_path
    click_on "bc3_queue"
    assert_equal 5, job_row_elements.length

    click_on_server_selector "chicago"
    assert_text 10
    click_on "bc3_queue"
    assert_equal 10, job_row_elements.length

    click_on_server_selector "ashburn"
    assert_text 5
    click_on "bc3_queue"
    assert_equal 5, job_row_elements.length
  end
end
