# frozen_string_literal: true

module LocaleHelper
  import Java::OrgSpringframeworkWebServletSupport::RequestContextUtils
  import Java::OrgSpringframeworkSecurityCoreContext::SecurityContextHolder
  import Java::JavaUtil::Locale

  SUPPORTED_LOCALES = {
    "nb" => "text.language.norwegian",
    "en" => "text.language.english",
    "sv" => "text.language.swedish",
    "iw" => "text.language.hebrew",
  }.freeze
  LOCALE_MAP = {
    "no" => "nb",
    "se" => "sv",
    "he" => "iw",
  }.freeze

  def current_locale(request)
    locale = RequestContextUtils.getLocale(request)
    if SUPPORTED_LOCALES.key?(locale.language)
      return locale
    end

    local_name = LOCALE_MAP[locale.language]
    if local_name
      return Locale.new(locale.language)
    end
    user = SecurityContextHolder.context&.authentication&.principal
    customer = user.try(:current_customer)
    if customer
      return customer.locale
    end
    if SystemUtils.isUK
      return Locale::UK
    end
    Locale.new("nb")
  end
end
