# Stub out all of the Rake tasks in the klick-genome project
# (assumed to be in a sibling directory).
#
# HACK ASSUMPTIONS:
# - the Rakefile is nicely formatted (tasks in namespaces are indented)

src = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'klick-genome', 'Rakefile'))
puts "Generating Rakefile from #{src}"
raise "Missing #{src}" if (!File.exist?(src))

r = File.read(src)
skeleton =
  r.
    split("\n").
    select { |lin| lin =~ /^\s*namespace/ || lin =~ /^\s*task/ || lin =~ /^\s*desc/ }
# puts skeleton
# puts "===="

add_namespace_end_keywords = []

def starts_with_space(line)
  return (line  =~ /^\s+/)
end

skeleton.each_with_index do | lin, index |
  add_namespace_end_keywords << lin
  if starts_with_space(skeleton[index]) and !starts_with_space(skeleton[index + 1]) then
    add_namespace_end_keywords << 'end'
  end
end

# puts add_namespace_end_keywords
# puts "==="

body = add_namespace_end_keywords.map do |lin|
  if lin =~ /^\s*task/
    taskname = lin.match(/task\s+:(.*?)\s/)[1]
    "#{lin} puts \"  called #{taskname}\" end"
  else
    lin
  end
end

# puts "==="
# puts "BODY"
# puts body

write_rakefile = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Rakefile'))

File.open(write_rakefile, 'w') do |f|
  f.puts "### GENERATED FILE ###"
  f.puts "# This file was generated with the script"
  f.puts "# scripts/create_stub_klick_genome_rakefile.rb"
  f.puts ''
end

File.open(write_rakefile, 'a') do |f|
  f.puts body.join("\n")
end

File.open(write_rakefile, 'a') do |f|
  f.puts ''
  f.puts '# SIMULATING RAKE ERRORS'
  f.puts "require_relative 'simulate_failure/simulate_rake_task_failure_for_current_branch.rb'"
end

puts "Done generating rakefile."

