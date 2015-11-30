--   Demo of incremental table change
--   Change Initial table schema and contents
--
-- USPS Publication 28 - Postal Addressing Standards
-- Section 2.1.1
-- http://pe.usps.gov/text/pub28/28c2_001.htm
-- minimum of 30. Optimal is 64.

-- attention line
-- company name
-- secondary address line
-- primary address line
-- city-state-zip
--
USE Demo1;
GO
--
--   Eventually we want this:
--CREATE TABLE Customer
--(
--   CustomerId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
--   Name1            nvarchar(64) NOT NULL,
--   Name2            nvarchar(64) NOT NULL,
--   BillingAddress1  nvarchar(64) NOT NULL,
--   BillingAddress2  nvarchar(64) NOT NULL,
--   BillingCity      nvarchar(50) NOT NULL,
--   BillingPostal1   nvarchar(11),
--   BillingPostal2   nvarchar(11),
--   BillingCountry   nvarchar(64),  -- 'United Kingdom of Great Britain and Northern Ireland' is 53
--   BillingCountryCode nchar(2) NOT NULL DEFAULT('us'); -- ISO 3166
--);
--GO
--
--  Step 1: Expand.
--  Using "Refactoring Databases", page 177, "Introduce Null Value"s
--  so that revised code can ignore old columns.
ALTER TABLE Customer  ALTER COLUMN Name             varchar(30) NOT NULL;
ALTER TABLE Customer  ALTER COLUMN BillingAddress1  varchar(30) NOT NULL;
ALTER TABLE Customer  ALTER COLUMN BillingAddress2  varchar(30) NOT NULL;
ALTER TABLE Customer  ALTER COLUMN BillingCity      varchar(30) NOT NULL;
ALTER TABLE Customer  ALTER COLUMN BillingState     char(2)     NOT NULL;
GO
--  Using "Refactoring Databases", page 126, "Replace Column",
--  first introduce new columns.
--  defaults allowed only so that triggers can recognize what needs to be updated.
--  Default constraints are named so that we can drop them later.
--
ALTER TABLE Customer  ADD
   Name1              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name1            DEFAULT(''),
   Name2              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name2            DEFAULT(''),
   BillingAddress1_a  nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingAddres1_a DEFAULT(''),
   BillingAddress2_a  nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingAddres2_a DEFAULT(''),
   BillingCity_a      nvarchar(50) NOT NULL CONSTRAINT DF_Customer_BillingCity_a    DEFAULT(''),
   BillingPostal1     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal1   DEFAULT(''),
   BillingPostal2     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal2   DEFAULT(''),
   BillingCountry     nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingCountry   DEFAULT(''),
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   BillingCountryCode nchar(2)     NOT NULL  
       CONSTRAINT DF_Customer_BillingCountryCode DEFAULT('us'); -- ISO 3166
GO
--
--   Step 2: notify everyone of changes coming: old columns will be deleted
--   Step 3: create triggers to keep everything in sync.
IF OBJECT_ID ('SynchronizeCustomerAddress','TR') IS NOT NULL
      DROP TRIGGER SynchronizeCustomerAddress;
GO
CREATE TRIGGER SynchronizeCustomerAddress ON Customer FOR INSERT, UPDATE
AS
BEGIN
   IF UPDATE(Name) OR UPDATE(Name1)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET Name1 = inserted.Name
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.Name <> deleted.Name
        AND inserted.Name1 <> inserted.Name;
      -- new columns updated: update old columns
      UPDATE Customer
         SET Name = inserted.Name1
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.Name1 <> deleted.Name1
        AND inserted.Name1 <> inserted.Name;
   END;

   IF UPDATE(BillingAddress1) OR UPDATE(BillingAddress1_a)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET BillingAddress1_a = inserted.BillingAddress1
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingAddress1 <> deleted.BillingAddress1
        AND inserted.BillingAddress1_a <> inserted.BillingAddress1;
      -- new columns updated: update old columns
      UPDATE Customer
         SET BillingAddress1 = inserted.BillingAddress1_a
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingAddress1_a <> deleted.BillingAddress1_a
        AND inserted.BillingAddress1_a <> inserted.BillingAddress1;
   END;
   
   IF UPDATE(BillingAddress2) OR UPDATE(BillingAddress2_a)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET BillingAddress2_a = inserted.BillingAddress2
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingAddress2 <> deleted.BillingAddress2
        AND inserted.BillingAddress2_a <> inserted.BillingAddress2;
      -- new columns updated: update old columns
      UPDATE Customer
         SET BillingAddress2 = inserted.BillingAddress2_a
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingAddress2_a <> deleted.BillingAddress2_a
        AND inserted.BillingAddress2_a <> inserted.BillingAddress2;
   END;
   
   IF UPDATE(BillingCity) OR UPDATE(BillingCity_a)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET BillingCity_a = inserted.BillingCity
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingCity <> deleted.BillingCity
        AND inserted.BillingCity_a <> inserted.BillingCity;
      -- new columns updated: update old columns
      UPDATE Customer
         SET BillingCity = inserted.BillingCity_a
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingCity_a <> deleted.BillingCity_a
        AND inserted.BillingCity_a <> inserted.BillingCity;
   END;
   
   IF UPDATE(BillingZIP) OR UPDATE(BillingPostal2)
   BEGIN;
      -- old columns updated: update new columns
      UPDATE Customer
         SET Postal2 = SUBSTRING(inserted.BillingZIP,1,5) + '-' + SUBSTRING(inserted.BillingZIP,6,4)
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.BillingZIP <> deleted.BillingZIP 
        AND inserted.Postal2 <>
            SUBSTRING(inserted.BillingZIP,1,5) + '-' + SUBSTRING(inserted.BillingZIP,6,4);
      -- new columns updated: update old columns
      UPDATE Customer
         SET BillingZIP = SUBSTRING(inserted.BillingZIP,1,5) + SUBSTRING(inserted.BillingZIP,7,4)
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE inserted.Postal2 <> deleted.Postal2
        AND inserted.BillingCountryCode = 'us'
        AND inserted.Postal2 <> 
            SUBSTRING(inserted.BillingZIP,1,5) + SUBSTRING(inserted.BillingZIP,7,4);
   END;
END;
GO
--
--   Convert: That is, add data to new fields
--   WHERE clauses cover case where updates occur before conversion finishes
--
UPDATE Customer  SET Name1 = Name                        WHERE Name1 = '' AND Name <> '';
UPDATE Customer  SET BillingAddress1_a = BillingAddress1 WHERE BillingAddress1_a = '' AND BillingAddress1 <> '';
UPDATE Customer  SET BillingAddress2_a = BillingAddress2 WHERE BillingAddress2_a = '' AND BillingAddress2 <> '';
UPDATE Customer  SET BillingCity_a     = BillingCity     WHERE BillingCity_a = '' AND BillingCity <> '';
UPDATE Customer  SET BillingPostal2    = BillingZIP
WHERE BillingPostal2 IS NULL
  AND BillingZIP     > '';
GO
--
--  Add a customer using old fields
--
SELECT * FROM Customer;
GO
INSERT INTO Customer
(Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
VALUES
('Santa Claus','325 S. Santa Claus Lane','North Pole', 'AK','99705');
GO
SELECT * FROM Customer;
GO
--
--  Add a customer using new fields
--
SELECT * FROM Customer;
GO
INSERT INTO Customer
(Name1,BillingAddress1_a,BillingCity_a,BillingState,BillingPostal2)
VALUES
('Bullwinke J. Moose', '1 Veronica Lake', 'Frostbite Falls','MN','56649-1111');
GO
INSERT INTO Customer
(Name1,Name2,BillingAddress1_a,BillingCity_a,BillingState,BillingPostal2,BillingCountry,BillingCountryCode)
VALUES
('Dudley Doright','RCMP', '1 Headquarters Road','Toronto','ON','M3C 0C1','CANADA','ca');
GO
SELECT * FROM Customer;
GO
--
--  Update using old fields
--
UPDATE Customer
   SET BillingAddress1 = '2 Second Street'
WHERE Name = 'BigBusiness';
GO
SELECT * FROM Customer;
GO
UPDATE Customer
   SET BillingAddress1_a = '222 Veronica Lake'
WHERE Name1 = 'Bullwinke J. Moose';
GO
SELECT * FROM Customer;
GO
--
--   Program conversion complete: drop trigger and old fields
--
DROP TRIGGER SynchronizeCustomerAddress;
GO
ALTER TABLE Customer DROP COLUMN Name, BillingAddress1, BillingAddress2, BillingCity, BillingZIP;
GO
--
--   Now remove the defaults (page 189)
--
SELECT CustomerID, Name1, BillingAddress1_a, BillingAddress2_a
FROM Customer 
WHERE Name1 < '!'
   OR BillingAddress1_a  < '!'
   OR BillingAddress2_a  < '!';
GO
ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Name1;
ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingAddress1_a;
ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingCity_a;
GO
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
