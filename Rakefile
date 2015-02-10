require 'rake/testtask'
require 'bundler/gem_tasks'

task default: :test

Rake::TestTask.new do |t|
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end
