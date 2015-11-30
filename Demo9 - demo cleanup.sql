--   Demo of incremental table change
--   9. Cleanup
--
USE master;
GO
DROP DATABASE Demo1;
GO
!! del C:\SQLServerData\MSSQL11.MSSQLSERVER\MSSQL\DATA\Demo1_log.ldf
!! del C:\SQLServerData\MSSQL11.MSSQLSERVER\MSSQL\DATA\Demo1.mdf
