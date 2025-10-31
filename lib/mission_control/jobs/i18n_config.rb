class MissionControl::Jobs::I18nConfig < ::I18n::Config
  AVAILABLE_LOCALES = [ :en ]
  AVAILABLE_LOCALES_SET = [ :en, "en" ]
  DEFAULT_LOCALE = :en

  def available_locales
    AVAILABLE_LOCALES
  end

  def available_locales_set
    AVAILABLE_LOCALES_SET
  end

  def default_locale
    DEFAULT_LOCALE
  end
end
