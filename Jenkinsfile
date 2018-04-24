// Sensei build Jenkins pipeline.

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException
import groovy.transform.Field

// Shared libraries.
// Configured in https://ci.senseilabs.com/configure.
// Ref https://jenkins.io/doc/book/pipeline/shared-libraries/
@Library('genome') _   // Shared library in Jenkins.

// Users can tailor parts of pipeline using config files
// See Jenkins/README.md.
// Using a global variable (!) to allow for the optional_stage helper method.
// ref https://stackoverflow.com/questions/6305910/
//    how-do-i-create-and-access-the-global-variables-in-groovy
@Field Map PIPELINE_CONFIG = null

// Shared library instances.
genome = new org.klick.Genome()
githelper = new org.klick.Git()


node('sensei_build') {

  // Code repo.
  def code_github_org = 'jeff-zohrab'
  def code_repo_name = 'klick-genome-CI-stub'

  // Slack channel to report to (specified in Jenkins config file)
  def slack_channel = ''

  // Each Jenkins node/executor gets its own DB.
  // db_name must start with "intranet_jnk_" (see UnitTests/DatabaseTestBase.cs)
  def db_name = "intranet_jnk_${env.NODE_NAME}_${env.EXECUTOR_NUMBER}"

  // The GitHub plugin creates unusable directory names
  // (ref https://issues.jenkins-ci.org/browse/JENKINS-38706),
  // so hardcode the workspace we'll use, and create dirs as needed.
  genome.create_dir("c:\\www")
  ws("c:\\www\\genome") {

    try {
      checkout(code_github_org, code_repo_name)
      slack_channel = PIPELINE_CONFIG['slack_channel']
      configure(db_name)

      if (env.BRANCH_NAME == 'develop') {
        stage('Lock schema migrations') {
	  lock_schema_migrations()
        }
      }

      setup_db(db_name)
      full_build_and_unit_test()
      if (PIPELINE_CONFIG.containsKey('selenium_filter')) {
        ui_testing([db_name: db_name, fail_on_error: true, report_to_testrail: true])
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


def checkout(code_github_org, code_repo_name) {
  stage('Checkout') {
    genome.stop_iis()  // Must use a shared lib, local repo isn't checked out yet.
    cleanWs()
    checkout_args = [
      workspace_dir: env.WORKSPACE,
      branch_name: env.BRANCH_NAME,
      github_org: code_github_org,
      repo_name: code_repo_name,
      ref_repo_parent_dir: 'c:\\reference_repo',
      creds_id: 'github-ci'
    ]
    githelper.checkout_from_reference_repo(checkout_args)
    PIPELINE_CONFIG = genome.get_pipeline_config(env.BRANCH_NAME)
  }
}

def configure(db_name) {
  stage('Config') {
    genome.create_web_config(db_name)
    writeFile file: 'site.cfg', text: "jenkins_${env.NODE_NAME}"
    writeFile file: 'theme.cfg', text: 'genome'
    bat 'rake jenkins:fix_configs generateManifest'
    bat 'rake nlog:use_config[NLog.config.Jenkins]'
    powershell 'Set-Timezone -Name "Eastern Standard Time"'
  }
}


// Users can skip steps included in the "skip" list in the Jenkins config file.
def optional_stage(stage_name, stage_closure) {
  if (PIPELINE_CONFIG['skip'].contains(stage_name.toLowerCase())) {
    echo "Skipping ${stage_name}"
    return
  }

  // Ref http://mrhaki.blogspot.ca/2009/11/groovy-goodness-passing-closures-to.html
  stage(stage_name) {
    stage_closure()
  }
}

def setup_db(db_name) {
  optional_stage('Setup db') {
    reset_and_migrate_db(db_name)
  }
}

def reset_and_migrate_db(db_name) {
  timeout(10) { // minutes
    bat "rake resetdb[\"$db_name\"] migrateschema"
  }
}

def lock_schema_migrations() {
  withCredentials([usernamePassword(credentialsId: 'github-ci', passwordVariable: 'P', usernameVariable: 'U')]) {
    withEnv(["ENV_USER=${U}", "ENV_PASS=${P}"]) {
      powershell "Scripts\\Jenkins\\develop_cleanup\\lock_schema_migrations.ps1 -branch ${env.BRANCH_NAME}"

      // Suppressing config file cleanup for now.
      // Config file cleanup happens frequently, but that creates a new commit, which kicks off another Jenkins run,
      // sapping pipeline resources.
      // powershell "Scripts\\Jenkins\\develop_cleanup\\remove_old_jenkins_config_files.ps1 -branch ${env.BRANCH_NAME}"
    }
  }
}

def full_build_and_unit_test() {
  build_back_end()
  test_back_end()
  build_front_end()
  test_front_end()
}

def build_back_end() {
  optional_stage('Compile back end') {
    bat 'rake migrateschemacheck base'
  }
}

def test_back_end() {
  optional_stage('NUnit') {
    run_nunit(PIPELINE_CONFIG['nunit_filter'])
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

def run_nunit(nunit_filter) {
  try {
    bat "rake runtests[\"$nunit_filter\"]"
  }
  finally {
    nunit testResultsPattern: 'nunit-result.xml'
  }
}

def ui_testing(args_map) {
  echo "Got args: ${args_map}"
  stage('Run Selenium test') {
    configure_iis_and_start_site()
    bat 'rake compileqaattributedecorator compileqauitesting'
    reset_and_migrate_db(args_map.db_name)  // Required, as earlier stages may destroy data.
    selenium_args = [
      branch_name: env.BRANCH_NAME,
      selenium_filter: PIPELINE_CONFIG['selenium_filter'],
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
//   * selenium_filter: string (from PIPELINE_CONFIG)
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
//   * selenium_filter: string (from PIPELINE_CONFIG)
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
  timeout(120) {  // minutes
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
