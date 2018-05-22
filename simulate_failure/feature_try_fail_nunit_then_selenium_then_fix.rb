# Rake.application.remove_task(:runtests)
task :runtests, :filter do |t, args|
  raise 'simulating :runtests failure'
end

set_selenium_failure()
