def clean_redis
  all_keys = Resque.redis.keys("*")
  Resque.redis.del all_keys if all_keys.any?
end

class JobsLoader
  FAILED_JOBS_COUNT = 100
  REGULAR_JOBS_COUNT = 50

  attr_reader :application, :server

  def initialize(application, server)
    @application = application
    @server = server
  end

  def load
    ActiveJob::Base.current_queue_adapter = server.queue_adapter

    load_failed_jobs
    load_regular_jobs
  end

  private
    def load_failed_jobs
      puts "Generating #{failed_jobs_count} failed jobs for #{application} - #{server} at #{current_redis.inspect}..."
      failed_jobs_count.times do |index|
        enqueue_one_of FailingJob, FailingReloadedJob, with: index
      end
      dispatch_jobs
    end

    def current_redis
      Resque.redis.instance_variable_get("@redis")
    end

    def dispatch_jobs
      worker = Resque::Worker.new("*")
      worker.work(0.0)
    end

    def load_regular_jobs
      puts "Generating #{regular_jobs_count} regular jobs..."
      regular_jobs_count.times do |index|
        enqueue_one_of DummyJob, DummyReloadedJob, with: index
      end
    end

    def with_random_queue(job_class)
      random_queue = [ "background", "reports", "default", "realtime" ].sample
      job_class.tap do
        job_class.queue_as random_queue
      end
    end

    def enqueue_one_of(*jobs, with:)
      with_random_queue(jobs.sample).perform_later(*Array(with))
    end

    def failed_jobs_count
      @failed_jobs_count ||= randomize(FAILED_JOBS_COUNT)
    end

    def regular_jobs_count
      @regular_jobs_count ||= randomize(REGULAR_JOBS_COUNT)
    end

    def randomize(value)
      (value * (1 + rand)).to_i
    end
end

puts "Deleting existing jobs..."
clean_redis

MissionControl::Jobs.applications.each do |application|
  application.servers.each do |server|
    JobsLoader.new(application, server).load
  end
end
