--   Demo of split table change
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
--  Using "Refactoring Databases", page 145, "Split Table",
--
CREATE TABLE BillingAddress
(
   BillingAddressID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   CustomerId       int NOT NULL,
   Address1  nvarchar(64) NOT NULL,
   Address2  nvarchar(64) NOT NULL,
   City      nvarchar(64) NOT NULL,
   State     char(2)      NOT NULL,
   Postal1   nvarchar(11) NOT NULL CONSTRAINT DF_BillingAddress_Postal1 DEFAULT '',
   Postal2   nvarchar(11) NOT NULL CONSTRAINT DF_BillingAddress_Postal2 DEFAULT '',
   Country   nvarchar(64) NOT NULL CONSTRAINT DF_BillingAddress_Country DEFAULT '',
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   CountryCode nchar(2)     NOT NULL  
       CONSTRAINT DF_BillingAddress_CountryCode DEFAULT 'us', -- ISO 3166
 CONSTRAINT FK_BillingAddress_Customer 
   FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
);
GO
--
--   Now add a column to the Shipping Address table
--
ALTER TABLE ShippingAddress
   ALTER COLUMN CustomerID int NULL;
ALTER TABLE ShippingAddress
   ADD BillingAddressID int NULL;
ALTER TABLE ShippingAddress
   ADD CONSTRAINT FK_ShippingAddress_BillingAddressID
   FOREIGN KEY (BillingAddressID) REFERENCES BillingAddress (BillingAddressID);
--
GO
--
--   Step 2: create triggers to keep everything in sync.
--
--    Create triggers for Customer table
--
IF OBJECT_ID ('SynchronizeCustomerAddress','TR') IS NOT NULL
   DROP TRIGGER SynchronizeCustomerAddress;
GO
CREATE TRIGGER SynchronizeCustomerAddress ON Customer FOR INSERT, UPDATE
AS
BEGIN
  --  The next 3 lines are needed only if database option RECURSIVE_TRIGGERS is ON
   DECLARE @cnt int = (SELECT COUNT(*) FROM inserted);
   IF @cnt > 0 
   BEGIN;
   IF UPDATE(BillingAddress1) OR 
      UPDATE(BillingAddress1) OR
      UPDATE(BillingAddress2) OR
      UPDATE(BillingCity)     OR
      UPDATE(BillingState)    OR
      UPDATE(BillingPostal1)  OR
      UPDATE(BillingPostal2)  OR
      UPDATE(BillingCountry)  OR
      UPDATE(BillingCountryCode)
   BEGIN;
      -- Check for INSERT
      --   If we add a customer via new columns, should NOT add an address
      --   if the address is empty.  This tripped me up.
      INSERT INTO BillingAddress
      (CustomerId, Address1, Address2, City,
       [State], Postal1, Postal2, Country,
       CountryCode)
      SELECT ins.CustomerId,   ins.BillingAddress1, ins.BillingAddress2, ins.BillingCity,
             ins.BillingState, ins.BillingPostal1,  ins.BillingPostal2,  ins.BillingCountry,
             ins.BillingCountryCode
      FROM inserted ins
      LEFT OUTER JOIN deleted del
      ON ins.CustomerId = del.CustomerId
      WHERE del.CustomerId IS NULL
        AND (ins.BillingAddress1 <> ''  OR
             ins.BillingAddress2 <> ''  OR
             ins.BillingCity <> ''      OR
             ins.BillingState <> ''     OR
             ins.BillingPostal1 <> ''   OR
             ins.BillingPostal2 <> ''   OR
             ins.BillingCountryCode <> 'us');
      --
      -- old columns updated: update new columns
      UPDATE BillingAddress
         SET Address1 = inserted.BillingAddress1,
             Address2 = inserted.BillingAddress2,
             City     = inserted.BillingCity,
             State    = inserted.BillingState,
             Postal1  = inserted.BillingPostal1,
             Postal2  = inserted.BillingPostal2,
             Country  = inserted.BillingCountry,
             CountryCode = inserted.BillingCountryCode
      FROM inserted INNER JOIN deleted
      ON inserted.CustomerID = deleted.CustomerID
      WHERE BillingAddress.CustomerId = inserted.CustomerId
        -- was any part of the address changed?
        AND (inserted.BillingAddress1 <> ISNULL(deleted.BillingAddress1,'') OR
             inserted.BillingAddress2 <> ISNULL(deleted.BillingAddress2,'') OR
             inserted.BillingCity     <> ISNULL(deleted.BillingCity,'')     OR
             inserted.BillingState    <> ISNULL(deleted.BillingState,'')    OR
             inserted.BillingPostal1  <> ISNULL(deleted.BillingPostal1,'')  OR
             inserted.BillingPostal2  <> ISNULL(deleted.BillingPostal2,'')  OR
             inserted.BillingCountry  <> ISNULL(deleted.BillingCountry,'')  OR
             inserted.BillingCountryCode <> ISNULL(deleted.BillingCountryCode,''));
   END;

   END;  -- of IF @cnt > 0
END;
GO
--
IF OBJECT_ID ('SynchronizeBillingAddress','TR') IS NOT NULL
   DROP TRIGGER SynchronizeBillingAddress;
GO
CREATE TRIGGER SynchronizeBillingAddress ON BillingAddress FOR INSERT, UPDATE
AS
BEGIN
  --  The next 3 lines are needed only if database option RECURSIVE_TRIGGERS is ON
   DECLARE @cnt int = (SELECT COUNT(*) FROM inserted);
   IF @cnt > 0 
   BEGIN;
   IF UPDATE(Address1) OR 
      UPDATE(Address1) OR
      UPDATE(Address2) OR
      UPDATE(City)     OR
      UPDATE(State)    OR
      UPDATE(Postal1)  OR
      UPDATE(Postal2)  OR
      UPDATE(Country)  OR
      UPDATE(CountryCode)
   BEGIN;
      -- [new] table updated: update corresponding [old] columns in Customer table
      UPDATE Customer
         SET BillingAddress1 = inserted.Address1,
             BillingAddress2 = inserted.Address2,
             BillingCity     = inserted.City,
             BillingState    = inserted.[State],
             BillingPostal1  = inserted.Postal1,
             BillingPostal2  = inserted.Postal2,
             BillingCountry  = inserted.Country,
             BillingCountryCode = inserted.CountryCode
      FROM inserted
      WHERE inserted.CustomerId = Customer.CustomerId 
        AND (inserted.Address1 <> BillingAddress1 OR
             inserted.Address2 <> BillingAddress2 OR
             inserted.City     <> BillingCity     OR
             inserted.[State]  <> BillingState    OR
             inserted.Postal1  <> BillingPostal1  OR
             inserted.Postal2  <> BillingPostal2  OR
             inserted.Country  <> BillingCountry  OR
             inserted.CountryCode <> BillingCountryCode);
   END;

   END;  -- of IF @cnt > 0
END;
GO
--
--
IF OBJECT_ID ('SynchronizeBillingAddressDelete','TR') IS NOT NULL
   DROP TRIGGER SynchronizeBillingAddressDelete;
GO
CREATE TRIGGER SynchronizeBillingAddressDelete ON BillingAddress FOR DELETE
AS
BEGIN
  --  The next 3 lines are needed only if database option RECURSIVE_TRIGGERS is ON
   DECLARE @cnt int = (SELECT COUNT(*) FROM deleted);
   IF @cnt > 0 
   BEGIN;
      -- [new] table updated: update corresponding [old] columns in Customer table
      UPDATE Customer
         SET BillingAddress1 = '',
             BillingAddress2 = '',
             BillingCity     = '',
             BillingState    = '',
             BillingPostal1  = '',
             BillingPostal2  = '',
             BillingCountry  = ''
      FROM deleted
      WHERE deleted.CustomerId = Customer.CustomerId;
   END;  -- of IF @cnt > 0
END;
GO
--
--
IF OBJECT_ID ('SynchronizeShippingAddress','TR') IS NOT NULL
   DROP TRIGGER SynchronizeShippingAddress;
GO
CREATE TRIGGER SynchronizeShippingAddress ON ShippingAddress FOR INSERT, UPDATE
AS
BEGIN
  --  The next 3 lines are needed only if database option RECURSIVE_TRIGGERS is ON
   DECLARE @cnt int = (SELECT COUNT(*) FROM inserted);
   IF @cnt > 0 
   BEGIN;
    IF UPDATE(CustomerID) 
    BEGIN;
       UPDATE ShippingAddress
          SET BillingAddressID = ba.BillingAddressID
       FROM inserted ins
       INNER JOIN BillingAddress ba
       ON ins.CustomerId = ba.CustomerId
       WHERE ShippingAddress.CustomerID = ins.customerId
         --  Clause below needed to avoid to avoid infinite recursion
         --  -1 is assumed to be a integer value that will never match
         AND ba.BillingAddressID <> COALESCE(ins.BillingAddressID, -1);
    END; -- of IF row INSERTed

    IF UPDATE(BillingAddressID) 
    BEGIN;
       UPDATE ShippingAddress
          SET CustomerID = ba.CustomerId
       FROM inserted ins
       INNER JOIN BillingAddress ba
       ON ins.BillingAddressID = ba.BillingAddressID
       WHERE ShippingAddress.BillingAddressID = ins.BillingAddressID 
         --  Clause below needed to avoid to avoid infinite recursion
         --  -1 is assumed to be a integer value that will never match
         AND ba.CustomerId <> COALESCE(ins.CustomerID, -1);
    END; -- of IF row INSERTed
   END;  -- of IF @cnt > 0
END;
GO
--
--    Add DEFAULT constraints so that columns going away won't block new code.
--
ALTER TABLE Customer 
   ADD CONSTRAINT DF_Customer_BillingAddress1 DEFAULT '' FOR BillingAddress1,
       CONSTRAINT DF_Customer_BillingAddress2 DEFAULT '' FOR BillingAddress2,
       CONSTRAINT DF_Customer_City            DEFAULT '' FOR BillingCity,
       CONSTRAINT DF_Customer_State           DEFAULT '' FOR BillingState;
--
--   Step 3: Convert. That is, add data to new columns
--   WHERE clauses cover case where updates occur before conversion finishes
--
--
--    Run conversion to make old and new tables contain the same data
--
INSERT INTO BillingAddress
(CustomerId, Address1, Address2, City, [State], Postal1, Postal2, Country, CountryCode)
SELECT CustomerId,   BillingAddress1, BillingAddress2, BillingCity,
       BillingState, BillingPostal1,  BillingPostal2,  BillingCountry,
       BillingCountryCode
FROM Customer;
GO
--
--   Run conversion to link shipping address to the new business address table
--   We assume that 1 billing address per customer will remain true while conversion occurs
--
UPDATE ShippingAddress
   SET BillingAddressID = ba.BillingAddressID
FROM BillingAddress ba
WHERE ShippingAddress.CustomerID = ba.CustomerId;
GO
--
--   Display results to verify conversion worked
--
SELECT c.*, ba.*
FROM BillingAddress ba
INNER JOIN Customer c
ON ba.CustomerId = c.CustomerId;
--
SELECT * FROM ShippingAddress;
GO
--
--   Step 4: notify everyone of changes coming: old columns will be deleted
--   Step 5: Migrate: developers / DBAs change programs and stored procedures
--
--   Add a customer using old columns
--
INSERT INTO Customer
(Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, BillingState, BillingPostal1, BillingPostal2)
VALUES
('Santa Claus', '', '325 S. Santa Claus Lane','','North Pole', 'AK', '', '99705');
GO
SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
--
--  Add a customer using new columns
--
DECLARE @output TABLE ( CustomerId  int NOT NULL );
--
INSERT INTO Customer (Name1,Name2)
   OUTPUT (inserted.CustomerId) INTO @output
  VALUES ('Bullwinke J. Moose', '');

DECLARE @id int = (SELECT TOP 1 CustomerId FROM @output);

INSERT INTO BillingAddress
(CustomerId, Address1, Address2, City, [State], Postal1, Postal2)
VALUES
(@id, '1 Veronica Lake','','Frostbite Falls', 'MN', '', '99705');
GO

SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
-- TODO: create sample UPDATE, and DELETE statements for 
--       for customer and billing address
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