-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Gill, Concurrency
-- Create date: 2018-04-04
-- Description:	Kill all processes running against the database name passed in
-- =============================================
ALTER PROCEDURE KillAllSpids 
	-- Add the parameters for the stored procedure here
	@databasename SYSNAME = N'boomi4'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @kill varchar(8000);

	SELECT @kill = '';  
	SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
	FROM sys.dm_exec_sessions
	WHERE database_id  = db_id(@databasename)

	EXEC(@kill);

END

GO
