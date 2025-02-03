# frozen_string_literal: true

require 'listen'
require 'log'

module SourceReloader
  include Log

  layout_url = JRuby.runtime.jruby_class_loader.getResource(SlimRenderer::DEFAULT_LAYOUT.delete_prefix('/'))
  view_dir = File.dirname(File.dirname(layout_url.path))
  LOG.info "Scanning Slim source files for changes: #{view_dir}"
  resource_path = File.dirname(view_dir)
  Listen.to(view_dir) do |modified, added, removed|
    (modified + added + removed).each do |f|
      view_path = f.delete_prefix(resource_path)
      LOG.info "Invalidate: #{view_path.inspect}" if SlimRenderer::TEMPLATE_CACHE.delete(view_path)
    end
  end.start

  ruby_dir = JRuby.runtime.jruby_class_loader.getResource('ruby').path
  LOG.info "Scanning Ruby source files for changes: #{ruby_dir}"
  RUBY_CACHE = Concurrent::Map.new
  Dir["#{ruby_dir}/*.rb"].each { |f| RUBY_CACHE[f] = File.read(f) }
  Listen.to(ruby_dir) do |modified, added, removed|
    (modified + added).each do |f|
      next if f =~ /source_reloader/
      ruby_content = File.read(f)
      next if RUBY_CACHE[f] == ruby_content
      LOG.info "Reload: #{f.inspect}"
      load f
      RUBY_CACHE[f] = ruby_content
    end
  end.start
end
