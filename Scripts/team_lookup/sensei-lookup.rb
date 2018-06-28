
require 'yaml'
require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'pp'

$stdout.sync = true


class SenseiLookup
  
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sensei Team Google Sheets Ruby Lookup'.freeze
  this_dir = File.dirname(__FILE__)
  CLIENT_SECRETS_PATH = File.join(this_dir, 'client_secret.json').freeze
  CONFIG_PATH = File.join(this_dir, 'config.yml').freeze
  CREDENTIALS_PATH = File.join(this_dir, 'token.yml').freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  def initialize()
    file_must_exist CLIENT_SECRETS_PATH
    file_must_exist CONFIG_PATH
    @config = YAML.load_file(CONFIG_PATH)

    # Calls to the spreadsheet are expensive, cache them during dev.
    @raw_data_cache = nil
  end

  attr_reader :config

  def file_must_exist(filename)
    raise "Missing #{filename}" unless File.exist?(filename)
  end

  def log(s)
    $stdout.puts s
  end

  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization.
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)

    scope = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      msg = <<HERE
Go to this URL in your browser, and get the resulting code after authorization:

#{url}

HERE
      $stdout.puts msg
      $stdout.print 'code: '
      code = STDIN.gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )

      $stdout.puts "Generated #{CREDENTIALS_PATH}"
    end

    credentials
  end


  def get_raw_data()
    return @raw_data_cache if @raw_data_cache

    if !File.exist?(CREDENTIALS_PATH) then
      $stderr.puts
      $stderr.puts "Missing #{CREDENTIALS_PATH}."
      $stderr.puts "Please call 'authorize' first."
      $stderr.puts
      file_must_exist CREDENTIALS_PATH
    end

    # Initialize API
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize

    log 'Reading sheet'
    spreadsheet_id = @config[:google_sheet][:spreadsheet_id]
    people_range = @config[:google_sheet][:people_range]
    team_range = @config[:google_sheet][:team_range]
    response = service.batch_get_spreadsheet_values(spreadsheet_id, ranges: [people_range, team_range])

    v = response.value_ranges

    string_to_bool = lambda { |s| ['yes', 'y', 'true'].include?((s || '').downcase) }
    
    # The results are returned in the same order as the ranges passed
    # to batch_get_spreadsheet_values.
    people = v[0].values.map do |row|
      {
        name: row[0],
        git_commit_emails: row[1].split(',').map { |e| e.strip },
        team: row[2],
        slack_username: row[3],
        notify_me: string_to_bool.call(row[6]),
        notify_team: string_to_bool.call(row[7])
      }
    end

    teams = v[1].values.map do |row|
      {
        name: row[0],
        slack_channel: row[1]
      }
    end

    @raw_data_cache =
      {
        people: people,
        teams: teams
      }
    @raw_data_cache
  end


  def git_commit_email_to_slack_channel_list_hash()
    ret = {}
    raw_data = get_raw_data()
    raw_data[:people].each do |p|
      team = raw_data[:teams].select { |h| h[:name] == p[:team] }[0] || {}
      channels = []
      channels << "@#{p[:slack_username]}" if (p[:notify_me] && p[:slack_username])
      channels << "\##{team[:slack_channel]}" if (p[:notify_team] && team[:slack_channel])
      p[:git_commit_emails].each do |e|
        ret[e] = channels
      end
    end
    ret
  end


  # Verification step for rake only.
  def test()
    pp git_commit_email_to_slack_channel_list_hash()
  end

end
