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

  def label_for_batch_job_status(status)
    status == :finished ? "completed" : status.to_s.humanize.downcase
  end

  def modifier_for_batch_status(status)
    case status.to_s
    when "completed" then "is-success"
    when "failed"    then "is-danger"
    when "enqueued"  then "is-info"
    else "is-light"
    end
  end
end
