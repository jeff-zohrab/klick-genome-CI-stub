Rake.application.remove_task(:runtests)

task :runtests do
  raise 'simulating :runtests failure'
end
