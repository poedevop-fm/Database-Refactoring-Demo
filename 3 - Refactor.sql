--   Demo of incremental table change
--   Change Initial table schema and contents
--
--   TODO: add some more refactorings
--
ALTER DATABASE Demo1 SET RECURSIVE_TRIGGERS OFF;
GO
USE Demo1;
GO
--
--   Goal: Replace Name with two columns: Name1 and Name2
--         Replace ZIP with Postal1, Postal2
--         Add BillingCountry and BillingCountryCode columns.
--
--  Step 1: Expand.
--
--  Using "Refactoring Databases", page 126, "Replace Column",
--  first introduce new columns.
--  defaults allowed only so that triggers can recognize what needs to be updated.
--  Default constraints are named so that we can drop them later.
--  Warning: Adding NOT NULL (with default) columns can be time consuming!
--           (1 million rows on laptop took 17 seconds, 2 million took 28 seconds)
--
--   Add new columns
ALTER TABLE Customer  ADD
   Name1              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name1          DEFAULT '',
   Name2              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name2          DEFAULT '',
   BillingPostal1     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal1 DEFAULT '',
   BillingPostal2     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal2 DEFAULT '',
   BillingCountry     nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingCountry DEFAULT '',
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   BillingCountryCode nchar(2)     NOT NULL  
       CONSTRAINT DF_Customer_BillingCountryCode DEFAULT 'us'; -- ISO 3166
GO
--
--  Add DEFAULT constraint
--  so that INSERTing new rows using only the new columns will not fail.
--
ALTER TABLE Customer ADD CONSTRAINT DF_Customer_Name DEFAULT '' FOR Name;
GO
SELECT * FROM Customer;
GO
--
--   Step 2: create triggers to keep everything in sync.
IF OBJECT_ID ('SynchronizeCustomerAddress','TR') IS NOT NULL
   DROP TRIGGER SynchronizeCustomerAddress;
GO
CREATE TRIGGER SynchronizeCustomerAddress ON Customer FOR INSERT, UPDATE
AS
BEGIN
   --SET NOCOUNT ON;    -- Normally present.
   --  The next 3 lines are needed only if database option RECURSIVE_TRIGGERS is ON
   DECLARE @cnt int = (SELECT COUNT(*) FROM inserted);
   IF @cnt > 0 
   BEGIN;
   --
   IF UPDATE(Name) OR UPDATE(Name1)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET Name1 = inserted.Name
      FROM inserted LEFT OUTER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE Customer.CustomerId = inserted.CustomerId
        AND inserted.Name <> ISNULL(deleted.Name,'')
        AND inserted.Name1 <> inserted.Name;
      -- new columns updated: update old columns
      UPDATE Customer
         SET Name = inserted.Name1
      FROM inserted LEFT OUTER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE Customer.CustomerId = inserted.CustomerId
        AND inserted.Name1 <> ISNULL(deleted.Name1,'')
        AND inserted.Name1 <> inserted.Name;
   END;

   IF UPDATE(BillingZIP) OR UPDATE(BillingPostal2)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET BillingPostal2 = 
         CASE WHEN inserted.BillingZIP IS NULL THEN ''
              WHEN SUBSTRING(inserted.BillingZIP,6,4) > '' THEN SUBSTRING(inserted.BillingZIP,1,5) + '-' + SUBSTRING(inserted.BillingZIP,6,4)
              ELSE inserted.BillingZIP END
      FROM inserted LEFT OUTER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE Customer.CustomerId = inserted.CustomerId
        AND inserted.BillingZIP <> ISNULL(deleted.BillingZIP, '')
        AND inserted.BillingPostal2 <>
              CASE WHEN inserted.BillingZIP IS NULL THEN ''
                   WHEN LEN(inserted.BillingZIP) > 5 AND SUBSTRING(inserted.BillingZIP,6,4) > '' THEN SUBSTRING(inserted.BillingZIP,1,5) + '-' + SUBSTRING(inserted.BillingZIP,6,4)
                   ELSE inserted.BillingZIP END
        AND inserted.BillingZIP >= '0';
      -- new columns updated: update old columns
      UPDATE Customer
         SET BillingZIP = SUBSTRING(inserted.BillingPostal2,1,5) + SUBSTRING(inserted.BillingPostal2,7,4)
      FROM inserted LEFT OUTER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE Customer.CustomerId = inserted.CustomerId
        AND inserted.BillingPostal2 <> ISNULL(deleted.BillingPostal2, '')
        AND inserted.BillingCountryCode = 'us'
        AND ISNULL(inserted.BillingZIP,'') <> 
            SUBSTRING(inserted.BillingPostal2,1,5) + SUBSTRING(inserted.BillingPostal2,7,4);
   END;
   END;
END;
GO
--
--   Step 3: Convert. That is, add data to new columns
--   WHERE clauses cover case where updates occur before conversion finishes
--
UPDATE Customer
  SET Name1 = Name
WHERE Name1 = '' AND Name <> '';
--
UPDATE Customer  
  SET BillingPostal2 = CASE WHEN SUBSTRING(BillingZIP,6,4) <= '' THEN BillingZIP
                            ELSE SUBSTRING(BillingZIP,1,5) + '-' + SUBSTRING(BillingZIP,6,4)
                       END
WHERE BillingPostal2 = ''  AND BillingZIP > '';
GO
SELECT * FROM Customer;
GO
--   Step 4: notify everyone of changes coming: old columns will be deleted
--   Step 5: Migrate: developers / DBAs change programs and stored procedures
--
--   Add a customer using old columns
--
INSERT INTO Customer
(Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
VALUES
('Santa Claus','325 S. Santa Claus Lane','','North Pole', 'AK','99705');
GO
SELECT * FROM Customer;
GO
--
--  Add a customer using new columns
--
INSERT INTO Customer
(Name1,BillingAddress1,BillingAddress2, BillingCity, BillingState,BillingPostal2)
VALUES
('Bullwinke J. Moose', '1 Veronica Lake', '', 'Frostbite Falls','MN','56649-1111');
GO
INSERT INTO Customer
(Name1,Name2,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingPostal2,BillingCountry,BillingCountryCode)
VALUES
('Dudley Doright','RCMP', '1 Headquarters Road','','Toronto','ON','M3C 0C1','CANADA','ca');
GO
SELECT * FROM Customer;
GO
--
--  Update using old columns
--            (Old value of Address1 was "456 Second Street" - trigger does nothing)
--            (Old ZIP was 22222)
--
UPDATE Customer
   SET BillingAddress1 = '2 Second Street'
WHERE Name = 'BigBusiness';
GO
UPDATE Customer
   SET BillingZIP = '222223333'
WHERE Name = 'Dr. John H. Watson';
GO
--
SELECT * FROM Customer;
GO
--
--   Update using new columns
--                  (Old address was '1 Veronica Lake' - trigger does nothing)
--                  (Old PostalCode2 was 12345)
--
UPDATE Customer
   SET BillingAddress1 = '222 Veronica Lake'
WHERE Name1 = 'Bullwinke J. Moose';
GO
--
UPDATE Customer
   SET BillingPostal2 = '12345-9876'
WHERE Name1 = 'Fidgett, Panneck, and Runn';
GO
SELECT * FROM Customer;
GO
--
--   Step 6: Drop trigger, old columns, and defaults
--
DROP TRIGGER SynchronizeCustomerAddress;
GO
ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Name;
GO
ALTER TABLE Customer  DROP COLUMN Name, BillingZIP;
GO
--
--          Now remove the default for the new column (page 189)
--
SELECT CustomerID, Name1
FROM Customer 
WHERE Name1 < '!';
GO
ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Name1;
GO
SELECT * FROM Customer;
GO
--
--
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