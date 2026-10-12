class MissionControl::Jobs::I18nConfig < ::I18n::Config
  DEFAULT_LOCALE = :en

  def available_locales
    @available_locales ||= super | [ DEFAULT_LOCALE ]
  end

  def available_locales_set
    @available_locales_set ||= available_locales.flat_map { |locale| [ locale, locale.to_s ] }.to_set
  end

  def default_locale
    DEFAULT_LOCALE
  end
end
