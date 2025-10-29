# A relation of workers.
#
# Relations are enumerable, so you can use +Enumerable+ methods on them.
# Notice however that using these methods will imply loading all the relation
# in memory, which could introduce performance concerns.
class MissionControl::Jobs::WorkersRelation
  include Enumerable

  attr_accessor :offset_value, :limit_value

  delegate :last, :[], :to_s, :reverse, to: :to_a

  attr_reader :hostname, :pid, :queues

  ALL_WORKERS_LIMIT = 100_000_000 # When no limit value it defaults to "all workers"
  IN_MEMORY_FILTERS = %w[ queues ]

  def initialize(queue_adapter:)
    @queue_adapter = queue_adapter

    set_defaults
  end

  # Returns a +MissionControl::Jobs::WorkersRelation+ with the configured filtering options.
  #
  # === Options
  # * <tt>:hostname</tt> - To only include the workers of a given hostname.
  # * <tt>:pid</tt> - To only include the workers of a given pid.
  # * <tt>:queues</tt> - To only include workers processing jobs from a the given queues.
  def where(hostname: nil, pid: nil, queues: nil)
    # Remove nil arguments to avoid overriding parameters when concatenating +where+ clauses
    arguments = { hostname: hostname, pid: pid, queues: queues }.compact

    clone_with **arguments
  end

  def offset(offset)
    clone_with offset_value: offset
  end

  def limit(limit)
    clone_with limit_value: limit
  end

  def each(&block)
    workers.each(&block)
  end

  def reload
    @count = @workers = nil
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
    attr_writer :hostname, :pid, :queues

    def set_defaults
      self.offset_value = 0
      self.limit_value = ALL_WORKERS_LIMIT
    end

    def workers
      return @workers if @workers

      @workers = @queue_adapter.fetch_workers(self)
      perform_in_memory_filtering(@workers)
      @workers
    end

    def perform_in_memory_filtering(workers)
      workers.then { |workers| filter_by_queues(workers) }
      filter_by_queues(workers) if queues.present?
    end

    def filter_by_queues(workers)
      queues.present? workers.filter { |worker| worker.metadata['queues'].match?(queues) }
    end

    def query_count
      @count ||= @queue_adapter.count_workers(self)
    end

    def loaded?
      !@workers.nil?
    end

    def clone_with(**properties)
      dup.reload.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end
end
