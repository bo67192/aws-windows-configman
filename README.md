# dt-infra-citrix-management

## Citrix Management Scripts

These are powershell scripts deploy to the citrix controllers for managing DocuTAP user sessions

Located in ssm\windows-ctxcnt-man\util

* Production
  * hsctxwcnt001
  * hsctxwcnt002
* Staging
  * hsctxwcnt500
  * hsctxwnct501

All scripts will be deployed to `C:\docutap\util\citrix`

These scripts will log to standard out and `C:\docutap\logs\citrixman`

### Switch-SiteApps.ps1

* Parameters
  * -siteId - the siteID to enable
  * -enabled - true if the apps should be enabled, false if they should not be
  * -maxApps - the maximum number of applications to toggle. Default of 10
* Return
  * Returns $true if it was successful
  * Exits with a non-zero exit code and logs a message if it fails

### Stop-UserSessions.ps1

* Parameters
  * -siteId - the siteID to turn off user sessions
  * -gracePeriod - the amount of time in seconds to message users before forcing logoff
  * -maxUsersThreshold - maximum number of users to force logoff. If there are more sessions than this number, the script will exit with a non-zero return code
* Return
  * Returns $true if it was successful
  * Exits with a non-zero exit code and logs a message if it fails

### Set-SiteDTVersion.ps1

* Parameters
  * -siteId - the siteID to turn off user sessions
  * -maxApps - the maximum number of applications to update working directory, default of 10
* Return
  * Returns $true if it was successful
  * Exits with a non-zero exit code and logs a message if it fails

## Windows General Config

These are powershell functions for general windows management. These should support being run on any windows server in the docutap environment

Located in ssm\windows-general-man\util and ssm\windows-general-man\dsc

### DSC

* Installs chocolatey
  * Tests for chocolatey in C:\ProgramData\chocolatey\choco.exe

### Util

* CommonFunctions.psm1
  * `write-log`
    * A logging function for docutap powershell scripts
    * Prints logs in json format to `$global:logDir` (this can be changed by calling `set-logdir <new_log_dir>`)
    * Parameters
      * `-message` the human readable log message to output
      * `-level` the severity of the log message being printed
        * INFO
        * ERROR
        * WARN
        * DEBUG
      * `-category` the log message category, gives a way to group log message together
        * app
        * cosmos
        * windows
        * citrix
      * `-item` the specific config item being changed
        * hostname
        * app
        * version
  * `Test-LastDSCSResult`
    * Tests the most recently applied DSC config. We need this because we apply multiple MOF files, and each one overwrites the most recent results
    * Logs the name of the most recent DSC, the result, and the number of configurations applied
  * `Invoke-SQL`
    * A Function to invoke SQL queries, typically against the data mart
    * Returns the data set retrieved as a powershell object
    * Parameters
      * `-dataSource` the server name to query, e.g. "bipfwcsql001.docutap.local" 
      * `-database` the database name to query, e.g. "SFDataMart"
      * `-sqlCommand` the sql query to run. This is required
      * `-user` the sql server username, e.g. "SSM_RO"
      * `-plaintextpwd` the plain text password. This is converted to a secure string
