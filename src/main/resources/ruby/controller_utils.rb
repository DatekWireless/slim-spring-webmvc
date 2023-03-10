module ControllerUtils
  def current_locale(request)
    locale = RequestContextUtils.getLocale(request)
    if locale.to_string.length > 2
      locale = Java::JavaUtil::Locale.new(locale.language)
    end
    locale
  end
end
