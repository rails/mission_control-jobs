class ActiveJob::Queue
  attr_reader :name

  def initialize(name, queue_adapter: ActiveJob::Base.queue_adapter)
    @name = name
    @queue_adapter = queue_adapter
  end

  def size
    queue_adapter.queue_size(name)
  end

  alias length size

  def pause
    queue_adapter.pause_queue(name)
  end

  def resume
    queue_adapter.resume_queue(name)
  end

  def paused?
    queue_adapter.queue_paused?(name)
  end

  def active?
    !paused?
  end

  private
    attr_reader :queue_adapter
end
