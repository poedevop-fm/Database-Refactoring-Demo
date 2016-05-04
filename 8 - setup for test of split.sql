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
DECLARE @fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
DECLARE @jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
DECLARE @bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

INSERT INTO BillingAddress
   (CustomerId, Address1, Address2, City, [State], Postal1, Postal2)
VALUES
   (@fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345'),
   (@jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222'),
   (@bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321');
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
--    Create trigger for Customer table
--
-- TODO: add trigger code here
