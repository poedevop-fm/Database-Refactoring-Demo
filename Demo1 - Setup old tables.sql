--   Demo of incremental table change
--   1. Initial table schema and contents
--
USE tempdb;

IF OBJECT_ID('ShippingAddress','U') IS NOT NULL DROP TABLE ShippingAddress;
IF OBJECT_ID('Customer',       'U') IS NOT NULL DROP TABLE Customer;

CREATE TABLE Customer
(
   CustomerId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   Name      varchar(30) NOT NULL,
   BillingAddress1  varchar(30) NOT NULL,
   BillingAddress2  varchar(30) NOT NULL,
   BillingCity      varchar(30) NOT NULL,
   BillingState     char(2) NOT NULL,
   BillingZIP       char(9)
);

CREATE TABLE ShippingAddress
(
   ShippingId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   CustomerId int        NOT NULL,
   Address1  varchar(30) NOT NULL,
   Address2  varchar(30) NOT NULL,
   City      varchar(30) NOT NULL,
   ShipState char(2)     NOT NULL,
   ZIP       char(9),
   CONSTRAINT FK_ShippingAddress_Customer
      FOREIGN KEY (CustomerId) REFERENCES Customer (CustomerId)
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
--  Test: table should have contents
--
SELECT * FROM Customer;
SELECT * FROM ShippingAddress;
