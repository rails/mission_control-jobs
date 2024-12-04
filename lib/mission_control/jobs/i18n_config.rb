class MissionControl::Jobs::I18nConfig < ::I18n::Config
  def available_locales
    [ :en ]
  end

  def default_locale
    :en
  end
end
