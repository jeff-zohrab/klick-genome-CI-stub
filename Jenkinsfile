// HACK COPIED JENKINSFILE //
// HACK COPIED JENKINSFILE //
// HACK COPIED JENKINSFILE //
// Sensei build Jenkins pipeline.

import org.jenkinsci.plugins.workflow.steps.FlowInterruptedException

// Shared libraries.
// Configured in https://ci.senseilabs.com/configure.
// Ref https://jenkins.io/doc/book/pipeline/shared-libraries/
@Library('WIP') _   // Shared library in Jenkins.


node('sensei_build') {

  // Users can tailor parts of pipeline using config files
  // See Jenkins/README.md.
  def pipeline_config

  // Slack channel to report to (specified in Jenkins config file)
  def slack_channel = ''

  // Users can 'skip' some stages using the Jenkins config file.
  def should_execute = {
    if (pipeline_config['skip'].contains(it.toLowerCase())) {
      echo "Skipping ${it}"
      return false
    }
    return true
  }

  // Each Jenkins node/executor gets its own DB.
  // db_name must start with "intranet_jnk_" (see UnitTests/DatabaseTestBase.cs)
  def db_name = "intranet_jnk_${env.NODE_NAME}_${env.EXECUTOR_NUMBER}"

  // Some stages destroy db data, so note if a reset is required for
  // subsequent stages.
  def db_reset_required = false

  // Shared library instance.
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

        args = [
	  'workspace_dir': env.WORKSPACE,
	  'branch_name': env.BRANCH_NAME
        ]
        githelper.checkout_from_reference_repo(args)
        pipeline_config = genome.get_pipeline_config(env.BRANCH_NAME)
        slack_channel = pipeline_config['slack_channel']
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

      stage('Setup db') {
        if (should_execute('Setup db')) {
          timeout(10) { // minutes
            bat "rake resetdb[\"$db_name\"] migrateschema"
          }
        }
      }

      stage('Compile back end') {
        if (should_execute('Compile back end')) {
          bat 'rake migrateschemacheck base'
        }
      }

      stage('NUnit') {
        if (should_execute('NUnit')) {
          run_nunit(pipeline_config['nunit_filter'])
          db_reset_required = true
        }
      }

      stage('Compile client') {
        if (should_execute('Compile client')) {
          bat 'rake compileClient'
        }
      }

      stage('Npm test') {
        if (should_execute('Npm test')) {
	  // TODO - reactivate
          // bat 'npm test -- --single-run'
        }
      }

      if (pipeline_config.containsKey('selenium_filter')) {
        stage('Run Selenium test') {
          genome.configure_iis_and_start_site()
          bat 'rake compileqaattributedecorator compileqauitesting'
          if (db_reset_required) {
            bat 'rake resetmydb migrateschema'
          }
          timeout(120) {  // minutes
            run_selenium(pipeline_config)
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
