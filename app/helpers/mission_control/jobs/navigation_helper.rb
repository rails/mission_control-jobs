module MissionControl::Jobs::NavigationHelper
  attr_reader :page_title, :current_section

  def navigation_sections
    { queues: [ "Queues", application_queues_path(@application) ] }.tap do |sections|
      supported_job_statuses.without(:pending).each do |status|
         sections[navigation_section_for_status(status)] = [ status_title_tab(status), application_jobs_path(@application, status) ]
      end

      sections[:workers] = [ "Workers", application_workers_path(@application) ] if workers_exposed?
    end
  end

  def navigation_section_for_status(status)
    if status.nil? || status == :pending
      :queues
    else
      "#{status}_jobs".to_sym
    end
  end

  def navigation(title: nil, section: nil)
    @page_title = title
    @current_section = section
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

  def jobs_count_with_status(status)
    count = ApplicationJob.jobs.with_status(status).count
    count.infinite? ? "..." : number_to_human(count)
  end

  def status_title_tab(status)
    "#{status.to_s.titleize} Jobs (#{jobs_count_with_status(status)})"
  end
end
