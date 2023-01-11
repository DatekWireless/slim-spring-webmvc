module ControllerUtils
  def current_locale(request)
    locale = RequestContextUtils.getLocale(request)
    if locale.to_string.length > 2
      locale = Java::JavaUtil::Locale.new(locale.language)
    end
    locale
  end

  @@message_source = Java::org.springframework.context.support::ReloadableResourceBundleMessageSource.new
  @@message_source.setCacheSeconds(300)
  @@message_source.setBasenames("classpath:lights_version", "classpath:lightsMessages")
  Java::no.datek.m2m.kernel.exceptions::M2mException.setMessageSource(@@message_source)

  def message_source
    @@message_source
  end

  def message_source_accessor(locale)
    MessageSourceAccessor.new(message_source, locale)
  end
end
