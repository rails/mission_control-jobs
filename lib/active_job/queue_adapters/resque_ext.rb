module ActiveJob::QueueAdapters::ResqueExt
  def queue_names
    Resque.queues
  end
end
