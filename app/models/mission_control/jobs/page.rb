class MissionControl::Jobs::Page
  DEFAULT_PAGE_SIZE = 10

  attr_reader :jobs_relation, :index, :page_size

  def initialize(jobs_relation, page: 1, page_size: DEFAULT_PAGE_SIZE)
    @jobs_relation = jobs_relation
    @page_size = page_size
    @index = [ page, 1 ].max
  end

  def jobs
    jobs_relation.limit(page_size).offset(offset)
  end

  def first?
    index == 1
  end

  def last?
    index == pages_count || total_count == 0
  end

  def previous_index
    [ index - 1, 1 ].max
  end

  def next_index
    [ index + 1, pages_count ].min
  end

  def pages_count
    (total_count.to_f / 10).ceil
  end

  def total_count
    @total_count ||= jobs_relation.count # Potentially expensive when filtering and a lot of jobs, with adapter in charge of doing the filtering in memory
  end

  private
    def offset
      (index - 1) * page_size
    end
end
