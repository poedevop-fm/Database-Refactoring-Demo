--   Demo of incremental table change
--   Change Initial table schema and contents
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
