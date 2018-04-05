function Restore-SqlDatabaseToAzure {
  <#
  .SYNOPSIS
  Restore a SQL database from backup file to physical files specified
  .DESCRIPTION
  Takes backup file name, database name, server name, logical files names, and physical file names as input and restores the database
  killing all open connections to the destination database if it exists.
  .EXAMPLE
  Restore-SqlDatabaseToAzure -restoredb 'boomi4' `
  -instance 'cncybook82\dev2017' `
  -backupfile 'c:\backup\boomi.bak' `
  -datapath 'c:\data\restoretest' `
  -logpath 'c:\log\restoretest'; 
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
    [string]$logpath
  )

  process {

  try
  {

    cls;

    <# Prompt user that all connections will be killed in the source database. Stop function if answer is not Y. #>
    Write-Host "Executing this function will kill all connections to database $restoredb on instance $instance.  Enter " -NoNewline
    Write-Host "Y " -ForegroundColor Red -NoNewline
    Write-Host "to continue: " -NoNewline
    $continue = Read-Host;

    if($continue -ne 'Y')
    {
        Write-Host "Function Restore-SqlDatabaseToAzure was stopped because of request from user.";
        return;
    }

    <# Build the physical file paths and names for the restore database #>
    $physdata = "$datapath\$restoredb.mdf";
    $physlog = "$logpath\$restoredb`_log.ldf";

    <# Initialize variables to build relocate file parameter #>
    $relocate = @();
    $count = 0;

    <# Confirm that the backup file exists.  If it doesn not, raise an error. #>
    $backupexists = Test-Path $backupfile -ErrorAction SilentlyContinue;

    if($backupexists -ne $True)
    {
        throw "Backup file $backupfile does not exist.  Please check the file path and name and retry.";
    }

    <# Build the RESTORE FILELISTONLY statement and execute it to return a list of logical and physical file names #>
    $filelistonly = "RESTORE FILELISTONLY FROM DISK = '$backupfile'";
    $filelist = Invoke-Sqlcmd -ServerInstance $instance -Database master -Query $filelistonly;

    <# Build the RelocateFile parameter #>
    foreach ($file in $filelist) {

    $relocateDataFile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')

    $relocateDataFile.LogicalFileName = $file.LogicalName

    if ($file.Type -eq 'D') {
                
            <# If there is more than one data file, append the file count to the end of the physical file name
                to prevent contention #>
            if($count -ge 1)
            {
                $relocateDataFile.PhysicalFileName = "$datapath\$restoredb`_$count.mdf";  
            }
            else
            {
                $relocateDataFile.PhysicalFileName = "$datapath\$restoredb.mdf"
            }

            $count += 1;

        }

    elseif($file.Type -eq 'S') 
        {
            $relocateDataFile.PhysicalFileName = "$datapath\$restoredb`_mod"
        }

    else {

        $relocateDataFile.PhysicalFileName = "$logpath\$restoredb.ldf"

        }

    $relocate += $relocateDataFile;

    }

    <# Check if the restore database exists.  If it does, kill all existing connections. #>
    $exists = Invoke-Sqlcmd -ServerInstance $instance -Database master -Query "SELECT 1 FROM sys.databases WHERE name = '$restoredb';";
    if($exists)
    {
        Invoke-Sqlcmd -ServerInstance $instance -Database master -Query "EXEC KillAllSpids @databasename = N'$restoredb';";
    }

        <# Prompt the user that the restore database will be overwritten.  Stop function if the answer is not yes. #>

        Write-Host "If database $restoredb exists on instance $instance, it will be overwitten.  Enter " -NoNewline
        Write-Host "Y " -ForegroundColor Red -NoNewline
        Write-Host "to continue: " -NoNewline
        $overwrite = Read-Host;

        <# Confirm that the data path and log path exist.  If either of them do not, raise an error. #>
        $dataexists = Test-Path $datapath -ErrorAction SilentlyContinue;
        if($dataexists -ne $True)
        {
            throw "Data file path $datapath does not exist.  Please check the file path and retry.";
        }

        $logexists = Test-Path $logpath -ErrorAction SilentlyContinue;
        if($logexists -ne $True)
        {
            throw "Log file path $logpath does not exist.  Please check the file path and retry.";
        }

        <# If all checks have passed and the user has opted to overwrite the restore database, restore the database. #>
        if($overwrite -eq 'Y')
        {
            Restore-SqlDatabase -ServerInstance $instance -Database $restoredb -BackupFile $backupfile -RelocateFile $relocate -ReplaceDatabase;
        }
        else
        {
            Write-Host "Function Restore-SqlDatabaseToAzure was stopped because of request from user." -ForegroundColor Magenta;
            return;
        }
    }
catch
{
    Write-Error $_;
}
}
}
