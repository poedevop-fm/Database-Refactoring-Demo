--   Demo of split table change
--
ALTER DATABASE Demo1 SET RECURSIVE_TRIGGERS OFF;
GO
USE Demo1;
GO
--
--   Goal: Ultimately, allow the creation of multiple Billing Addresses for
--         one customer.  This means moving Billing Address data out of the
--         Customer table and putting that data into its own table.  Make sure
--         links from shipping address to billing address are preserved.
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
  --SET XACT_ABORT, NOCOUNT ON;  -- Normally this would be on. NOCOUNT off for demo.
  SET XACT_ABORT ON;
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
   --SET XACT_ABORT, NOCOUNT ON;  -- Normally this would be on. NOCOUNT off for demo.
   SET XACT_ABORT ON;
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
  --SET XACT_ABORT, NOCOUNT ON;  -- Normally this would be on. NOCOUNT off for demo.
  SET XACT_ABORT ON;
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
   --SET XACT_ABORT, NOCOUNT ON;  -- Normally this would be on. NOCOUNT off for demo.
   SET XACT_ABORT ON;
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
--  Add a customer using new table
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
--
--  Update using old columns
--            (Old value of Address1 was "456 Second Street" - trigger does nothing)
--
UPDATE Customer
   SET BillingAddress1 = '2 Second Street'
WHERE Name1 = 'BigBusiness';
GO
SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
--
--  Update using new table
--
DECLARE @c_id int = (SELECT CustomerID FROM Customer WHERE Name1 = 'BigBusiness');
UPDATE BillingAddress
   SET Address1 = '3 Third Street'
WHERE CustomerId = @c_id;
GO
SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
--
--   DELETE from Customer
--
DELETE FROM Customer WHERE Name1 = 'Santa Claus';
GO
SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
--
--  DELETE using BillingAddress
--
DECLARE @moose_id int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Bullwinke J. Moose');

DELETE FROM BillingAddress
WHERE CustomerId = @moose_id;

DELETE FROM Customer WHERE CustomerId = @moose_id;
GO
SELECT * FROM Customer;
SELECT * FROM BillingAddress;
GO
--
--   Step 6: Drop trigger, old columns, and defaults
--
DROP TRIGGER SynchronizeCustomerAddress;
DROP TRIGGER SynchronizeBillingAddress;
DROP TRIGGER SynchronizeBillingAddressDelete;
DROP TRIGGER SynchronizeShippingAddress;
GO
--           Make the BillingAddressID NOT NULL
SELECT ShippingAddressID, CustomerID
FROM ShippingAddress 
WHERE BillingAddressID IS NULL;
GO
ALTER TABLE ShippingAddress
  ALTER COLUMN BillingAddressID int NOT NULL;
GO
--
ALTER TABLE ShippingAddress DROP CONSTRAINT FK_ShippingAddress_Customer;
GO
ALTER TABLE ShippingAddress DROP COLUMN CustomerID;
GO
ALTER TABLE Customer  DROP CONSTRAINT DF_Customer_BillingPostal1;
ALTER TABLE Customer  DROP CONSTRAINT DF_Customer_BillingPostal2;
ALTER TABLE Customer  DROP CONSTRAINT DF_Customer_BillingCountry;
ALTER TABLE Customer  DROP CONSTRAINT DF_Customer_BillingCountryCode;
ALTER TABLE Customer  DROP COLUMN BillingAddress1;
ALTER TABLE Customer  DROP COLUMN BillingAddress2;
ALTER TABLE Customer  DROP COLUMN BillingCity;
ALTER TABLE Customer  DROP COLUMN BillingState;
ALTER TABLE Customer  DROP COLUMN BillingPostal1;
ALTER TABLE Customer  DROP COLUMN BillingPostal2;
ALTER TABLE Customer  DROP COLUMN BillingCountry;
ALTER TABLE Customer  DROP COLUMN BillingCountryCode;
--
--   Step 7: Decide about ON DELETE CASCADE on foreign key from billing address
--           to customer.  Dropping the constraint, if appropriate, might
--           expose coding errors.
--
--   Step 8: Notify developers that they can now change business logic and
--           presentation to support multiple billing addresses.
--
