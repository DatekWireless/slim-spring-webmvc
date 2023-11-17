# frozen_string_literal: true

require 'uri'
require 'slim_helper'
require 'form_helper'

class ViewContext
  include SlimHelper
  include FormHelper

  attr_reader :app_view_context, :content_store, :default_context, :model_map, :request

  def initialize(**attributes)
    attributes.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def [](key)
    if model_map.key?(key)
      model_map.get(key)
    elsif model_map.key?(key.to_s)
      model_map.get(key.to_s)
    elsif app_view_context.key?(key)
      app_view_context[key]
    elsif default_context.key?(key)
      default_context[key]
    elsif request.attribute_names.include?(key.to_s)
      request.getAttribute(key.to_s)
    else raise(NameError, "no key: #{key.inspect}")
    end
  end

  def method_missing(method_name, *args, **opts)
    self[method_name]
  rescue NameError
    super
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
end
