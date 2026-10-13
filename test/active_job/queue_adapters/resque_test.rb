require "test_helper"

class ActiveJob::QueueAdapters::ResqueTest < ActiveSupport::TestCase
  include ActiveJob::QueueAdapters::AdapterTesting

  test "supports queue pausing when ResquePauseHelper is defined" do
    assert ActiveJob::Base.queue_adapter.supports_queue_pausing?
  end

  test "does not support queue pausing when ResquePauseHelper is not defined" do
    emulating_resque_pause_gem_absence do
      assert_not ActiveJob::Base.queue_adapter.supports_queue_pausing?
    end
  end

  test "retry failed jobs mixed with other jobs in several transaction batches" do
    with_failed_jobs_mixed_with_other_jobs do
      stub_const(ActiveJob::QueueAdapters::ResqueExt::ResqueJobs, :MAX_REDIS_TRANSACTION_SIZE, 2) do
        ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob").retry_all
      end

      assert_equal (0..9).to_a.reverse, ActiveJob.jobs.failed.map { |job| job.serialized_arguments.first }
      assert_equal 5, ActiveJob.jobs.pending.where(queue_name: :default).count
    end
  end

  test "discard failed jobs mixed with other jobs in several transaction batches" do
    with_failed_jobs_mixed_with_other_jobs do
      stub_const(ActiveJob::QueueAdapters::ResqueExt::ResqueJobs, :MAX_REDIS_TRANSACTION_SIZE, 2) do
        ActiveJob.jobs.failed.where(job_class_name: "FailingReloadedJob").discard_all
      end

      assert_equal (0..9).to_a.reverse, ActiveJob.jobs.failed.map { |job| job.serialized_arguments.first }
      assert_equal 0, ActiveJob.jobs.pending.where(queue_name: :default).count
    end
  end

  %i[ retry_all discard_all ].each do |operation|
    test "#{operation} removes each transaction batch of failed jobs with a single LREM" do
      6.times { |index| FailingJob.perform_later(index) }
      perform_enqueued_jobs

      # Count on the client: Redis < 7 doesn't count the commands inside MULTI in INFO commandstats
      Redis::MultiConnection.any_instance.expects(:lrem).times(3)

      stub_const(ActiveJob::QueueAdapters::ResqueExt::ResqueJobs, :MAX_REDIS_TRANSACTION_SIZE, 2) do
        ActiveJob.jobs.failed.where(job_class_name: "FailingJob").public_send(operation)
      end
    end
  end

  test "retry_all removes the jobs already requeued when a later job fails" do
    3.times { |index| FailingJob.perform_later(index) }
    perform_enqueued_jobs

    Resque::Job.stubs(:create).returns(true).then.raises(Redis::CommandError, "ERR")
    assert_raises(Redis::CommandError) { ActiveJob.jobs.failed.retry_all }

    assert_equal [ [ 1 ], [ 0 ] ], ActiveJob.jobs.failed.map(&:serialized_arguments)
  end

  private
    def emulating_resque_pause_gem_absence
      helper_const = Object.send(:remove_const, :ResquePauseHelper)
      yield
    ensure
      Object.const_set(:ResquePauseHelper, helper_const)
    end

    # 15 failed jobs: FailingJob 0..9 in order, with FailingReloadedJob after every second one
    def with_failed_jobs_mixed_with_other_jobs
      10.times do |index|
        FailingJob.perform_later(index)
        FailingReloadedJob.perform_later(100 + index) if index.odd?
      end
      perform_enqueued_jobs
      assert_equal 15, ActiveJob.jobs.failed.count

      yield
    end

    def queue_adapter
      :resque
    end

    def perform_enqueued_jobs
      @worker ||= Resque::Worker.new("*")
      @worker.work(0.0)
    end
end
