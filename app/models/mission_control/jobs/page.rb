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
    index == pages_count
  end

  def previous_index
    [ index - 1, 1 ].max
  end

  def next_index
    [ index + 1, pages_count ].min
  end

  def pages_count
    (jobs_relation.count.to_f / 10).ceil
  end

  private
    def offset
      (index - 1) * page_size
    end
end
