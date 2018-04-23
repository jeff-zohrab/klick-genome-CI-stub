# Copies the Jenkinsfile in klick-genome to here, and mods it.
# (assumed to be in a sibling directory).
#
# HACK ASSUMPTIONS:
# - regexes the file in place

src = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'klick-genome', 'Jenkinsfile'))
puts "Generating Jenkinsfile from #{src}"
raise "Missing #{src}" if (!File.exist?(src))

write_Jenkinsfile = File.expand_path(File.join(File.dirname(__FILE__), '..', 'Jenkinsfile'))

File.open(write_Jenkinsfile, 'w') do |f|
  # f.puts "// HACK COPIED JENKINSFILE //"
  # f.puts "// HACK COPIED JENKINSFILE //"
  # f.puts "// HACK COPIED JENKINSFILE //"

  f.puts File.read(src)
end

puts "Done generating Jenkinsfile."
