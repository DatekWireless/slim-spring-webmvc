module ControllerUtils
  def current_locale(request)
    locale = RequestContextUtils.getLocale(request)
    if locale.to_string.length > 2
      locale = Java::JavaUtil::Locale.new(locale.language)
    end
    locale
  end

  if defined?(Java::NoDatekM2mWebLightsController::ControllerUtils)
    def message_source
      messageSource = ReloadableResourceBundleMessageSource.new
      messageSource.setCacheSeconds(300)
      messageSource.setBasenames("classpath:lights_version", "classpath:lightsMessages")
      ControllerUtils.setMessageSource(messageSource)
      M2mException.setMessageSource(messageSource)
    end
    def message_source_accessor(locale)
      MessageSourceAccessor.new(message_source(locale), locale)
    end
  else
    def message_source
      nil
    end
    def message_source_accessor(locale)
      nil
    end
  end

end
