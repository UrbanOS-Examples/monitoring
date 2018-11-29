library(
    identifier: 'pipeline-lib@4.3.0',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

properties([
    pipelineTriggers([scos.dailyBuildTrigger()]),
])

def doStageIf = scos.&doStageIf
def doStageIfRelease = doStageIf.curry(scos.changeset.isRelease)
def doStageUnlessRelease = doStageIf.curry(!scos.changeset.isRelease && !scos.changeset.isHotfix)
def doStageIfPromoted = doStageIf.curry(scos.changeset.isMaster)
def doStageIfHotfix = doStageIf.curry(scos.changeset.isHotfix)

node('infrastructure') {
    ansiColor('xterm') {

        scos.doCheckoutStage()

        doStageUnlessRelease('Deploy to Dev') {
            deployMonitoringTo('dev')
        }

         doStageIfPromoted('Deploy to Staging') {
            def promotionTag = scos.releaseCandidateNumber()

            deployMonitoringTo('staging')

            scos.applyAndPushGitHubTag(promotionTag)
        }

        doStageIfRelease('Deploy to Production') {
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            deployMonitoringTo('prod')

            scos.applyAndPushGitHubTag(promotionTag)
        }
    }
}

def deployMonitoringTo(environment) {
    def terraform = scos.terraform(environment)
    sh "terraform init && terraform workspace new ${environment}"
    terraform.plan(terraform.defaultVarFile)
    terraform.apply()
}
