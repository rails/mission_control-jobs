module MissionControl::Jobs::NavigationHelper
  attr_reader :page_title, :current_section

  def navigation_sections
    {
      queues: [ "Queues", queues_path ],
      failed_jobs: [ "Failed jobs (#{failed_jobs_count})", failed_jobs_path ]
    }
  end

  def navigation(title: nil, section: nil)
    @page_title = title
    @current_section = section
  end

  def page_title
    @page_title
  end
end
