module MissionControl::Jobs::UiHelper
  def blank_status_notice(message)
    tag.div message, class: "mt-6 has-text-centered is-size-3 has-text-grey"
  end
end
