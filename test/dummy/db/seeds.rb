def clean_redis
  all_keys = Resque.redis.keys("*")
  Resque.redis.del all_keys if all_keys.any?
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

puts "Deleting existing jobs..."
clean_redis

puts "Generating failed jobs..."
100.times do |index|
  enqueue_one_of FailingJob, FailingReloadedJob, with: index
end
worker = Resque::Worker.new("*")
worker.work(0.0)

puts "Generating regular jobs..."
500.times do |index|
  enqueue_one_of DummyJob, DummyReloadedJob, with: index
end
