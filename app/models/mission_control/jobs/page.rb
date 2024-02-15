class MissionControl::Jobs::Page
  DEFAULT_PAGE_SIZE = 10

  attr_reader :items_relation, :index, :page_size

  def initialize(items_relation, page: 1, page_size: DEFAULT_PAGE_SIZE)
    @items_relation =items_relation
    @page_size = page_size
    @index = [ page, 1 ].max
  end

  def jobs
    items_relation.limit(page_size).offset(offset)
  end

  def first?
    index == 1
  end

  def last?
    index == pages_count || empty? || jobs.empty?
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
    @total_count ||= items_relation.count # Potentially expensive when filtering a lot of items, with the adapter in charge of doing the filtering in memory
  end

  private
    def offset
      (index - 1) * page_size
    end
end
