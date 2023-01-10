require 'listen'

layout_url = JRuby.runtime.jruby_class_loader.getResource(SlimHelper::DEFAULT_LAYOUT.delete_prefix('/'))
view_dir = File.dirname(File.dirname(layout_url.path))
resource_path = File.dirname(view_dir)

listener = Listen.to(view_dir) do |modified, added, removed|
  (modified + added + removed).each do |f|
    view_path = f.delete_prefix(resource_path)
    puts "Invalidate: #{view_path.inspect}" if SlimHelper::TEMPLATE_CACHE.delete(view_path)
  end
end
listener.start

RUBY_CACHE = Concurrent::Map.new
ruby_dir = JRuby.runtime.jruby_class_loader.getResource('ruby').path
Dir["#{ruby_dir}/*.rb"].each { |f| RUBY_CACHE[f] = File.read(f) }
ruby_listener = Listen.to(ruby_dir) do |modified, added, removed|
  (modified + added).each { |f|
    next if f =~ /source_reloader/
    ruby_content = File.read(f)
    next if RUBY_CACHE[f] == ruby_content
    puts "Reload: #{f.inspect}"
    load f
    RUBY_CACHE[f] = ruby_content
  }
end
ruby_listener.start

puts 'Scanning Ruby and Slim source files for changes.'
