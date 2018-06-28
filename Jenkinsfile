// Sensei build Jenkins pipeline.

// Config
CODE_GITHUB_ORG = 'jeff-zohrab'  // TODO - fix this for actual pipeline
CODE_REPO_NAME = 'klick-genome-CI-stub'  // TODO - fix this for actual pipeline
TAG_USER_NAME = 'Jeff Zohrab' // TODO - fix this for actual pipeline
TAG_USER_EMAIL = 'jzohrab@gmail.com' // TODO - fix this for actual pipeline
DEFAULT_JENKINS_CHANNEL = 'jenkins-dev-tests' // TODO - fix this for actual pipeline


import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException
import java.text.SimpleDateFormat
import groovy.transform.Field
import groovy.json.JsonSlurperClassic

// Shared libraries, configured in https://ci.senseilabs.com/configure.
// Ref https://jenkins.io/doc/book/pipeline/shared-libraries/
@Library('genome') _
genome = new org.klick.Genome()
githelper = new org.klick.Git()
senseislack = new org.klick.SenseiSlack()

// User pipeline configuration (see Jenkins/config/README.md).
@Field PIPELINE_CONFIG = [:]

// Users can skip stages using config files (see Jenkins/config/README.md).
// The global variable (!) allows for the optional_stage helper method.
// ref https://stackoverflow.com/questions/6305910/
//    how-do-i-create-and-access-the-global-variables-in-groovy
@Field String[] SKIP_STAGES = []

// Unique db per Jenkins node/executor.
@Field String DB_NAME = ""


node('sensei_build') {

  DB_NAME = "intranet_jnk_${env.NODE_NAME}_${env.EXECUTOR_NUMBER}"

  // Create directory (the GitHub plugin directory names are unwieldy,
  // per https://issues.jenkins-ci.org/browse/JENKINS-38706).
  genome.create_dir("c:\\www")
  ws("c:\\www\\genome") {

    try {
      checkout()
      configure()

      PIPELINE_CONFIG = get_pipeline_config(env.BRANCH_NAME)
      SKIP_STAGES = PIPELINE_CONFIG['skip']

      setup_db()

      if (isDevelop()) {
        build_and_unit_test()
        def nunit_filter = PIPELINE_CONFIG.get('nunit_filter', '')
        tag_UT(nunit_filter)
      }
      else if (isMaster()) {
        build_and_unit_test()
      }
      else if (isRelease()) {
        def nunit_filter = PIPELINE_CONFIG.get('nunit_filter', '')
        build_and_unit_test(nunit_filter)
        tag_UT(nunit_filter)
        ui_testing([
          selenium_filter: PIPELINE_CONFIG.get('selenium_filter', ''),
          report_to_testrail: true,
          fail_on_error: false,
          tag_on_success: true
        ])
      }
      else if (isQaauto()) {
        build_back_end()
        build_front_end()
        if (PIPELINE_CONFIG.containsKey('selenium_filter')) {
          ui_testing([
            selenium_filter: PIPELINE_CONFIG['selenium_filter'],
            report_to_testrail: false,
            fail_on_error: true
          ])
	}
      }
      else {
        build_and_unit_test(PIPELINE_CONFIG.get('nunit_filter', ''))
        if (PIPELINE_CONFIG.containsKey('selenium_filter')) {
          ui_testing([
            selenium_filter: PIPELINE_CONFIG['selenium_filter'],
            report_to_testrail: false,
            fail_on_error: true
          ])
        }
      }

      currentBuild.result = 'SUCCESS'
      def p = currentBuild.previousBuild
      if (p != null && p.result != 'SUCCESS') {
        send_slack_back_to_normal()
      }

    } // end try
    catch(FlowInterruptedException interruptEx) {
      currentBuild.result = 'ABORTED'
    }
    catch(err) {
      echo "Error: ${err}"
      send_slack_failure(err)
      currentBuild.result = 'FAILURE'
    }
    finally {
      genome.stop_iis()
      cleanWs()
    }
  } // end ws()
}  // end node


///////////////////////////////////////////////////
// Helpers

def isDevelop() {
  return (env.BRANCH_NAME == 'develop')
}

def isMaster() {
  return (env.BRANCH_NAME == 'master')
}

def isQaauto() {
  return (env.BRANCH_NAME.startsWith('qaauto'))
}

def isRelease() {
  return (env.BRANCH_NAME.startsWith('release'))
}

def isCriticalBranch() {
  return (isDevelop() || isMaster() || isRelease())
}


def checkout() {
  stage('Checkout') {
    genome.stop_iis()  // Must use a shared lib, local repo isn't checked out yet.
    cleanWs()
    checkout_args = [
      workspace_dir: env.WORKSPACE,
      branch_name: env.BRANCH_NAME,
      github_org: CODE_GITHUB_ORG,
      repo_name: CODE_REPO_NAME,
      ref_repo_parent_dir: 'c:\\reference_repo',
      creds_id: 'github-ci'
    ]
    githelper.checkout_from_reference_repo(checkout_args)
  }
}

def configure() {
  stage('Config') {
    genome.create_web_config(DB_NAME)
    writeFile file: 'site.cfg', text: "jenkins_${env.NODE_NAME}"
    writeFile file: 'theme.cfg', text: 'genome'
    bat 'rake jenkins:fix_configs generateManifest'
    bat 'rake nlog:use_config[NLog.config.Jenkins]'
    powershell 'Set-Timezone -Name "Eastern Standard Time"'
  }
}


// Users can tweak the pipeline for their branches
// using config files in the "Jenkins" directory.
def get_pipeline_config(branch_name) {
  def config = [
    'skip': '',
    'nunit_filter': '',
    'slack_channel': ''
  ]
  config = override_config_for_branch(config, branch_name)

  def tmp = config['skip'].
             split(',').
             collect { it.trim() }.
             collect { it.toLowerCase() }
  config['skip'] = tmp
  echo "Got pipeline config: ${config}"
  return config
}


def override_config_for_branch(config, branch_name) {
  filename = 'Jenkins/config/' + branch_name.replaceAll('/', '_')
  if (!fileExists(filename))
    return config

  rawfile = readFile file: filename, encoding: 'ascii'
  lines = rawfile.
    split("\n").
    collect { s -> s.trim() }.
    findAll { s -> !s.startsWith('#') }. // Comment
    findAll { s -> s.contains(':') }.    // Must be key:value
    findAll { s -> !s.startsWith(':') }  // Bad line format

  // rawfile.eachLine doesn't work!
  for (line in lines) {
    // Not using a simple "(key, value) = line.split(':')",
    // in case the value also has a colon
    // (e.g, "nunit_filter: cat == Some:Category")
    def colon_pos = line.indexOf(':')
    def key = line.substring(0, colon_pos)
    def value = line.substring(colon_pos + 1, line.length())
    config << [(key.trim()): (value.trim())]
  }

  return config
}


// Users can skip steps included in the "skip" list in the Jenkins config file.
def optional_stage(stage_name, stage_closure) {
  if (SKIP_STAGES.contains(stage_name.toLowerCase())) {
    echo "Skipping ${stage_name}"
    return
  }

  // Ref http://mrhaki.blogspot.ca/2009/11/groovy-goodness-passing-closures-to.html
  stage(stage_name) {
    stage_closure()
  }
}


// 'true' if the user skipped the stage in the jenkins config file.
def pipeline_config_skipped_stage(stage_name) {
  return (SKIP_STAGES.contains(stage_name.toLowerCase()))
}


def setup_db() {
  optional_stage('Setup db') {
    reset_and_migrate_db()
  }
}


def reset_and_migrate_db() {
  timeout(10) { // minutes
    bat "rake resetdb[\"$DB_NAME\"] migrateschema"
  }
}


def build_and_unit_test(nunit_filter = '') {
  build_back_end()
  test_back_end(nunit_filter)
  build_front_end()
  test_front_end()
}


def build_back_end() {
  optional_stage('Compile back end') {
    bat 'rake migrateschemacheck base'
  }
}


def HEAD_has_tag(tag_regex, message) {
  if (githelper.commit_has_tag_matching_regex('HEAD', tag_regex)) {
    echo "${message} (current commit already has tag matching ${tag_regex})."
    return true
  }

  return false
}


def test_back_end(nunit_filter) {
  optional_stage('NUnit') {
    if (HEAD_has_tag(/UT_\d+/, 'Skip NUnit')) {
      return
    }
    try {
      bat "rake runtests[\"$nunit_filter\"]"
    }
    finally {
      nunit testResultsPattern: 'nunit-result.xml'
    }
  }
}


def build_front_end() {
  optional_stage('Compile client') {
    bat 'rake compileClient'
  }
}


def test_front_end() {
  optional_stage('Npm test') {
    if (HEAD_has_tag(/UT_\d+/, 'Skip Npm test')) {
      return
    }
    bat 'npm test -- --single-run'
  }
}


def add_tag_if_missing(tag_regex, tag_start, message) {
  if (HEAD_has_tag(tag_regex, "Don't re-tag with ${tag_start}")) {
    return
  }

  def dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss")
  def date = new Date()
  def tagname = tag_start + dateFormat.format(date)

  args = [
    tag_name: tagname,
    tag_message: message,
    tag_user_name: TAG_USER_NAME,
    tag_user_email: TAG_USER_EMAIL,
    github_org: CODE_GITHUB_ORG,
    repo_name: CODE_REPO_NAME,
    creds_id: 'github-ci'
  ]
  githelper.add_tag(args)
}


def tag_UT(nunit_filter) {
  def ran_nunit = !pipeline_config_skipped_stage('NUnit')
  def ran_all_tests = (nunit_filter == '')
  if (ran_nunit && ran_all_tests) {
    add_tag_if_missing(/UT_\d+/, "UT_", "Unit tests passed.")
  }
  else {
    echo "Not adding UT_ tag (ran_nunit=${ran_nunit}, ran_all_tests=${ran_all_tests})"
  }
}


// Tag if tagging is required, and if all the tests were run.
def tag_UI(tag_on_success, selenium_filter) {
  def ran_all_tests = (selenium_filter == '')
  if (tag_on_success && ran_all_tests) {
    add_tag_if_missing(/UI_\d+/, "UI_", "UI tests passed.")
  }
  else {
    echo "Not adding UI_ tag (tag_on_success=${tag_on_success}, ran_all_tests=${ran_all_tests})"
  }
}


def ui_testing(args_map) {
  echo "Got args: ${args_map}"
  stage('Run Selenium test') {
    if (HEAD_has_tag(/UI_\d+/, 'Skip Selenium test')) {
      return
    }

    configure_iis_and_start_site()
    bat 'rake compileqaattributedecorator compileqauitesting'
    reset_and_migrate_db()  // Required, as earlier stages may destroy data.

    try {
      timeout(180) {  // minutes
        powershell """QA\\Jenkins\\run_test.ps1 `
          -nunit_filter \"${args_map.selenium_filter}\" `
          -report_to_testrail ${args_map.report_to_testrail} `
          -branch_name ${env.BRANCH_NAME}"""
      }
      tag_UI(args_map.get('tag_on_success', false), args_map.selenium_filter)
    }
    catch(err) {
      handle_error(err, args_map.fail_on_error)
    }
    finally {
      publish_selenium_artifacts(args_map.fail_on_error)
    }
  }
}


// Jenkins deletes the workspace, which appears to confuse IIS.
// Setting everything up afresh for the run.
def configure_iis_and_start_site() {
  withCredentials([string(credentialsId: 'senseilabs-com-pfx-certificate-password', variable: 'P')]) {
    withEnv(["ENV_CERT_PASS=${P}"]) {
      powershell "Scripts\\Jenkins\\IIS\\setup_iis.ps1"
    }
  }
}


// In some cases (e.g.release branches), we don't fail the build
// if tests fail, as some tests are flaky.
def handle_error(err, fail_on_error) {
  if (fail_on_error) {
    throw err
  }
  echo "Some tests failed, but we're ignoring them."
}


def publish_selenium_artifacts(fail_on_error) {
  def artifact_pattern = 'QA\\UITesting\\SenseiOS.UI.Tests\\bin\\Debug\\Artifacts\\*.*'
  archiveArtifacts allowEmptyArchive: true, artifacts: artifact_pattern

  // The nunit plugin fails the whole build if
  // it sees test errors, so only use it if failing the build.
  if (fail_on_error) {
    nunit testResultsPattern: 'SeleniumTestResult.xml'
  }
}


// ------------------------
// Slack notifications

def send_slack_failure(err) {
  def subject = "*${env.BRANCH_NAME}* build failed"
  def channels = get_slack_channels()
  echo "Notifying failure on slack channels: ${channels}"
  for (c in channels) {
    def append = get_last_committer_message(c)
    senseislack.post_failure([subject: subject + append, channel: c])
  }
}


// When sending a message to a team channel, append
// who made the last commit to the branch.
// Don't bother adding anything for direct messages,
// and don't "blame" anyone for critical branches.
def get_last_committer_message(channel) {
  if (channel.startsWith('@') || isCriticalBranch())
    return ''
  return " (last commit by ${last_committer_email().replaceAll(/@.*/, '')})"
}


def send_slack_back_to_normal() {
  def subject = "*${env.BRANCH_NAME}* build passed, back to normal! :tada:"
  def channels = get_slack_channels()
  echo "Notifying back to normal on slack channels: ${channels}"
  for (c in channels) {
    senseislack.post_success([subject: subject, channel: c])
  }
}


def get_slack_channels() {
  if (isCriticalBranch()) {
    return [ DEFAULT_JENKINS_CHANNEL ]
  }

  // Jenkins config files
  configured = PIPELINE_CONFIG.get('slack_channel', '')
  if (configured != '')
    return configured.split(',').collect { it.trim() }

  try {
    return get_slack_channels_from_google_sheet()
  }
  catch(err) {
    // Swallow this exception ... if gsheets lookup fails,
    // it shouldn't fail the build!
    echo "WARNING: failed gsheets lookup.  ${err}"
    senseislack.post_failure([subject: "Failed gsheets lookup", body: "`${err}`", channel: '#ops-jenkins'])
  }

  // Fallback.
  return []
}


def last_committer_email() {
  def raw = bat(script: 'git log -n 1 --format="%%ae"', returnStdout: true)
  def emails = raw.split("\n").findAll { it.contains('@') }
  if (emails.size() == 0)
    return 'unknown@unknown.com'   // In case people didn't specify their email.
  return emails[0]
}


def get_slack_channels_from_google_sheet() {
  def email = last_committer_email()
  echo "Looking up email: ${email}"

  def data = [:]
  dir('Scripts/team_lookup') {
    config_team_lookup()
    bat "ruby lookup_slack_channel.rb --email ${email} --output channel.json"
    data = getJson(readFile('channel.json'))
  }
  echo "Got data: ${data}"

  if (data.warning.trim() != '') {
    def msg = [subject: data.warning, channel: '#ops-jenkins']
    senseislack.post_warning(msg)
  }

  return data.channels.
    flatten().
    findAll { it != null && it.trim() != '' }.
    sort().
    unique()
}


def config_team_lookup() {
  bat "rake gem:install_cert gem:install"
  withCredentials([
      file(credentialsId: 'google-sheets-client-secret-json', variable: 'CS'),
      file(credentialsId: 'google-sheets-token-yml', variable: 'T')
    ]) {
    writeFile file: 'client_secret.json', text: readFile(CS)
    writeFile file: 'token.yml', text: readFile(T)
  }
}


// Use JsonSlurperClassic -- JsonSlurper returns LazyMap, which causes all
// sorts of trouble non-serializable exceptions.  Big time waster!
@NonCPS
def getJson(s) {
  def slurper = new groovy.json.JsonSlurperClassic()
  return slurper.parseText(s)
}
