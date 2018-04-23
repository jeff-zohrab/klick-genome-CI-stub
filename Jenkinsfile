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


node('sensei_build') {

  // Slack channel to report to (specified in Jenkins config file)
  def slack_channel = ''

  // Each Jenkins node/executor gets its own DB.
  // db_name must start with "intranet_jnk_" (see UnitTests/DatabaseTestBase.cs)
  def db_name = "intranet_jnk_${env.NODE_NAME}_${env.EXECUTOR_NUMBER}"

  // Some stages destroy db data, so note if a reset is required for
  // subsequent stages.
  def db_reset_required = false

  // Shared library instances.
  def genome = new org.klick.Genome()
  def githelper = new org.klick.Git()

  // The GitHub plugin creates unusable directory names
  // (ref https://issues.jenkins-ci.org/browse/JENKINS-38706),
  // so hardcode the workspace we'll use, and create dirs as needed.
  genome.create_dir("c:\\www")
  ws("c:\\www\\genome") {

    try {
      stage('Checkout') {
        genome.stop_iis()
        cleanWs()
        checkout_args = [
          workspace_dir: env.WORKSPACE,
          branch_name: env.BRANCH_NAME,
          github_org: 'jeff-zohrab',
          repo_name: 'klick-genome-CI-stub',
          ref_repo_parent_dir: 'c:\\reference_repo',
          creds_id: 'github-ci'
        ]
        githelper.checkout_from_reference_repo(checkout_args)
        PIPELINE_CONFIG = genome.get_pipeline_config(env.BRANCH_NAME)
        slack_channel = PIPELINE_CONFIG['slack_channel']
      }

      stage('Config') {
        genome.create_web_config(db_name)
        writeFile file: 'site.cfg', text: "jenkins_${env.NODE_NAME}"
        writeFile file: 'theme.cfg', text: 'genome'
        bat 'rake jenkins:fix_configs generateManifest'
        bat 'rake nlog:use_config[NLog.config.Jenkins]'
        bat 'rake rakefile:validate'
        powershell 'Set-Timezone -Name "Eastern Standard Time"'
      }

      if (env.BRANCH_NAME == 'develop') {
        stage('Lock schema migrations') {
	  lock_schema_migrations()
        }
      }

      optional_stage('Setup db') {
        timeout(10) { // minutes
          bat "rake resetdb[\"$db_name\"] migrateschema"
        }
      }

      optional_stage('Compile back end') {
        bat 'rake migrateschemacheck base'
      }

      optional_stage('NUnit') {
        run_nunit(PIPELINE_CONFIG['nunit_filter'])
        db_reset_required = true
      }

      optional_stage('Compile client') {
        bat 'rake compileClient'
      }

      optional_stage('Npm test') {
        bat 'npm test -- --single-run'
      }

      if (PIPELINE_CONFIG.containsKey('selenium_filter')) {
        stage('Run Selenium test') {
          configure_iis_and_start_site()
          bat 'rake compileqaattributedecorator compileqauitesting'
          if (db_reset_required) {
            bat 'rake resetmydb migrateschema'
          }
          timeout(120) {  // minutes
            run_selenium(PIPELINE_CONFIG)
          }
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


// Users can skip steps.
// Ref http://mrhaki.blogspot.ca/2009/11/groovy-goodness-passing-closures-to.html
def optional_stage(stage_name, stage_closure) {
  if (PIPELINE_CONFIG['skip'].contains(stage_name.toLowerCase())) {
    echo "Skipping ${stage_name}"
    return
  }

  stage(stage_name) {
    stage_closure()
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

def run_nunit(nunit_filter) {
  try {
    bat "rake runtests[\"$nunit_filter\"]"
  }
  finally {
    nunit testResultsPattern: 'nunit-result.xml'
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

def run_selenium(pipeline_config) {
  def fail_if_selenium_fails = pipeline_config['fail_if_selenium_fails']
  def selenium_filter = pipeline_config['selenium_filter']
  def report_to_testrail = pipeline_config['report_to_testrail']
  def branch_name = env.BRANCH_NAME

  def genome = new org.klick.Genome()

  if (fail_if_selenium_fails == 'true') {
    genome.run_selenium_with_fail(selenium_filter, report_to_testrail, branch_name)
  }
  else {
    genome.run_selenium_no_fail(selenium_filter, report_to_testrail, branch_name)
  }
}
