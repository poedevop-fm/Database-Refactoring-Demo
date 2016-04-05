--
--   Setup for testing Customer table's trigger
--
USE Demo1;
GO
--
--   Create table
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
--
IF OBJECT_ID('Customer','U') IS NOT NULL 
   DROP TABLE Customer;
--
CREATE TABLE Customer
(
   CustomerId       int IDENTITY(1,1) NOT NULL PRIMARY KEY,
   Name             varchar(30) NOT NULL,
   BillingAddress1  varchar(30) NOT NULL,
   BillingAddress2  varchar(30) NOT NULL,
   BillingCity      varchar(30) NOT NULL,
   BillingState     char(2) NOT NULL,
   BillingZIP       char(9)
);
--
--   Add sample data
--
INSERT INTO Customer
   (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
VALUES
   ('Fidgett, Panneck, and Runn','123 Main Street','',       'Fairview',  'XX','12345'),
   ('Dr. John H. Watson',        'Apt. B','221 Baker Street','Gotham',    'ZZ','22222'),
   ('BigBusiness',               '456 Second Street','',     'Metropolis','YY','987654321');
GO
--
--  Step 1: Expand: add columns and defaults to table
--  Using "Refactoring Databases", page 186, "Introduce Default Value"
--  so that revised code can ignore old columns.
ALTER TABLE Customer  ADD CONSTRAINT DF_Customer_Name DEFAULT('') FOR Name;
GO
--
--  Using "Refactoring Databases", page 126, "Replace Column",
--  first introduce new columns.
--  defaults allowed only so that triggers can recognize what needs to be updated.
--  Default constraints are named so that we can drop them later.
--
ALTER TABLE Customer  ADD
   Name1              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name1             DEFAULT(''),
   Name2              nvarchar(64) NOT NULL CONSTRAINT DF_Customer_Name2             DEFAULT(''),
   BillingPostal1     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal1    DEFAULT(''),
   BillingPostal2     nvarchar(11) NOT NULL CONSTRAINT DF_Customer_BillingPostal2    DEFAULT(''),
   BillingCountry     nvarchar(64) NOT NULL CONSTRAINT DF_Customer_BillingCountry    DEFAULT(''),
                        -- 'United Kingdom of Great Britain and Northern Ireland' is 53 chars
   BillingCountryCode nchar(2)     NOT NULL  
         CONSTRAINT DF_Customer_BillingCountryCode DEFAULT('us'); -- ISO 3166
GO
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
--    Run conversion to make old and new columns the same
--
UPDATE Customer
  SET Name1 = Name
WHERE Name1 = '' AND Name <> '';
GO
--
UPDATE Customer  
  SET BillingPostal2 = CASE WHEN SUBSTRING(BillingZIP,6,4) <= '' THEN BillingZIP
                            ELSE SUBSTRING(BillingZIP,1,5) + '-' + SUBSTRING(BillingZIP,6,4)
                       END
WHERE BillingPostal2 = ''  AND BillingZIP > '';
GO
--
SELECT * FROM Customer;
