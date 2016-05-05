--
--   Setup for testing triggers for split table refactoring
--   Shipping Address, Billing Address, and Customer
--
USE Demo1;
GO
--
--   Drop existing tables and constraints
--
IF OBJECT_ID('FK_ShippingAddress_Customer', 'F') IS NOT NULL
    ALTER TABLE ShippingAddress DROP CONSTRAINT FK_ShippingAddress_Customer;
GO
IF OBJECT_ID('DF_ShippingAddress_Country', 'D') IS NOT NULL
    ALTER TABLE ShippingAddress DROP CONSTRAINT DF_ShippingAddress_Country;
IF OBJECT_ID('DF_ShippingAddress_CountryCode', 'D') IS NOT NULL
    ALTER TABLE ShippingAddress DROP CONSTRAINT DF_ShippingAddress_CountryCode;
IF OBJECT_ID('DF_ShippingAddress_Postal1', 'D') IS NOT NULL
    ALTER TABLE ShippingAddress DROP CONSTRAINT DF_ShippingAddress_Postal1;
IF OBJECT_ID('DF_ShippingAddress_Postal2', 'D') IS NOT NULL
    ALTER TABLE ShippingAddress DROP CONSTRAINT DF_ShippingAddress_Postal2;
--
IF OBJECT_ID('ShippingAddress','U') IS NOT NULL 
   DROP TABLE ShippingAddress;
GO
--
IF OBJECT_ID('DF_BillingAddress_Country', 'D') IS NOT NULL
    ALTER TABLE BillingAddress DROP CONSTRAINT DF_BillingAddress_Country;
IF OBJECT_ID('DF_BillingAddress_CountryCode', 'D') IS NOT NULL
    ALTER TABLE BillingAddress DROP CONSTRAINT DF_BillingAddress_CountryCode;
IF OBJECT_ID('DF_BillingAddress_Postal1', 'D') IS NOT NULL
    ALTER TABLE BillingAddress DROP CONSTRAINT DF_BillingAddress_Postal1;
IF OBJECT_ID('DF_BillingAddress_Postal2', 'D') IS NOT NULL
    ALTER TABLE BillingAddress DROP CONSTRAINT DF_BillingAddress_Postal2;
GO
--
IF OBJECT_ID('BillingAddress','U') IS NOT NULL 
   DROP TABLE BillingAddress;
GO
--
IF OBJECT_ID('DF_Customer_BillingCountry', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingCountry;
IF OBJECT_ID('DF_Customer_BillingCountryCode', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingCountryCode;
IF OBJECT_ID('DF_Customer_BillingPostal1', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingPostal1;
IF OBJECT_ID('DF_Customer_BillingPostal2', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_BillingPostal2;
IF OBJECT_ID('DF_Customer_Name1', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Name1;
IF OBJECT_ID('DF_Customer_Name2', 'D') IS NOT NULL
    ALTER TABLE Customer DROP CONSTRAINT DF_Customer_Name2;
GO
--
IF OBJECT_ID('Customer','U') IS NOT NULL 
   DROP TABLE Customer;
GO
--
--   Create table
--
CREATE TABLE Customer
(
   CustomerId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   Name1            nvarchar(64) NOT NULL,
   Name2            nvarchar(64) NOT NULL,
   BillingAddress1  nvarchar(64) NOT NULL,
   BillingAddress2  nvarchar(64) NOT NULL,
   BillingCity      nvarchar(64) NOT NULL,
   BillingState     char(2)      NOT NULL,
   BillingPostal1   nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal1 DEFAULT '',
   BillingPostal2   nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal2 DEFAULT '',
   BillingCountry   nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingCountry DEFAULT '',
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   BillingCountryCode nchar(2)     NOT NULL  
       CONSTRAINT DF_Customer_BillingCountryCode DEFAULT 'us' -- ISO 3166
);
GO
--
CREATE TABLE BillingAddress
(
   BillingAddressID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   CustomerId       int NOT NULL,
   Address1  nvarchar(64) NOT NULL,
   Address2  nvarchar(64) NOT NULL,
   City      nvarchar(64) NOT NULL,
   [State]   char(2)      NOT NULL,
   Postal1   nvarchar(11) NOT NULL CONSTRAINT DF_BillingAddress_Postal1 DEFAULT '',
   Postal2   nvarchar(11) NOT NULL CONSTRAINT DF_BillingAddress_Postal2 DEFAULT '',
   Country   nvarchar(64) NOT NULL CONSTRAINT DF_BillingAddress_Country DEFAULT '',
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   CountryCode nchar(2)     NOT NULL  
                                   CONSTRAINT DF_BillingAddress_CountryCode DEFAULT 'us', -- ISO 3166
 CONSTRAINT FK_BillingAddress_Customer 
   FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
   ON DELETE CASCADE  -- Can't be used for logical records, but that feature is going away
);
GO
--
CREATE TABLE ShippingAddress
(
   ShippingAddressInternalId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   ShippingAddressID nvarchar(20) NOT NULL,
   CustomerID  int         NULL,
   Address1  nvarchar(64)  NOT NULL,
   Address2  nvarchar(64)  NOT NULL,
   City      nvarchar(64)  NOT NULL,
   [State]   char(2)       NOT NULL,
   Postal1   nvarchar(11)  NOT NULL CONSTRAINT DF_ShippingAddress_Postal1 DEFAULT '',
   Postal2   nvarchar(11)  NOT NULL CONSTRAINT DF_ShippingAddress_Postal2 DEFAULT '',
   Country   nvarchar(64)  NOT NULL CONSTRAINT DF_ShippingAddress_Country DEFAULT '',
                          -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   CountryCode nchar(2)    NOT NULL  
                                    CONSTRAINT DF_ShippingAddress_CountryCode DEFAULT 'us', -- ISO 3166
   BillingAddressID  int   NULL,
 CONSTRAINT FK_ShippingAddress_Customer 
   FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
 CONSTRAINT FK_ShippingAddress_BillingAddress
   FOREIGN KEY (BillingAddressID) REFERENCES BillingAddress (BillingAddressID)
);
GO
--
--   Add sample data
--
INSERT INTO Customer
   (Name1,Name2,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingPostal1,BillingPostal2)
VALUES
   ('Fidgett, Panneck, and Runn', '', '123 Main Street','',       'Fairview',  'XX', '', '12345'),
   ('Dr. John H. Watson',         '', 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222'),
   ('Big Business',               '', '456 Second Street','',     'Metropolis','YY', '', '98765-4321');
GO
--
--
DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');
DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);
--
INSERT INTO ShippingAddress
(ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,BillingAddressID)
VALUES
 ('Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      @ba_fpr),
 ('Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      @ba_fpr),
 ('',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      @ba_jhw),
 ('Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', @ba_bb),
 ('Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', @ba_bb),
 ('Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      @ba_bb);
--
-- TODO: add trigger code here
--
--    Create trigger for Customer table
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
      WHERE del.CustomerId IS NULL;
      --
      -- TODO: add update logic to trigger
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
      FROM inserted LEFT OUTER JOIN deleted
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
        --AND does any of part of the new address differ from what's in BillingAddress?  (TODO: needed?)
      -- new columns updated: update old columns
      --UPDATE Customer
      --   SET Name = inserted.Name1
      --FROM inserted LEFT OUTER JOIN deleted
      --ON inserted.CustomerID = deleted.CustomerID
      --WHERE Customer.CustomerId = inserted.CustomerId
      --  AND inserted.Name1 <> ISNULL(deleted.Name1,'')
      --  AND inserted.Name1 <> inserted.Name;
   END;

   END;  -- of IF @cnt > 0
END;
GO
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
       WHERE ShippingAddress.CustomerID = ins.customerId;
    END; -- of IF row INSERTed
   END;  -- of IF @cnt > 0
END;
GO
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
--
--   Display results to verify conversion worked
--
SELECT c.*, ba.*
FROM BillingAddress ba
INNER JOIN Customer c
ON ba.CustomerId = c.CustomerId;
--
SELECT * FROM ShippingAddress;