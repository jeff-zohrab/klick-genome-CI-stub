
def get_git_branch_name()
  # Ref https://git-blame.blogspot.ca/2013/06/checking-current-branch-programatically.html
  branch_name = `git symbolic-ref --short -q HEAD`
  if (branch_name.strip == '') then
    branch_name = ENV['BRANCH_NAME'] || ''   # Read from Jenkins environment var.
  end
  return branch_name.strip
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

branch_name = get_git_branch_name()
puts "Got branch: '#{branch_name}'"
simulate_rake_error = File.join(File.dirname(__FILE__), branch_name, 'Rakefile.rb')
if (File.exist?(simulate_rake_error)) then
    require simulate_rake_error
end
