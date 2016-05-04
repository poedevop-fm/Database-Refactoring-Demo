--   Demo of split table refactoring
--   1. Initial table schema and contents
--
USE Demo1;
GO
--
--   Create table
--
IF OBJECT_ID('Customer','U') IS NOT NULL DROP TABLE Customer;
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
       CONSTRAINT DF_Customer_BillingCountryCode DEFAULT 'us'; -- ISO 3166
);
GO
--
CREATE TABLE ShippingAddress
(
   ShippingAddressInternalId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   ShippingAddressID nvarchar(20) NOT NULL,
   CustomerID        int          NOT NULL,
   ShippingAddress1  nvarchar(64) NOT NULL,
   ShippingAddress2  nvarchar(64) NOT NULL,
   ShippingCity      nvarchar(64) NOT NULL,
   ShippingState     char(2) NOT NULL,
   ShippingZIP       char(9),
 CONSTRAINT FK_ShippingAddress_Customer 
   FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);
GO
--
--   Add sample data
--
INSERT INTO Customer
(Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
VALUES
('Fidgett, Panneck, and Runn','123 Main Street','','Fairview','XX','12345'),
('Dr. John H. Watson','Apt. B','221 Baker Street','Gotham','ZZ','22222'),
('BigBusiness','456 Second Street','','Metropolis','YY','987654321');
GO
--
--  Verify: table should have contents
--
DECLARE @cnt int = (SELECT COUNT(*) FROM Customer);
IF @cnt IS NULL OR @cnt < 3
 BEGIN;
    --  For SQL Server 2008, still need RAISERROR
    RAISERROR ('Create failed',11,1);
    THROW 51000, 'CREATE TABLE failed.', 1;
 END;
GO
SELECT * FROM Customer;
GO
DECLARE @fpr int = (SELECT CustomerID FROM Customer WHERE Name = 'Fidgett, Panneck, and Runn');
DECLARE @jhw int = (SELECT CustomerID FROM Customer WHERE Name = 'Dr. John H. Watson');
DECLARE @bb  int = (SELECT CustomerID FROM Customer WHERE Name = 'BigBusiness');
--
INSERT INTO ShippingAddress
(ShippingAddressID, CustomerID, 
 ShippingAddress1, ShippingAddress2, ShippingCity, ShippingState, ShippingZIP)
VALUES 
(@fpr, 'Main Office', '123 Main Street', '',      'Fairview',  'XX', '12345'),
(@fpr, 'Office #2',  '456 Pirate Lane', '',       'Nags Head', 'NC', '22222'),
(@jhw, '',           'Apt. B','221 Baker Street', 'Gotham',    'ZZ', '22222'),
(@bb,  'Store #101', '456 Second Street', '',     'Metropolis','YY', '987654321'),
(@bb,  'Store #102', '5555 N. Innes St.', '',     'Salisbury', 'NC', '282021111'),
(@bb,  'Store #103', '999 E. Peachtree Lane', '', 'Atlanta',   'GA', '33333');
GO
--
--  Verify: table should have contents
--
DECLARE @cnt int = (SELECT COUNT(*) FROM ShippingAddress);
IF @cnt IS NULL OR @cnt < 6
 BEGIN;
    --  For SQL Server 2008, still need RAISERROR
    RAISERROR ('Create failed',11,1);
    THROW 51000, 'CREATE TABLE failed.', 1;
 END;
GO
SELECT * FROM ShippingAddress;
