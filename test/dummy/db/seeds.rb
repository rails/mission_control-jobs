def clean_redis
  all_keys = Resque.redis.keys("*")
  Resque.redis.del all_keys if all_keys.any?
end

def clean_database
  SolidQueue::Job.all.each(&:destroy)
  SolidQueue::Process.all.each(&:destroy)
end

class JobsLoader
  attr_reader :application, :server, :failed_jobs_count, :regular_jobs_count, :finished_jobs_count, :blocked_jobs_count

  def initialize(application, server, failed_jobs_count: 100, regular_jobs_count: 50)
    @application = application
    @server = server
    @failed_jobs_count = randomize(failed_jobs_count)
    @regular_jobs_count = randomize(regular_jobs_count)
    @finished_jobs_count = randomize(regular_jobs_count)
    @blocked_jobs_count = randomize(regular_jobs_count)
  end

  def load
    server.activating do
      load_finished_jobs
      load_failed_jobs
      load_regular_jobs
      load_blocked_jobs if server.queue_adapter.supported_statuses.include?(:blocked)
    end
  end

  private
    def load_failed_jobs
      puts "Generating #{failed_jobs_count} failed jobs for #{application} - #{server}..."
      failed_jobs_count.times { |index| enqueue_one_of FailingJob => index, FailingReloadedJob => index, FailingPostJob => [ Post.last, 1.year.ago ] }
      perform_jobs
    end

    def perform_jobs
      case server.queue_adapter_name
      when :resque
        worker = Resque::Worker.new("*")
        worker.work(0.0)
      when :solid_queue
        worker = SolidQueue::Worker.new(queues: "*", threads: 1, polling_interval: 0.01)
        worker.mode = :inline
        worker.start
      else
        raise "Don't know how to dispatch jobs for #{server.queue_adapter_name} adapter"
      end
    end

    def load_finished_jobs
      puts "Generating #{finished_jobs_count} finished jobs for #{application} - #{server}..."
      regular_jobs_count.times do |index|
        enqueue_one_of DummyJob => index, DummyReloadedJob => index
      end
      perform_jobs
    end

    def load_regular_jobs
      puts "Generating #{regular_jobs_count} regular jobs for #{application} - #{server}..."
      regular_jobs_count.times do |index|
        enqueue_one_of DummyJob => index, DummyReloadedJob => index
      end
    end

    def load_blocked_jobs
      puts "Generating #{blocked_jobs_count} blocked jobs for #{application} - #{server}..."
      blocked_jobs_count.times do |index|
        enqueue_one_of BlockingJob => index
      end
    end

    def with_random_queue(job_class)
      random_queue = [ "background", "reports", "default", "realtime" ].sample
      job_class.tap do
        job_class.queue_as random_queue
      end
    end

    def enqueue_one_of(arguments_by_job_class)
      job_class = arguments_by_job_class.keys.sample
      arguments = arguments_by_job_class[job_class]
      with_random_queue(job_class).perform_later(*Array(arguments))
    end

    def randomize(value)
      (value * (1 + rand)).to_i
    end
end

puts "Deleting existing jobs..."
clean_redis
clean_database

BASE_COUNT = (ENV["COUNT"].presence || 100).to_i

Post.find_or_create_by!(title: "Hello World!", body: "This is my first post.")

MissionControl::Jobs.applications.each do |application|
  application.servers.each do |server|
    JobsLoader.new(application, server, failed_jobs_count: BASE_COUNT, regular_jobs_count: BASE_COUNT / 2).load
  end
end
