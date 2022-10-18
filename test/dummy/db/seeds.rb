def clean_redis
  all_keys = Resque.redis.keys("*")
  Resque.redis.del all_keys if all_keys.any?
end

class JobsLoader
  attr_reader :application, :server, :failed_jobs_count, :regular_jobs_count

  def initialize(application, server, failed_jobs_count: 100, regular_jobs_count: 50)
    @application = application
    @server = server
    @failed_jobs_count = randomize(failed_jobs_count)
    @regular_jobs_count = randomize(regular_jobs_count)
  end

  def load
    server.activating do
      load_failed_jobs
      load_regular_jobs
    end
  end

  private
    def load_failed_jobs
      puts "Generating #{failed_jobs_count} failed jobs for #{application} - #{server} at #{current_redis.inspect}..."
      failed_jobs_count.times { |index| enqueue_one_of FailingJob => index, FailingReloadedJob => index, FailingPostJob => [ Post.last, 1.year.ago ] }
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
        enqueue_one_of DummyJob => index, DummyReloadedJob => index
      end
    end

    def with_random_queue(job_class)
      random_queue = [ "background", "reports", "default", "realtime" ].sample
      job_class.tap do
        job_class.queue_as random_queue
      end
    end

    def enqueue_one_of(arguments_by_job_class)
      arguments_by_job_class.each do |job_class, arguments|
        with_random_queue(job_class).perform_later(*Array(arguments))
      end
    end

    def randomize(value)
      (value * (1 + rand)).to_i
    end
end

puts "Deleting existing jobs..."
clean_redis

BASE_COUNT = (ENV["COUNT"].presence || 100).to_i

Post.find_or_create_by!(title: "Hello World!", body: "This is my first post.")

MissionControl::Jobs.applications.each do |application|
  application.servers.each do |server|
    JobsLoader.new(application, server, failed_jobs_count: BASE_COUNT, regular_jobs_count: BASE_COUNT / 2).load
  end
end
