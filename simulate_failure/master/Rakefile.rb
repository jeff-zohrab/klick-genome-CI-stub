Rake.application.remove_task(:runtests)

task :runtests, :filter do |t, args| do
  raise 'simulating :runtests failure'
end
