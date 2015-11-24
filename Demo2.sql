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
USE tempdb;
--
--   Eventually we want this:
--
--CREATE TABLE Customer
--(
--   CustomerId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
--   Name      varchar(30) NOT NULL,
--);
--CREATE TABLE dbo.MailingAddress
--(
--   AddressId      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
--   CustomerId     int NOT NULL,
--   Effective      date,
--   NotValidAfter  date,
--   UseForBilling  bit,
--   UseForShipping bit,
--   AddressVersion smallint NOT NULL DEFAULT(2),
--   Name1      nvarchar(64) NOT NULL,
--   Name2      nvarchar(64) NOT NULL,
--   Address1   nvarchar(64) NOT NULL,
--   Address2   nvarchar(64) NOT NULL,
--   City       nvarchar(30) NOT NULL,
--   Postal1    nvarchar(12) NULL,
--   Postal2    nvarchar(12) NULL,
--   Country    nvarchar(64) NULL, -- 'United Kingdom of Great Britain and Northern Ireland' is 53
--   CountyCode nchar(2) NOT NULL DEFAULT('us'),  -- ISO 3166
--   CONSTRAINT FK_MailingAddress_Customer
--      FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
--);
--
--  Step 1
--
CREATE TABLE dbo.MailingAddress
(
   AddressId      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   CustomerId     int NOT NULL,
   Effective      date,
   NotValidAfter  date,
   UseForBilling  bit,
   UseForShipping bit,
   AddressVersion smallint NOT NULL DEFAULT(2),
   Name1      nvarchar(64) NOT NULL,
   Name2      nvarchar(64) NOT NULL,
   Address1   nvarchar(64) NOT NULL,
   Address2   nvarchar(64) NOT NULL,
   City       nvarchar(30) NOT NULL,
   Postal1    nvarchar(12) NULL,
   Postal2    nvarchar(12) NULL,
   Country    nvarchar(64) NULL, -- 'United Kingdom of Great Britain and Northern Ireland' is 53
   CountyCode nchar(2) NOT NULL DEFAULT('us'),  -- ISO 3166
);
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
