class MissionControl::Jobs::WorkersPage
  DEFAULT_PAGE_SIZE = 10

  attr_reader :workers_collection, :index, :page_size

  def initialize(workers_collection, page: 1, page_size: DEFAULT_PAGE_SIZE)
    @workers_collection = workers_collection
    @page_size = page_size
    @index = [ page, 1 ].max
  end

  def workers
    workers_collection.drop(offset).first(page_size)
  end

  def first?
    index == 1
  end

  def last?
    index == pages_count || empty? || workers.empty?
  end

  def empty?
    total_count == 0
  end

  def previous_index
    [ index - 1, 1 ].max
  end

  def next_index
    pages_count ? [ index + 1, pages_count ].min : index + 1
  end

  def pages_count
    (total_count.to_f / 10).ceil unless total_count.infinite?
  end

  def total_count
    @total_count ||= workers_collection.count # Potentially expensive when filtering and a lot of workers, with adapter in charge of doing the filtering in memory
  end

  private
    def offset
      (index - 1) * page_size
    end
end
