module MissionControl::Jobs::NavigationHelper
  attr_reader :page_title, :current_section

  def navigation_sections
    {
      queues: [ "Queues", application_queues_path(@application) ],
      failed_jobs: [ "Failed jobs (#{failed_jobs_count})", application_jobs_path(@application, :failed) ]
    }
  end

  def navigation(title: nil, section: nil)
    @page_title = title
    @current_section = section
  end

  def page_title
    @page_title
  end

  def navigation_section_for_job(job)
    case job.status
    when :failed then :failed_jobs
    else :queues
    end
  end

  def selected_application?(application)
    MissionControl::Jobs::Current.application.name == application.name
  end

  def selectable_applications
    MissionControl::Jobs.applications.reject { |app| selected_application?(app) }
  end

  def selected_server?(server)
    MissionControl::Jobs::Current.server.name == server.name
  end

  def jobs_filter_param
    if @job_filters&.any?
      { filter: @job_filters }
    else
      {}
    end
  end
end
