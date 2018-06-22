def causes = currentBuild.rawBuild.getCauses()
def specificCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)

def SCMCause = currentBuild.rawBuild.getCause(hudson.triggers.SCMTrigger$SCMTriggerCause)
def change_author = env.CHANGE_AUTHOR

if (specificCause) {
    println "Manual user"
    println specificCause.properties
}

if (change_author) {
    println change_author
}
if (SCMCause) {
    println SCMCause.properties
}
