# A relation of workers.
#
# Relations are enumerable, so you can use +Enumerable+ methods on them.
# Notice however that using these methods will imply loading all the relation
# in memory, which could introduce performance concerns.
#
# Internally, +ActiveJob+ will always use paginated queries to the underlying
# queue adapter. The page size can be controlled via +config.active_job.default_page_size+
# (1000 by default).
class ActiveJob::WorkersRelation
  include Enumerable

  attr_reader :default_page_size
  attr_accessor :offset_value, :limit_value

  delegate :last, :[], :count, :empty?, :length, :size, :to_s, :inspect, :reverse, to: :to_a

  ALL_WORKERS_LIMIT = 100_000_000 # When no limit value it defaults to "all workers"

  def initialize(workers: [], default_page_size: ActiveJob::Base.default_page_size)
    @workers = workers
    @default_page_size = default_page_size

    set_defaults
  end

  # Sets an offset for the workers list. The first position is 0.
  def offset(offset)
    @workers = @workers.drop(offset)
    clone_with offset_value: offset
  end

  # Sets the max number of wokers to fetch in the query.
  def limit(limit)
    @workers = @workers.first(limit)
    clone_with limit_value: limit
  end

  def each(&block)
    @workers.each(&block)
  end

  def reload
    @count = nil
    self
  end

  private
    def set_defaults
      self.offset_value = 0
      self.limit_value = ALL_WORKERS_LIMIT
    end

    def clone_with(**properties)
      dup.reload.tap do |relation|
        properties.each do |key, value|
          relation.send("#{key}=", value)
        end
      end
    end
end
