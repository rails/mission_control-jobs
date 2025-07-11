module MissionControl::Jobs::NavigationHelper
  attr_reader :page_title, :current_section

  def navigation_sections
    { queues: [ "Queues", application_queues_path(@application) ] }.tap do |sections|
      supported_job_statuses.without(:pending).each do |status|
         sections[navigation_section_for_status(status)] = [ "#{status.to_s.titleize} jobs (#{jobs_count_with_status(status)})", application_jobs_path(@application, status) ]
      end

      sections[:workers] = [ "Workers", application_workers_path(@application) ] if workers_exposed?
      sections[:recurring_tasks] = [ "Recurring tasks", application_recurring_tasks_path(@application) ] if recurring_tasks_supported?
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

  def jobs_count_with_status(status)
    count = ActiveJob.jobs.with_status(status).count
    if count.infinite?
      "..."
    else
      number_to_human(count,
        format: "%n%u",
        units: {
          thousand: "K",
          million: "M",
          billion: "B",
          trillion: "T",
          quadrillion: "Q"
        })
    end
  end
end
