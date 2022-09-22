require_relative "../application_system_test_case"

class PaginateJobsTest < ApplicationSystemTestCase
  setup do
    20.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    visit failed_jobs_path
  end

  test "paginate failed jobs" do
    assert_jobs 0..9

    click_on "Next page"
    assert_jobs 10..19

    click_on "Previous page"
    assert_jobs 0..9
  end

  private
    def assert_jobs(range)
      expected_indexes = range.to_a

      assert_text /FailingJob.*#{expected_indexes.first}/i # Wait for page to load
      assert_equal expected_indexes.length, job_row_elements.length

      job_row_elements.each.with_index do |job_element, index|
        within job_element do
          assert_text /FailingJob.*#{expected_indexes[index]}/i
        end
      end
    end
end
