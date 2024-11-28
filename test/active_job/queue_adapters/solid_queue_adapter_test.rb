require "test_helper"

class ActiveJob::QueueAdapters::SolidQueueAdapterTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @previous_adapter, ActiveJob::Base.queue_adapter = ActiveJob::Base.queue_adapter, :solid_queue
  end

  teardown do
    delete_all_jobs
    ActiveJob::Base.queue_adapter = @previous_adapter
  end

  test "activate a new adapter with the default Solid Queue configuration" do
    job = DummyJob.perform_later
    assert ActiveJob.jobs.find_by_id(job.job_id).present?

    adapter = ActiveJob::QueueAdapters::SolidQueueAdapter.new
    adapter.activating do
      assert ActiveJob.jobs.find_by_id(job.job_id).present?
    end
  end

  test "active a new adapter pointing to a different database" do
    job = DummyJob.perform_later

    adapter = ActiveJob::QueueAdapters::SolidQueueAdapter.new(:queue_alternative)
    adapter.activating do
      @invoked = true
      assert_not ActiveJob.jobs.find_by_id(job.job_id).present?
    end

    assert @invoked
    assert ActiveJob.jobs.find_by_id(job.job_id).present?
  end

  test "activating different DB configurations is thread-safe" do
    adapter_1 = ActiveJob::QueueAdapters::SolidQueueAdapter.new(:queue)
    job_1 = adapter_1.activating { DummyJob.perform_later }

    adapter_2 = ActiveJob::QueueAdapters::SolidQueueAdapter.new(:queue_alternative)
    job_2 = adapter_2.activating { DummyJob.perform_later }

    [ [ adapter_1, job_1, job_2 ], [ adapter_2, job_2, job_1 ] ].flat_map do |adapter, present, missing|
      20.times.collect do
        Thread.new do
          adapter.activating do
            sleep_to_force_race_condition
            assert ActiveJob.jobs.find_by_id(present.job_id).present?
            assert_not ActiveJob.jobs.find_by_id(missing.job_id).present?
          end
        end
      end
    end.each(&:join)
  end

  test "use different Solid Queue adapters via active job" do
    adapter_1 = ActiveJob::QueueAdapters::SolidQueueAdapter.new(:queue)
    adapter_2 = ActiveJob::QueueAdapters::SolidQueueAdapter.new(:queue_alternative)

    with_active_job_adapter(adapter_1) do
      adapter_1.activating do
        5.times { DummyJob.perform_later }
      end
    end

    with_active_job_adapter(adapter_2) do
      adapter_2.activating do
        10.times { DummyJob.perform_later }
      end
    end

    with_active_job_adapter(adapter_1) do
      adapter_1.activating do
        assert_equal 5, ActiveJob.jobs.pending.count
      end
    end

    with_active_job_adapter(adapter_2) do
      adapter_2.activating do
        assert_equal 10, ActiveJob.jobs.pending.count
      end
    end
  end

  private
    def delete_all_jobs
      %i[ queue queue_alternative ].each do |db_config_name|
        SolidQueue::Record.connected_to(shard: db_config_name) do
          SolidQueue::Job.delete_all
        end
      end
    end

    def with_active_job_adapter(adapter, &block)
      previous_adapter = ActiveJob::Base.current_queue_adapter
      ActiveJob::Base.current_queue_adapter = adapter
      yield
    ensure
      ActiveJob::Base.current_queue_adapter = previous_adapter
    end
end
