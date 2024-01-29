# A queue of jobs
class ActiveJob::Queue
  attr_reader :name

  def initialize(name, size: nil, active: nil, queue_adapter: ActiveJob::Base.queue_adapter)
    @name = name
    @queue_adapter = queue_adapter

    @size = size
    @active = active
  end

  def size
    @size ||= queue_adapter.queue_size(name)
  end

  alias length size

  def clear
    queue_adapter.clear_queue(name)
  end

  def empty?
    size == 0
  end

  def pause
    queue_adapter.pause_queue(name)
  end

  def resume
    queue_adapter.resume_queue(name)
  end

  def paused?
    !active?
  end

  def active?
    return @active unless @active.nil?
    @active = !queue_adapter.queue_paused?(name)
  end

  # Return an +ActiveJob::JobsRelation+ with the pending jobs in the queue.
  def jobs
    ActiveJob::JobsRelation.new(queue_adapter: queue_adapter).pending.where(queue_name: name)
  end

  def reload
    @active = @size = nil
    self
  end

  def id
    name.parameterize
  end

  alias to_param id

  private
    attr_reader :queue_adapter
end
