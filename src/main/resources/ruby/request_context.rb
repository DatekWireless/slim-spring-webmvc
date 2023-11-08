# frozen_string_literal: true

module RequestContext
  EMPTY_HASH = {}.freeze

  def self.default_context(locale, params, rendering_context, request)
    application_context = rendering_context.application_context
    message_source = application_context.get_bean(org.springframework.context.MessageSource.java_class)
    message_source_accessor = MessageSourceAccessor.new(message_source, locale)
    {
      application_context: application_context,
      content_store: {},
      ctx: request.contextPath,
      current_user: SecurityContextHolder.context&.authentication&.principal,
      locale: locale,
      message: message_source_accessor,
      messages: message_source,
      messageSource: message_source,
      message_source: message_source,
      param: params,
      params: params,
      request: request,
      session: request.getSession(),
      user: request.session.getAttribute("user") || SecurityContextHolder.context&.authentication&.principal,
    }
  end

  # Override this method to set your application specific request attributes.
  def self.application_attributes(request)
    EMPTY_HASH
  end
end