module MissionControl::Jobs::PaginationHelper
  def first_page?
    current_page == 1
  end

  def last_page?
    current_page == total_pages
  end

  def total_pages
    (@jobs_count.to_f / 10).ceil
  end
end
