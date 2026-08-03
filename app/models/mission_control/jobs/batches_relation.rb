# A relation of batches.
#
# Relations are enumerable, so you can use +Enumerable+ methods on them.
# Notice however that using these methods will imply loading all the relation
# in memory, which could introduce performance concerns.
class MissionControl::Jobs::BatchesRelation
  include Enumerable

  def initialize(queue_adapter:, status: nil, offset: 0, limit: nil)
    @queue_adapter = queue_adapter
    @status = status
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
    queue_adapter.batches_count(status: @status)
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
      self.class.new(queue_adapter: queue_adapter, status: @status, offset: offset, limit: limit)
    end

    def batches
      @batches ||= queue_adapter.batches(status: @status, offset: @offset, limit: @limit).collect do |attributes|
        MissionControl::Jobs::Batch.new(queue_adapter: queue_adapter, **attributes)
      end
    end
end
