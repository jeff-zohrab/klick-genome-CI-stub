# Look up slack channels by user email.
#
# Write to json file for downstream processes.

require 'optparse'
require 'json'

require_relative 'sensei-lookup'

options = {}
OptionParser.new do |opt|
  opt.on('--email E') { |o| options[:email] = o }
  opt.on('--output O') { |o| options[:output] = o }
end.parse!

s = SenseiLookup.new()
hsh = s.git_commit_email_to_slack_channel_list_hash()

warning = ''
sheet_id = s.config[:google_sheet][:spreadsheet_id]
sheet_url = "https://docs.google.com/spreadsheets/d/#{sheet_id}"
warning = "Missing email #{options[:email]} from team sheet #{sheet_url}" unless hsh.key?(options[:email])

result = {
  email_exists: hsh.key?(options[:email]),
  warning: warning,
  channels: (hsh[options[:email]] || [])
}

puts result.to_json

output = options[:output]
if !output.nil? then
  File.open(output, 'w') { |f| f.write(result.to_json) }
  puts "Wrote #{output}"
end
