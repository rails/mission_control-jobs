module ActiveJob::QueueAdapters::AdapterTesting::JobBatches
  extend ActiveSupport::Concern
  extend ActiveSupport::Testing::Declarative

  included do
    # Ascending order
    assert_loop jobs_count: 10, order: :asc, batch_size: 5, expected_batches: [ 0..4, 5..9 ]
    assert_loop jobs_count: 12, order: :asc, batch_size: 5, expected_batches: [ 0..4, 5..9, 10..11 ]

    # Descending order
    assert_loop jobs_count: 10, order: :desc, batch_size: 5, expected_batches: [ 5..9, 0..4 ]
    assert_loop jobs_count: 12, order: :desc, batch_size: 5, expected_batches: [ 7..11, 2..6, 0..1 ]
  end

  class_methods do
    def assert_loop(jobs_count:, order:, batch_size:, expected_batches:)
      test "loop for #{jobs_count} jobs in #{order} order with #{batch_size} batch size: expecting #{expected_batches.inspect}" do
        jobs_count.times { |index| FailingJob.perform_later(index) }
        perform_enqueued_jobs

        batches = []
        ActiveJob.jobs.failed.in_batches(of: batch_size, order: order) { |batch| batches << batch }

        assert_equal expected_batches.length, batches.length
        batches.each { |batch| assert_instance_of ActiveJob::JobsRelation, batch }

        expected_batches.each.with_index do |batch_range, index|
          assert_equal batch_range.to_a, batches[index].to_a.collect(&:serialized_arguments).flatten
        end
      end

      test "loop for #{jobs_count} jobs in #{order} order with #{batch_size} batch size and using a class name filter: expecting #{expected_batches.inspect}" do
        jobs_count.times { |index| FailingJob.perform_later(index) }
        perform_enqueued_jobs

        batches = []
        ActiveJob.jobs.failed.where(job_class: "FailingJob").in_batches(of: batch_size, order: order) { |batch| batches << batch }

        assert_equal expected_batches.length, batches.length
        batches.each { |batch| assert_instance_of ActiveJob::JobsRelation, batch }

        expected_batches.each.with_index do |batch_range, index|
          assert_equal batch_range.to_a, batches[index].to_a.collect(&:serialized_arguments).flatten
        end
      end
    end
  end
end
