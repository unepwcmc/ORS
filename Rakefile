# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake/testtask'

Rake::TestTask.new("test:all") do |t|
  t.libs = ["lib", "test"]
  t.test_files = FileList['test/**/*_test.rb']
end

OnlineReportingTool::Application.load_tasks
