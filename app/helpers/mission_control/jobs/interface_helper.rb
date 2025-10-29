module MissionControl::Jobs::InterfaceHelper
  def blank_status_notice(message)
    tag.div message, class: "mt-6 has-text-centered is-size-3 has-text-grey"
  end

  def blank_status_emoji(status)
    case status.to_s
    when "failed", "blocked" then "😌"
    else ""
    end
  end

  def jobs_count_for(status)
    count = ActiveJob.jobs.with_status(status).count
    value = count.infinite? ? MissionControl::Jobs.count_limit : count
    suffix = count.infinite? ? "+" : ""

    units = { thousand: "K", million: "M", billion: "B", trillion: "T", quadrillion: "Q" }

    number_to_human(value, format: "%n%u", units: units) + suffix
  end

  def modifier_for_status(status)
    case status.to_s
    when "failed"      then "is-danger"
    when "blocked"     then "is-warning"
    when "finished"    then "is-success"
    when "scheduled"   then "is-info"
    when "in_progress" then "is-primary"
    else "is-primary is-light"
    end
  end
end
