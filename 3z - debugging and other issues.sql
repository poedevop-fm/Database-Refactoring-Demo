--
--   Other notes
--
--
-------------------------------------------------------------------------------
-- Making a column longer is always allowed. Making it shorter requires you to
-- DROP STATISTICS for that column. Also there are problems if the column is
-- indexed.
--SELECT MAX(LEN(Address1)) FROM dbo.Customer
--GO
DBCC SHOW_STATISTICS (Customer, Address1);
GO
DBCC SHOW_STATISTICS ("dbo.Customer", Address1);  -- dot apparently must be enclosed in double quotes
GO
--If an automatically created statistic does not exist for a column target, error message 2767 is returned. 
--
--DROP STATISTICS dbo.Customer.statisticsName
--
IF OBJECT_ID('ChangeLog','U') IS NOT NULL DROP TABLE ChangeLog;
CREATE TABLE ChangeLog (
   Changed  DATETIME2 NOT NULL DEFAULT(CURRENT_TIMESTAMP),
   CustomerId int NOT NULL,
   ins_Name      varchar(30) NOT NULL,
   ins_BillingAddress1  varchar(30) NOT NULL,
   ins_BillingAddress2  varchar(30) NOT NULL,
   ins_BillingCity      varchar(30) NOT NULL,
   ins_BillingState     char(2) NOT NULL,
   ins_BillingZIP       char(9),
   ins_Name1              nvarchar(64),
   ins_Name2              nvarchar(64),
   ins_BillingAddress1_a  nvarchar(64),
   ins_BillingAddress2_a  nvarchar(64),
   ins_BillingCity_a      nvarchar(50),
   ins_BillingPostal1     nvarchar(11),
   ins_BillingPostal2     nvarchar(11),
   ins_BillingCountry     nvarchar(64),
   ins_BillingCountryCode nchar(2),
   del_Name             varchar(30) NOT NULL,
   del_BillingAddress1  varchar(30) NOT NULL,
   del_BillingAddress2  varchar(30) NOT NULL,
   del_BillingCity      varchar(30) NOT NULL,
   del_BillingState     char(2) NOT NULL,
   del_BillingZIP       char(9),
   del_Name1              nvarchar(64),
   del_Name2              nvarchar(64),
   del_BillingAddress1_a  nvarchar(64),
   del_BillingAddress2_a  nvarchar(64),
   del_BillingCity_a      nvarchar(50),
   del_BillingPostal1     nvarchar(11),
   del_BillingPostal2     nvarchar(11),
   del_BillingCountry     nvarchar(64),
   del_BillingCountryCode nchar(2),
  CONSTRAINT PK_ChangeLog 
    PRIMARY KEY (Changed, CustomerID)
);
GO
--
--   Debugging aids
--
IF OBJECT_ID ('Debug11','TR') IS NOT NULL
      DROP TRIGGER Debug11;
GO
CREATE TRIGGER Debug11 ON Customer FOR INSERT, UPDATE
AS BEGIN
  INSERT INTO ChangeLog
  (CustomerId, 
   ins_Name, ins_BillingAddress1, ins_BillingAddress2, ins_BillingCity, ins_BillingState,
   ins_BillingZIP, 
   ins_Name1, ins_Name2, ins_BillingAddress1_a, ins_BillingAddress2_a,
   ins_BillingCity_a, ins_BillingPostal1, ins_BillingPostal2, ins_BillingCountry, ins_BillingCountryCode,
   del_Name, del_BillingAddress1, del_BillingAddress2, del_BillingCity, del_BillingState,
   del_BillingZIP,
   del_Name1, del_Name2, del_BillingAddress1_a, del_BillingAddress2_a,
   del_BillingCity_a, del_BillingPostal1, del_BillingPostal2, del_BillingCountry, del_BillingCountryCode)
  SELECT i.CustomerId, 
         i.Name, i.BillingAddress1, i.BillingAddress2, i.BillingCity,
         i.BillingState, i.BillingZIP,
         i.Name1, i.Name2, i.BillingAddress1_a, i.BillingAddress2_a, i.BillingCity_a,
         i.BillingPostal1, i.BillingPostal2, i.BillingCountry, i.BillingCountryCode,
         d.Name, d.BillingAddress1, d.BillingAddress2, d.BillingCity,
         d.BillingState, d.BillingZIP,
         d.Name1, d.Name2, d.BillingAddress1_a, d.BillingAddress2_a, d.BillingCity_a,
         d.BillingPostal1,d.BillingPostal2,d.BillingCountry,d.BillingCountryCode
  FROM inserted i LEFT OUTER JOIN deleted d ON i.CustomerId = d.CustomerId;
END;
GO
SELECT * FROM ChangeLog;
SELECT CustomerID, ins_Name, ins_Name1
FROM ChangeLog
--WHERE ins_Name <> del_Name
--  AND ins_Name1 <> ins_Name;
WHERE ins_Name1 <> del_Name1
  AND ins_Name1 <> ins_Name;

SELECT * FROM ChangeLog;
SELECT CustomerID, ins_BillingZIP, ins_BillingPostal2, del_BillingZIP, del_BillingPostal2,
SUBSTRING(ins_BillingZIP,1,5) + SUBSTRING(ins_BillingZIP,6,4) AS Expr1
FROM ChangeLog
--WHERE ins_BillingZIP <> del_BillingZIP 
--        AND ins_BillingPostal2 <>
--            SUBSTRING(ins_BillingZIP,1,5) + '-' + SUBSTRING(ins_BillingZIP,6,4);
      WHERE ins_BillingPostal2 <> del_BillingPostal2
        AND ins_BillingCountryCode = 'us'
        AND ins_BillingPostal2 <> 
            SUBSTRING(ins_BillingZIP,1,5) + SUBSTRING(ins_BillingZIP,7,4);
--
--
--   Lessons learned:
--   1. Automated unit tests is a good idea: you back up and start all over a lot
--      You need to cover all cases: INSERT/UPDATE; old/new.
--   2. Because of lesson #1, version control is probably a good idea
--   3. Changelog table was a good debugging tool
--   4. Need "WHERE Customer.CustomerId = inserted.CustomerId" clause to keep from
--      from changing every row.  Tests probably need to verify all rows.
--   5. LEFT OUTER JOIN needed, so ISNULL(deleted.column,...) needed in WHERE clauses.
--      Both needed to handle INSERT situation.
--   6. An UPDATE that changes no rows still invokes the trigger. Without an IF at the
--      top, the trigger will go into infinite recursion.  Alternatively, setting the
--      database "ALTER DATABASE Demo1 SET RECURSIVE_TRIGGERS OFF" also works.  (OFF
--      is the default setting.)
