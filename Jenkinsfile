// Sensei build Jenkins pipeline.

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException
import java.text.SimpleDateFormat
import groovy.transform.Field

// Shared libraries, configured in https://ci.senseilabs.com/configure.
// Ref https://jenkins.io/doc/book/pipeline/shared-libraries/
@Library('genome') _
genome = new org.klick.Genome()
githelper = new org.klick.Git()

// Users can skip stages using config files (see Jenkins/config/README.md).
// The global variable (!) allows for the optional_stage helper method.
// ref https://stackoverflow.com/questions/6305910/
//    how-do-i-create-and-access-the-global-variables-in-groovy
@Field String[] SKIP_STAGES = []

// Unique db per Jenkins node/executor.
@Field String DB_NAME = ""

// Config
CODE_GITHUB_ORG = 'jeff-zohrab'  // TODO - fix this for actual pipeline
CODE_REPO_NAME = 'klick-genome-CI-stub'  // TODO - fix this for actual pipeline
TAG_USER_NAME = 'Jeff Zohrab' // TODO - fix this for actual pipeline
TAG_USER_EMAIL = 'jzohrab@gmail.com' // TODO - fix this for actual pipeline
DEFAULT_JENKINS_CHANNEL = 'jenkins-dev-tests' // TODO - fix this for actual pipeline

node('sensei_build') {

  // Slack channel to report to.
  def slack_channel = ''

  DB_NAME = "intranet_jnk_${env.NODE_NAME}_${env.EXECUTOR_NUMBER}"

  // Create directory (the GitHub plugin directory names are unwieldy,
  // per https://issues.jenkins-ci.org/browse/JENKINS-38706).
  genome.create_dir("c:\\www")
  ws("c:\\www\\genome") {

    try {
      checkout()
      // configure()  // TODO RESTORE THIS

      def pipeline_config = get_pipeline_config(env.BRANCH_NAME)
      SKIP_STAGES = pipeline_config['skip']
      slack_channel = get_slack_channel(pipeline_config)

      setup_db()

///////////////////////
// TODO _ REMOVE _ SCRAP

stage('try tag check') {
  bat 'git remote -v'

  // HACK STEALING
  args = [
      workspace_dir: env.WORKSPACE,
      branch_name: env.BRANCH_NAME,
      github_org: CODE_GITHUB_ORG,
      repo_name: CODE_REPO_NAME,
      ref_repo_parent_dir: 'c:\\reference_repo',
      creds_id: 'github-ci'
  ]
  withCredentials([usernamePassword(credentialsId: args.creds_id, passwordVariable: 'P', usernameVariable: 'U')]) {
    def s = "git fetch https://${U}:${P}@github.com/${args.github_org}/${args.repo_name}.git"
    bat s
    bat 'git log --decorate=full adc0eac01c08ba6d91 -n 4'
  } // end withCredentials

  // bat 'git log --decorate=full adc0eac01c08ba6d91 -n 4'
  // bat 'git log --decorate=full --all -n 4'
  // bat 'git log --decorate=full --all'
}

///////////////////////

      if (isDevelop()) {
        build_and_unit_test()
        tag_UT()
      }
      else if (isMaster()) {
        build_and_unit_test()
      }
      else if (isRelease()) {
        def nunit_filter = pipeline_config.get('nunit_filter', '')
        build_and_unit_test(nunit_filter)
        if (!pipeline_config_skipped_stage('NUnit') && nunit_filter == '') {
          tag_UT()  // We ran all the tests.
        }
        ui_testing([
          selenium_filter: pipeline_config.get('selenium_filter', ''),
          report_to_testrail: true,
          fail_on_error: false
        ])
      }
      else if (isQaauto()) {
        build_back_end()
        build_front_end()
        if (pipeline_config.containsKey('selenium_filter')) {
          ui_testing([
            selenium_filter: pipeline_config['selenium_filter'],
            report_to_testrail: false,
            fail_on_error: true
          ])
	}
      }
      else {
        build_and_unit_test(pipeline_config.get('nunit_filter', ''))
        if (pipeline_config.containsKey('selenium_filter')) {
          ui_testing([
            selenium_filter: pipeline_config['selenium_filter'],
            report_to_testrail: false,
            fail_on_error: true
          ])
        }
      }

      currentBuild.result = 'SUCCESS'

    } // end try
    catch(FlowInterruptedException interruptEx) {
      currentBuild.result = 'ABORTED'
    }
    catch(err) {
      echo "Error: ${err}"
      genome.notify_slack_channel_failure(err, slack_channel)
      currentBuild.result = 'FAILURE'
    }
    finally {
      genome.notify_slack_channel_if_back_to_normal(currentBuild, slack_channel)
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


def get_slack_channel(pipeline_config) {
  def ret = DEFAULT_JENKINS_CHANNEL
  if (isDevelop() || isMaster() || isRelease())
    ret = DEFAULT_JENKINS_CHANNEL
  else
    ret = pipeline_config.get('slack_channel', '')
  echo "Using slack channel: ${ret}"
  return ret
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


def test_back_end(nunit_filter) {
  optional_stage('NUnit') {
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
    bat 'npm test -- --single-run'
  }
}


def add_tag(name, message) {
  args = [
    tag_name: name,
    tag_message: message,
    tag_user_name: TAG_USER_NAME,
    tag_user_email: TAG_USER_EMAIL,
    github_org: CODE_GITHUB_ORG,
    repo_name: CODE_REPO_NAME,
    creds_id: 'github-ci'
  ]
  githelper.add_tag(args)
}


def tag_UT() {
  def dateFormat = new SimpleDateFormat("yyyyMMdd_HHmmss")
  def date = new Date()
  def tagname = "UT_" + dateFormat.format(date)
  add_tag(tagname, "Unit tests passed.")
}


def ui_testing(args_map) {
  echo "Got args: ${args_map}"
  stage('Run Selenium test') {
    configure_iis_and_start_site()
    bat 'rake compileqaattributedecorator compileqauitesting'
    reset_and_migrate_db()  // Required, as earlier stages may destroy data.
    selenium_args = [
      branch_name: env.BRANCH_NAME,
      selenium_filter: args_map.selenium_filter,
      report_to_testrail: args_map.report_to_testrail
    ]

    if (args_map.fail_on_error) {
      run_selenium(selenium_args)
    }
    else {
      run_selenium_no_fail(selenium_args)
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


// Run selenium, and fail the branch if tests fail.
// selenium_args: a map with the following values:
//   * selenium_filter: string
//   * report_to_testrail: true/false
//   * branch_name: branch
def run_selenium(selenium_args) {
  try {
    run_selenium_script(selenium_args)
  }
  finally {
    // The Jenkins nunit plugin marks the build
    // as "failed" if any tests fail.
    nunit testResultsPattern: 'SeleniumTestResult.xml'
    publish_selenium_artifacts()
  }
}


// Run selenium tests, but don't fail the branch even if tests fail.
// This method is separate from the run_selenium() method as it has
// completely different behaviour.
// selenium_args: a map with the following values:
//   * selenium_filter: string
//   * report_to_testrail: true/false
//   * branch_name: branch
def run_selenium_no_fail(selenium_args) {
  try {
    run_selenium_script(selenium_args)
  }
  catch(err) {
    // We're not failing the build if Selenium fails.
    // In some cases (e.g.release branches), we don't want to fail the build
    // if tests fail, as some tests are flaky.
    // Since the nunit plugin fails the whole build if
    // it sees test errors, don't use it.
    echo "Some tests failed, but we're ignoring them."
  }
  finally {
    publish_selenium_artifacts()
  }
}


def run_selenium_script(selenium_args) {
  timeout(180) {  // minutes
    powershell """QA\\Jenkins\\run_test.ps1 `
      -nunit_filter \"${selenium_args.selenium_filter}\" `
      -report_to_testrail ${selenium_args.report_to_testrail} `
      -branch_name ${selenium_args.branch_name}"""
  }
}


def publish_selenium_artifacts() {
  def artifact_pattern = 'QA\\UITesting\\SenseiOS.UI.Tests\\bin\\Debug\\Artifacts\\*.*'
  archiveArtifacts allowEmptyArchive: true, artifacts: artifact_pattern
}
