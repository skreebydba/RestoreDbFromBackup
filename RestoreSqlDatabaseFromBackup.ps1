function Restore-SqlDatabaseToAzure {
  <#
  .SYNOPSIS
  Restore a SQL database from backup file to physical files specified
  .DESCRIPTION
  Takes backup file name, database name, server name, logical files names, and physical file names as input and restores the database
  killing all open connections to the destination database if it exists.
  .EXAMPLE
  Restore-SqlDatabaseToAzure -sourcedb 'boomi' `
  -restoredb 'boomi4' `
  -instance 'cncybook82\dev2017' `
  -backupfile 'c:\backup\boomi.bak' `
  -datapath 'c:\data\restoretest' `
  -logpath 'c:\log\restoretest'; 
  .PARAMETER sourcedb
  The database being restored.
  .PARAMETER restoredb
  The database name being restored.
  .PARAMETER instance
  The instance the database is being restored to.
  .PARAMETER  backupfile
  The backup file being restored.
  .PARAMETER datapath
  The file path for the database data file 
  .PARAMETER logpath
  The file path for the database log file
  #>
  [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
  param
  (
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What database is being restored?')]
    [Alias('source')]
    [ValidateLength(3,255)]
    [string]$sourcedb,

    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What database name do you want to restore?')]
    [Alias('restore')]
    [ValidateLength(3,255)]
    [string]$restoredb,
    
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What instance are you restoring to?')]
    [Alias('inst')]
    [ValidateLength(3,255)]
    [string]$instance,		

    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What backup file is being restored?')]
    [Alias('bkupfile')]
    [ValidateLength(3,255)]
    [string]$backupfile,		

    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What path will the data file be restored to?')]
    [Alias('data')]
    [ValidateLength(3,255)]
    [string]$datapath,		

    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True,
    HelpMessage='What path will the log file be restored to ?')]
    [Alias('log')]
    [ValidateLength(3,255)]
    [string]$logpath,		
    
    [string]$logname = 'errors.txt'
  )

  process {

    Write-Host "Executing this function will kill all connections to database $sourcedb on instance $instance.  Enter " -NoNewline
    Write-Host "Y " -ForegroundColor Red -NoNewline
    Write-Host "to continue: " -NoNewline
    $continue = Read-Host;

    if($continue -ne 'Y')
    {
        Write-Host "Function Restore-SqlDatabaseToAzure was stopped because of request from user." -ForegroundColor Magenta;
        return;
    }

    $physdata = "$datapath\$restoredb.mdf";
    $physlog = "$logpath\$restoredb`_log.ldf"
    $RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$sourcedb", $physdata)
    $RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("$sourcedb`_Log", $physlog)

    $exists = Invoke-Sqlcmd -ServerInstance $instance -Database master -Query "SELECT 1 FROM sys.databases WHERE name = '$restoredb';";
    if($exists)
    {
        Invoke-Sqlcmd -ServerInstance $instance -Database master -Query "EXEC KillAllSpids @databasename = N'$restoredb';";
    }

    Restore-SqlDatabase -ServerInstance $instance -Database $restoredb -BackupFile $backupfile -RelocateFile @($RelocateData,$RelocateLog) -ReplaceDatabase;
      }
    }
