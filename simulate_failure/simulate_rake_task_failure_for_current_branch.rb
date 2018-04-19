
def get_git_branch_name()
  # Ref https://git-blame.blogspot.ca/2013/06/checking-current-branch-programatically.html
  branch_name = `git symbolic-ref --short -q HEAD`
  return branch_name.strip
end

Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end

simulate_rake_error = File.join(File.dirname(__FILE__), get_git_branch_name, 'Rakefile.rb')
if (File.exist?(simulate_rake_error)) then
    require simulate_rake_error
end
