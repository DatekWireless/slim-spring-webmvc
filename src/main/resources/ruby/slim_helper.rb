# frozen_string_literal: true

["uri:classloader:/ruby", "uri:classloader:/gems", "uri:classloader:/gems/concurrent-ruby",].each do |path|
  $LOAD_PATH << path unless $LOAD_PATH.include?(path)
end

# Standard library
require 'jruby'
require 'bigdecimal'
require 'date'
require 'logger'
require 'stringio'
require 'uri'

# Gems
require 'concurrent/map'
require 'kramdown'
require 'slim'

# Local source
require 'request_context'
require 'bigdecimal_ext'
require 'locale_helper'
require 'form_helper'
require 'message_source_accessor'
require 'string_response'
require 'application_setup'

module SlimHelper
  include LocaleHelper
  include FormHelper

  import Java::JavaTime::LocalDateTime
  import Java::OrgSpringframeworkSecurityCoreContext::SecurityContextHolder
  import Java::OrgSpringframeworkWebContextRequest::RequestContextHolder
  import Java::OrgSpringframeworkWebServletSupport::RequestContextUtils

  NO_LAYOUT = [
    '/views/index.slim', # La stå!
    '/views/error.slim',
  ]
  SPRING_KEYS = [
    :__spring_security_filterSecurityInterceptor_filterApplied,
    :__spring_security_scpf_applied,
    :__spring_security_session_mgmt_filter_applied,
  ]

  PARTIAL_ATTR = 'no.datek.slim.partial'
  LOG = Java::OrgApacheLog4j::Logger.get_logger('no.datek.slim')
  TEMPLATE_CACHE ||= Concurrent::Map.new
  CONTENT_CACHE ||= Concurrent::Map.new
  VIEW_SHAPES ||= Concurrent::Map.new
  LAYOUT_TEMPLATE_PATH = "/views/layouts"
  DEFAULT_LAYOUT = "#{LAYOUT_TEMPLATE_PATH}/layout.slim"
  PATCHED_CLASSES = []

  def render_slim(template, variables, rendering_context)
    request = RequestContextHolder.request_attributes.request
    locale = current_locale(request)

    patch_class_with_accessor(request.class)
    patch_class_with_accessor(request.session.class)

    params = request.parameterMap
    def params.[](key)
      super(key.to_s)
    end

    context_values = RequestContext.default_context(locale, params, rendering_context, request)
    context_values.update Hash[variables.map{|k,v| [k.to_sym, v]}]
    context_values.update Hash[request.getAttributeNames.select { |a| a !~ /\./ && !context_values[a.to_sym] }.map { |a| [a.to_sym, request.getAttribute(a)] }]
    # context_values.update Hash[request.session.getAttributeNames.select { |a| a !~ /\./ && !context_values[a.to_sym] }.map { |a| [a.to_sym, request.session.getAttribute(a)] }]
    context_values.update RequestContext.application_attributes(request)
    keys = (context_values.keys - SPRING_KEYS).sort
    view_shape = VIEW_SHAPES.fetch_or_store(keys) do |key|
      LOG.info "Creating new view shape (#{rendering_context.url}): #{keys}"
      Struct.new(*keys)
    end
    context = view_shape.new(*context_values.fetch_values(*keys))

    rendering_partial = request.getAttribute(PARTIAL_ATTR)

    # start = Time.now
    templ = TEMPLATE_CACHE.fetch_or_store(rendering_context.url) do |key|
      CONTENT_CACHE.fetch(template.hash) do |content_key|
        LOG.info "Load SLIM template #{rendering_context.url.inspect}"
        Slim::Template.new(rendering_context.url) { template }
      end
    end
    # templ_at = Time.now
    page_html = templ.render(context)
    # LOG.info "Create template: #{templ_at - start}, render: #{Time.now - templ_at}, file: #{rendering_context.url}"

    if rendering_partial || request.getAttribute('__no_layout') ||
      NO_LAYOUT.include?(rendering_context.url) || request.getHeader("X-Requested-With") == "XMLHttpRequest"
      page_html
    else
      load_start = Time.now
      layout_template_path =
        if (layout_template = request.getAttribute('no.datek.layout'))
          "#{LAYOUT_TEMPLATE_PATH}/#{layout_template}.slim"
        else
          DEFAULT_LAYOUT
        end
      layout = TEMPLATE_CACHE.fetch_or_store(layout_template_path) do |key|
        while (stream = JRuby.runtime.jruby_class_loader.getResourceAsStream(layout_template_path.delete_prefix('/'))).nil?
          if (Time.now - load_start) > 10
            return "TEMPLATE #{layout_template_path} NOT FOUND!"
          end
          sleep 0.1
        end
        content = stream.to_io.read
        CONTENT_CACHE.fetch_or_store(content.hash) do |content_key|
          LOG.info "Load SLIM template #{layout_template_path.inspect}"
          Slim::Template.new(layout_template_path) { content }
        end
      end
      # render_start = Time.now
      html = layout.render(context) { page_html }
      # LOG.info "Create template: #{render_start - load_start}, render: #{Time.now - render_start}, file: #{LAYOUT_TEMPLATE_PATH}"
      html
    end
  rescue Exception => e # rubocop: disable Lint/RescueException
    message = <<~HTML
      Exception rendering view: #{rendering_context.url.inspect}

      #{e.class}: #{e.message}

      #{e}

      #{e.backtrace.join("\n")}
    HTML
    LOG.error message
    "<h1>Whoops!</h1><pre>#{CGI.escapeHTML(message)}</pre>"
  end

  # self in this context is the Struct with the context variables
  def render(view_path, params = {})
    # load_start = Time.now

    view_resolver =
      application_context.getBean(org.springframework.web.servlet.view.script.ScriptTemplateViewResolver.java_class)
    view = view_resolver.resolveViewName(view_path, RequestContextUtils.getLocale(request))

    raise "COULD NOT FIND VIEW #{view_path.inspect}" if view.nil?

    map = self.to_h.update Hash[params.map { |k, v| [k, v] }]
    request.setAttribute(PARTIAL_ATTR, true)
    partial_response = StringResponse.new(request.character_encoding)

    # render_start = Time.now
    view.render(map, request, partial_response)

    # LOG.info "Create template: #{render_start - load_start}, render: #{Time.now - render_start}, file: #{LAYOUT_TEMPLATE_PATH}"

    partial_response.body
  rescue Exception => e # rubocop: disable Lint/RescueException
    LOG.error "Exception rendering partial template: #{view_path.inspect}"
    LOG.error "#{e.class}: #{e.message}"
    LOG.info e.backtrace.join("\n")
    LOG.error e
    raise
  end

  def content_for(key, &block)
    if block
      if (new_content = capture(&block))
        if (existing_content = content_store[key.to_sym])
          existing_content << new_content
        else
          content_store[key.to_sym] = new_content
        end
      end
    else
      content_store[key.to_sym]
    end
  end

  def capture(&block)
    backup_buf = block.binding.local_variable_get(:_buf)
    block.binding.local_variable_set(:_buf, StringIO.new(+"", "w+t:UTF-8:UTF-8"))
    block.call
    buffer = block.binding.local_variable_get(:_buf)
    block.binding.local_variable_set(:_buf, backup_buf)
    buffer&.string
  end

  def yield_content(key)
    content_store[key.to_sym]
  end

  def present?(arg)
    !!presence(arg)
  end

  def presence(arg)
    v = eval(arg.to_s)
    v.nil? || (v.respond_to?(:empty?) && v.empty?) ? nil : v
  rescue NameError => e
    nil
  end

  def getter(name, obj = nil)
    g = "get#{name[0].upcase}#{name[1..-1]}"
    return g unless obj
    return g if obj.respond_to?(g)
    g = "is#{name[0].upcase}#{name[1..-1]}"
    return g if obj.respond_to?(g)

    raise "No get- or is- method for attribute #{name}"
  end

  def binding_result(command_name)
    request.getAttribute("org.springframework.validation.BindingResult.#{command_name}") ||
      self["org.springframework.validation.BindingResult.#{command_name}"]
  rescue
    nil
  end

  def with_command_bean(command_name)
    bs = binding_result(command_name)
    bs.class.class_eval do
      def [](field_name)
        getFieldValue(field_name.to_s)
      end
    end
    yield bs
  end

  def formatDateTime(date_time, format = 'yyyy-MM-dd HH:mm:ss', timeZoneId: TimeZoneHelper.current_time_zone(user))
    if date_time.nil?
      return ''
    end

    local_date_time =
      if !(LocalDateTime === date_time)
        DateUtils.toJava8LocalDateTime(date_time)
      else
        date_time
      end

    DateUtils.formatJava8DateTime(local_date_time, format, timeZoneId)
  end

  def formatDate(date, format = '%d.%m.%Y')
    if date.nil?
      return ''
    end
    java_date =
      if Java::JavaUtil::Date === date
        date
      else
        DateUtils.toDate(date)
      end
    d = Time.at(java_date.time / 1000.0)
    d.strftime(format)
  end

  def markdown(text)
    return "" if text.nil? || text.strip.empty?

    Kramdown::Document.new(text).to_html
  end

  def patch_class_with_accessor(clazz)
    return if PATCHED_CLASSES.include?(clazz)
    LOG.info "Patching attribute getters for #{clazz.inspect}"
    clazz.class_eval do
      def [](field_name)
        getAttribute(field_name.to_s)
      end

      def []=(field_name, value)
        setAttribute(field_name.to_s, value)
      end

      def method_missing(method_name)
        getAttribute(method_name.to_s)
      end
    end
    PATCHED_CLASSES << clazz
  end
end

include SlimHelper
