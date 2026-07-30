class MissionControl::Jobs::BatchesRelation
  include Enumerable

  def initialize(queue_adapter:, offset: 0, limit: nil)
    @queue_adapter = queue_adapter
    @offset = offset
    @limit = limit
  end

  def offset(offset)
    with(offset: offset)
  end

  def limit(limit)
    with(limit: limit)
  end

  def count
    queue_adapter.batches_count
  end

  def empty?
    batches.empty?
  end

  def size
    batches.size
  end

  def each(&block)
    batches.each(&block)
  end

  private
    attr_reader :queue_adapter

    def with(offset: @offset, limit: @limit)
      self.class.new(queue_adapter: queue_adapter, offset: offset, limit: limit)
    end

    def batches
      @batches ||= queue_adapter.batches(offset: @offset, limit: @limit).collect do |attributes|
        MissionControl::Jobs::Batch.new(queue_adapter: queue_adapter, **attributes)
      end
    end
end
