# frozen_string_literal: true

require 'message_source_accessor'

module RequestContext
  begin
    import Java::OrgSpringframeworkSecurityCoreContext::SecurityContextHolder
  rescue NameError, LoadError
    # Running without security.
  end

  EMPTY_HASH = {}.freeze

  def self.default_context(locale, params, rendering_context, request)
    application_context = rendering_context.application_context
    message_source = application_context.get_bean(org.springframework.context.MessageSource.java_class)
    message_source_accessor = MessageSourceAccessor.new(message_source, locale)
    context = {
      application_context: application_context,
      ctx: request.contextPath,
      locale: locale,
      message: message_source_accessor,
      messages: message_source,
      messageSource: message_source,
      message_source: message_source,
      param: params,
      params: params,
      request: request,
      session: request.getSession(),
    }
    if defined?(SecurityContextHolder)
      principal = SecurityContextHolder.context&.authentication&.principal
      context.merge!({
        current_user: principal,
        user: request.session.getAttribute("user") || principal,
      })
    end
    context
  end

  # Override this method to set your application specific request attributes.
  def self.application_attributes(request)
    EMPTY_HASH
  end
end
