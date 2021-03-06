# Simulate success/failure.

def get_git_branch_name()
  # Ref https://git-blame.blogspot.ca/2013/06/checking-current-branch-programatically.html
  branch_name = `git symbolic-ref --short -q HEAD`
  if (branch_name.strip == '') then
    branch_name = ENV['BRANCH_NAME'] || ''   # Read from Jenkins environment var.
  end
  return branch_name.strip
end

$selenium_failure_flag_file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'QA', 'Jenkins', 'simulate_selenium_failure.txt'))

def set_selenium_success()
  puts "clearing failure file at #{$selenium_failure_flag_file}"
  if (File.exist?($selenium_failure_flag_file)) then
    File.delete($selenium_failure_flag_file)
  end
end

def set_selenium_failure()
  puts "SETTING failure file at #{$selenium_failure_flag_file}"
  File.open($selenium_failure_flag_file, 'w') do |f|
    f.puts "FAIL"
  end
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

######################3
# Main

set_selenium_success()

default_errors = File.join(File.dirname(__FILE__), "DEFAULT.rb")
require default_errors

branch_name = get_git_branch_name()
simulate_errors = File.join(File.dirname(__FILE__), "#{branch_name.gsub('/', '_')}.rb")

puts "Got branch: '#{branch_name}', checking for err simulation at #{simulate_errors}"
if (File.exist?(simulate_errors)) then
  puts "Simulating errors ..."
  require simulate_errors
end

