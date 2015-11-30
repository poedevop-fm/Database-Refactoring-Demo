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
--
--   Eventually we want this:
--CREATE TABLE Customer
--(
--   CustomerId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
--   Name1            nvarchar(64) NOT NULL,
--   Name2            nvarchar(64) NOT NULL,
--   BillingAddress1  nvarchar(64) NOT NULL,
--   BillingAddress2  nvarchar(64) NOT NULL,
--   BillingCity      nvarchar(64) NOT NULL,
--   BillingState     nchar(2) NULL,
--   BillingPostal1   nvarchar(11),
--   BillingPostal2   nvarchar(11),
--   BillingCountry   nvarchar(64),  -- 'United Kingdom of Great Britain and Northern Ireland' is 53
--   BillingCountryCode nchar(2) NOT NULL DEFAULT('us'); -- ISO 3166
--);
--GO
--
--  Step 1: Expand.
--  Per "Refactoring Databases", page 126, first introduce new columns
--
ALTER TABLE Customer 
   ADD Name1 nvarchar(64),
       Name2 nvarchar(64),
       BillingAddress1_a  nvarchar(64),
       BillingAddress2_a  nvarchar(64),
       BillingCity_a      nvarchar(64),
       BillingState_a     nchar(2),
       BillingPostal1     nvarchar(11),
       BillingPostal2     nvarchar(11),
       BillingCountry   nvarchar(64),  -- 'United Kingdom of Great Britain and Northern Ireland' is 53
       BillingCountryCode nchar(2) NOT NULL DEFAULT('us'); -- ISO 3166
GO
--
--   Step 2: notify everyone of changes coming: old columns will be deleted
--   Step 3: create triggers to keep everything in sync.
CREATE TRIGGER SynchronizeCustomerAddress ON Customer FOR INSERT, UPDATE
AS
(
   IF UPDATE(Name) OR UPDATE(Name1)
   BEGIN;
      UPDATE Customer
         SET Name1 = inserted.Name
      FROM inserted
      WHERE inserted.Name IS NOT NULL AND inserted.Name1 IS NULL;
      UPDATE Customer
         SET Name = inserted.Name1
      FROM inserted
      WHERE inserted.Name1 IS NOT NULL AND inserted.Name IS NULL;
   END;

   IF UPDATE(BillingAddress1) OR UPDATE(BillingAddress1_a)
   BEGIN;
      UPDATE Customer
         SET BillingAddress1_a = inserted.BillingAddress1
      FROM inserted
      WHERE inserted.BillingAddress1 IS NOT NULL AND inserted.BillingAddress1_a IS NULL;
      UPDATE Customer
         SET BillingAddress1 = inserted.BillingAddress1_a
      FROM inserted
      WHERE inserted.BillingAddress1_a IS NOT NULL AND inserted.BillingAddress1 IS NULL;
   END;
   
   IF UPDATE(BillingAddress2) OR UPDATE(BillingAddress2_a)
   BEGIN;
      UPDATE Customer
         SET BillingAddress2_a = inserted.BillingAddress2
      FROM inserted
      WHERE inserted.BillingAddress2 IS NOT NULL AND inserted.BillingAddress2_a IS NULL;
      UPDATE Customer
         SET BillingAddress2 = inserted.BillingAddress2_a
      FROM inserted
      WHERE inserted.BillingAddress2_a IS NOT NULL AND inserted.BillingAddress2 IS NULL;
   END;
   
   IF UPDATE(BillingCity) OR UPDATE(BillingCity_a)
   BEGIN;
      UPDATE Customer
         SET BillingCity_a = inserted.BillingCity
      FROM inserted
      WHERE inserted.BillingCity IS NOT NULL AND inserted.BillingCity_a IS NULL;
      UPDATE Customer
         SET BillingCity = inserted.BillingCity_a
      FROM inserted
      WHERE inserted.BillingCity_a IS NOT NULL AND inserted.BillingCity IS NULL;
   END;
   
   BillingState     char(2) NOT NULL,
   BillingZIP       char(9)

);
--
--     inserted.Name inserted.Name1
--         NULL           NULL         Do nothing
--         NOT NULL       NULL         Update name1 to name
--         NULL           NOT NULL     Update name  to name1
--         NOT NULL       NOT NULL     Do nothing: assume programmers knows what they're doing
--                                     Also, this terminate the recursion
--
--
--
GO
INSERT INTO Customer
(Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
VALUES
('Fidgett, Panneck, and Runn','123 Main Street','','Fairview','XX','12345'),
('Dr. John H. Watson','Apt. B','221 Baker Street','Gotham','ZZ','22222'),
('BigBusiness','456 Second Street','','Metropolis','YY','98765');
--
INSERT INTO ShippingAddress
(CustomerId,Address1,Address2,City,ShipState,ZIP)
SELECT c.CustomerId,'123 Main Street','','Fairview','XX','12345'
FROM Customer c
WHERE Name = 'Fidgett, Panneck, and Runn';
--
INSERT INTO ShippingAddress
(CustomerId,Address1,Address2,City,ShipState,ZIP)
SELECT c.CustomerId,'Apt. B','221 Baker Street','Gotham','ZZ','22222'
FROM Customer c
WHERE Name = 'Dr. John H. Watson';
--
INSERT INTO ShippingAddress
(CustomerId,Address1,Address2,City,ShipState,ZIP)
SELECT c.CustomerId,'77777 US HWY 12','','FRISCO','NC','27272'
FROM Customer c
WHERE Name = 'BigBusiness';
--
INSERT INTO ShippingAddress
(CustomerId,Address1,Address2,City,ShipState,ZIP)
SELECT c.CustomerId,'Attn: Alfred','Stately Wayne Manor','Gotham','NY','23333'
FROM Customer c
WHERE Name = 'BigBusiness';
--
--
-- Making a column longer is always allowed. Making it shorter requires you to DROP STATISTICS
-- for that column. Also there are problems if the column is indexed.
SELECT MAX(LEN(Address1)) 
FROM dbo.Customer
GO
DBCC SHOW_STATISTICS (Customer, Address1);
DBCC SHOW_STATISTICS ("dbo.Customer", Address1);  -- dot apparently must be enclosed in double quotes
--If an automatically created statistic does not exist for a column target, error message 2767 is returned. 

DROP STATISTICS dbo.Customer.statisticsName
--
ALTER TABLE dbo.MailingAddress
   ADD AddressVersion smallint NOT NULL DEFAULT(1);
GO
-- CREATE TRIGGER must be the only statement in the batch
CREATE TRIGGER dbo.MailingAddressTrigger ON dbo.Customer 
FOR INSERT,UPDATE AS 
(
   
);
