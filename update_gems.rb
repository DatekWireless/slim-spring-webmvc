#!/usr/bin/env ruby

require 'fileutils'

if RUBY_ENGINE != 'jruby'
  abort "Run this script with JRuby!"
end

FileUtils.rm_f 'gems.locked'
system "bin/bundle lock"
system "bin/bundle config set --local deployment 'true'"
system "bin/bundle install"

FileUtils.rm_rf Dir['src/main/resources/gems/*']

Dir['vendor/bundle/jruby/*/gems/*'].each do |gem|
  next if gem =~ /bundler/
  FileUtils.cp_r Dir["#{gem}/lib/*"], 'src/main/resources/gems/'
end

FileUtils.rm_rf '.bundle'
FileUtils.rm_rf 'vendor'
