#!/usr/bin/env ruby

require 'fileutils'

if RUBY_ENGINE != 'jruby'
  abort "Run this script with JRuby!"
end

system "bin/bundle update --bundler"
system "bin/bundle config set --local deployment 'true'"
system "bin/bundle install"

FileUtils.rm_rf 'src/main/resources/gems/*'

Dir['vendor/bundle/jruby/*/gems/*'].each do |gem|
  next if gem =~ /bundler/
  FileUtils.cp_r Dir["#{gem}/lib/*"], 'src/main/resources/gems/'
end

FileUtils.rm_rf '.bundle'
FileUtils.rm_rf 'vendor'
