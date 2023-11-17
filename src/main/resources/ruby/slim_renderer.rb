# frozen_string_literal: true

["uri:classloader:/ruby", "uri:classloader:/gems", "uri:classloader:/gems/concurrent-ruby",].each do |path|
  $LOAD_PATH << path unless $LOAD_PATH.include?(path)
end

# Standard library
require 'jruby'

# Gems
require 'concurrent/map'
require 'slim'

# Local source
require 'bigdecimal_ext'
require_relative 'core_ext'
require_relative 'view_context'
require_relative 'locale_helper'
require_relative 'request_context'
require 'application_setup'

module SlimRenderer
  include LocaleHelper

  import Java::OrgSpringframeworkWebContextRequest::RequestContextHolder

  NO_LAYOUT = [
    '/views/index.slim', # La stå!
    '/views/error.slim',
  ]
  LOG = Java::OrgApacheCommonsLogging::LogFactory.getLog('no.datek.slim')
  TEMPLATE_CACHE ||= Concurrent::Map.new
  CONTENT_CACHE ||= Concurrent::Map.new
  PARTIAL_ATTR = 'no.datek.slim.partial'
  LAYOUT_TEMPLATE_PATH = "/views/layouts"
  DEFAULT_LAYOUT = "#{LAYOUT_TEMPLATE_PATH}/layout.slim"

  def render_slim(template, model_map, rendering_context)
    request = RequestContextHolder.request_attributes.request
    locale = current_locale(request)

    patch_class_with_accessor(request.class)
    patch_class_with_accessor(request.session.class)

    params = request.parameterMap
    def params.[](key)
      super(key.to_s)
    end

    app_view_context = RequestContext.application_attributes(request)
    default_context = RequestContext.default_context(locale, params, rendering_context, request)
    content_store = model_map[:content_store] || {}
    context = ViewContext.new(app_view_context:, content_store:, default_context:, model_map:, request:)
    rendering_partial = request.getAttribute(PARTIAL_ATTR)

    templ = TEMPLATE_CACHE.compute_if_absent(rendering_context.url) do |key|
      CONTENT_CACHE.compute_if_absent(template.hash) do |content_key|
        LOG.info "Load SLIM template #{rendering_context.url.inspect}"
        Slim::Template.new(rendering_context.url) { template }
      end
    end
    page_html = templ.render(context)

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
      layout = TEMPLATE_CACHE.compute_if_absent(layout_template_path) do |key|
        while (stream = JRuby.runtime.jruby_class_loader.getResourceAsStream(layout_template_path.delete_prefix('/'))).nil?
          if (Time.now - load_start) > 10
            return "TEMPLATE #{layout_template_path} NOT FOUND!"
          end
          sleep 0.1
        end
        content = stream.to_io.read
        CONTENT_CACHE.compute_if_absent(content.hash) do |content_key|
          LOG.info "Load SLIM template #{layout_template_path.inspect}"
          Slim::Template.new(layout_template_path) { content }
        end
      end
      layout.render(context) { page_html }
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

  module AccessorPatch
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

  def patch_class_with_accessor(clazz)
    return if clazz.ancestors.include?(AccessorPatch)
    LOG.info "Patching attribute getters for #{clazz.inspect}"
    clazz.include AccessorPatch
  end
end

include SlimRenderer

if Java::JavaLang::System.getProperty("spring.profiles.active").include?('development')
  require 'source_reloader'
end
