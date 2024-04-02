# frozen_string_literal: true

require 'kramdown'
require 'string_response'
require_relative 'class_patcher'
require_relative 'locale_helper'

module SlimHelper
  include LocaleHelper
  include ClassPatcher
  import Java::JavaTime::LocalDateTime

  LOG = Java::OrgApacheCommonsLogging::LogFactory.getLog('no.datek.slim')

  # self in this context is the Struct with the context variables
  def render(view_path, params = {})
    view_resolver =
      application_context.getBean(org.springframework.web.servlet.view.script.ScriptTemplateViewResolver.java_class)
    view = view_resolver.resolveViewName(view_path, current_locale(request))

    raise "COULD NOT FIND VIEW #{view_path.inspect}" if view.nil?

    model_map = { content_store: content_store }.update(params)
    request.setAttribute(SlimRenderer::PARTIAL_ATTR, true)
    response = StringResponse.new(request.character_encoding)
    view.render(model_map, request, response)
    response.body
  rescue Exception => e # rubocop: disable Lint/RescueException
    LOG.error "Exception rendering partial template: #{view_path.inspect}"
    LOG.error "#{e.class}: #{e.message}"
    LOG.error e.to_s
    LOG.info e.backtrace.join("\n")
    raise
  end

  def asset_path(path)
    Java::NoDatekSlim::AssetStore.getHashedPath(path)
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

  def getter(name, obj = nil)
    g = "get#{name[0].upcase}#{name[1..-1]}"
    return g unless obj
    return g if obj.respond_to?(g)
    g = "is#{name[0].upcase}#{name[1..-1]}"
    return g if obj.respond_to?(g)

    raise "No get- or is- method for attribute #{name}"
  end

  module BindingResultPatch
    def [](field_name)
      getFieldValue(field_name.to_s)
    end
  end

  def binding_result(command_name)
    key = "org.springframework.validation.BindingResult.#{command_name}"
    br = model_map.get(key) || request.getAttribute(key) || self[key]
    raise "Binding result for #{command_name.inspect} is missing." if br.nil?
    patch_class_with_module(br.class, BindingResultPatch)
    br
  end

  def with_binding_result(command_name)
    yield binding_result(command_name)
  end

  def formatDateTime(date_time, format = 'yyyy-MM-dd HH:mm:ss', timeZoneId: TimeZoneHelper.current_time_zone(user))
    if date_time.nil?
      return ''
    end

    local_date_time =
      if !(LocalDateTime === date_time)
        DateUtils.toLocalDateTime(date_time)
      else
        date_time
      end

    DateUtils.formatLocalDateTime(local_date_time, format, timeZoneId)
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
end
