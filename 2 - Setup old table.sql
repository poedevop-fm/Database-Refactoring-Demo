--   Demo of incremental table change
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
   Name      varchar(30) NOT NULL,
   BillingAddress1  varchar(30) NOT NULL,
   BillingAddress2  varchar(30) NOT NULL,
   BillingCity      varchar(30) NOT NULL,
   BillingState     char(2) NOT NULL,
   BillingZIP       char(9)
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
