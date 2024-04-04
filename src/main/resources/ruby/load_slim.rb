# frozen_string_literal: true

# This file is loaded once for every view that is instantiated.
# It uses (requires) a separate file to avoid loading the same code multiple times.
begin
  require 'ruby/slim_renderer'
rescue Exception => e
  Java::OrgApacheCommonsLogging::LogFactory.getLog('no.datek.slim').error(e.to_s)

  module SlimRenderer
    def self.render(template, model_map, rendering_context)
      "<h1>Whoops!</h1><p>Failed to load SLIM template framework.</p>"
    end
  end
end

