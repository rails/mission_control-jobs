# A relation of batches.
#
# Relations are enumerable, so you can use +Enumerable+ methods on them.
# Notice however that using these methods will imply loading all the relation
# in memory, which could introduce performance concerns.
class MissionControl::Jobs::BatchesRelation
  include Enumerable

  attr_reader :status
  attr_accessor :offset_value, :limit_value

  delegate :last, :[], :to_s, :reverse, to: :to_a

  ALL_BATCHES_LIMIT = 100_000_000 # When no limit value it defaults to "all batches"

  def initialize(queue_adapter:, status: nil)
    @queue_adapter = queue_adapter
    @status = status

    set_defaults
  end

  def offset(offset)
    clone_with offset_value: offset
  end

  def limit(limit)
    clone_with limit_value: limit
  end

  def each(&block)
    batches.each(&block)
  end

  def reload
    @count = @batches = nil
    self
  end

  def count
    if loaded?
      to_a.length
    else
      query_count
    end
  end

  def empty?
    count == 0
  end

  alias length count
  alias size count

  private
    def set_defaults
      self.offset_value = 0
      self.limit_value = ALL_BATCHES_LIMIT
    end

    def batches
      @batches ||= @queue_adapter.fetch_batches(self).collect do |attributes|
        MissionControl::Jobs::Batch.new(queue_adapter: @queue_adapter, **attributes)
      end
    end

    # How many batches a fetch would return. The adapter only counts the full
    # set for a status, so the offset/limit window is applied arithmetically:
    # given 100 batches, offset(30).limit(50) counts 50, and offset(90)
    # counts 10.
    #
    # Given too many batches to count, +count_batches+ returns
    # +Float::INFINITY+, which passes through the arithmetic untouched and
    # tells +Page+ there are too many pages to link to the last one.
    def query_count
      @count ||= begin
        count = [ @queue_adapter.count_batches(self) - offset_value, 0 ].max
        limit_value_provided? ? [ count, limit_value ].min : count
      end
    end

    def limit_value_provided?
      limit_value.present? && limit_value != ALL_BATCHES_LIMIT
    end

    def loaded?
      !@batches.nil?
    end

    def clone_with(**properties)
      dup.reload.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end
end
