Restore-SqlDatabaseToAzure -sourcedb 'boomi' `
-restoredb 'boomi' `
-instance 'cncybook82\dev2017' `
-backupfile 'c:\backup\boomi.bak' `
-datapath 'c:\data\restoretest' `
-logpath 'c:\log\restoretest'; 

