# frozen_string_literal: true

require 'English'
require 'rake/clean'

default_tasks = []

begin
  require 'rake/testtask'
  Rake::TestTask.new :test do |t|
    t.libs << 'test'
    t.pattern = 'test/**/*_test.rb'
    t.verbose = true
    t.warning = true
  end
rescue LoadError
  warn $ERROR_INFO.message
end

begin
  require 'bundler/gem_tasks'
  default_tasks << :build
rescue LoadError
  warn <<~MSG
    asciidoctor-csl: Bundler is required to build this gem.
    You can install Bundler using `gem install` command:

      $ [sudo] gem install bundler

  MSG
end

task default: default_tasks unless default_tasks.empty?
