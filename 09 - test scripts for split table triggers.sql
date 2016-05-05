--
--   Define test scripts for split-table triggers
--
--   Tests are:
--       INSERT via old definitions, a new customer
--       INSERT via old definitions, multiple new customers
--       INSERT via old definitions, a new shipping address
--       INSERT via old definitions, multiple new shipping addresses
--       UPDATE via old definitions, a customer's billing address
--       UPDATE via old definitions, a customer's other data
--       DELETE (old)(after deleting all shipping addresses), a customer
--       INSERT via new definitions, a new customer
--       INSERT (via new definitions) a new billing address for an existing customer
--       INSERT via new definitions, a new shipping address
--       UPDATE via new definitions, a customer's billing address
--       UPDATE via new definitions, a customer's other data
--       DELETE (new)(after deleting the shipping addresses), a billing address
--       DELETE (new)(after deleting all addresses), a customer
--   TODO: what to do about "ON DELETE CASCADE" on BillingAddress? Eventually it needs to be removed!
--
--   FYI: on failed tests, the _m_ column is < for expected, and > for actual
--
USE Demo1;
GO
--
--   One time for the database: 
--:r tSQLt.class.sql
--
--   One time to define the schema for the application's test script
--EXEC tSQLt.NewTestClass 'testSplitTableTriggers';
--GO
--
--   Define test scripts
--
--
--  Verify that setup loads tables correctly.  This may seem silly, but it
--  ensures that you're not looking in the wrong place when some other test
--  fails.  This test, therefore, is really more of a debugging aid than a
--  true test.  Stop snickering: this test case found several bugs in the
--  setup procedure. It is also the template for the tests scripts that follow.
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that Setup loads tables correctly]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that Setup loads tables correctly];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that Setup loads tables correctly]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
    --Act
    -- (Nothing needs to be done for this test case.)

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT Customer using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT Customer using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT Customer using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
------Act
   INSERT INTO Customer
   (Name1,Name2,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingPostal1,BillingPostal2)
   VALUES
   ('Santa Claus','', '325 S. Santa Claus Lane', '', 'North Pole', 'AK', '', '99705');

------Assert
    CREATE TABLE expected_customer (
      CustomerID        int,
      Name1             varchar(30),
      Name2             varchar(30),
      BillingAddress1   nvarchar(64),
      BillingAddress2   nvarchar(64),
      BillingCity       nvarchar(64),
      BillingState      nchar(2),
      BillingPostal1    nvarchar(11),
      BillingPostal2    nvarchar(11),
      BillingCountry    nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');
   DECLARE @c_sc  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Santa Claus');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us'),
    (@c_sc, 'Santa Claus',                 '', '325 S. Santa Claus Lane', '', 'North Pole',
     'AK', '', '99705',     '','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);
   DECLARE @ba_sc  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_sc);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us'),
      (@ba_sc,  @c_sc,  '325 S. Santa Claus Lane', '', 'North Pole','AK','','99705',     '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles multiple INSERT Customers using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles multiple INSERT Customers using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles multiple INSERT Customers using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
------Act
   INSERT INTO Customer
   (Name1,Name2,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingPostal1,BillingPostal2)
   VALUES
   ('Santa Claus','', '325 S. Santa Claus Lane', '', 'North Pole', 'AK', '', '99705'),
   ('Easter Bunny','and friends', 'Apt 3', '1234 Left Turnpike', 'Nowhere', 'ZZ', '', '44444');

------Assert
    CREATE TABLE expected_customer (
      CustomerID        int,
      Name1             varchar(30),
      Name2             varchar(30),
      BillingAddress1   nvarchar(64),
      BillingAddress2   nvarchar(64),
      BillingCity       nvarchar(64),
      BillingState      nchar(2),
      BillingPostal1    nvarchar(11),
      BillingPostal2    nvarchar(11),
      BillingCountry    nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');
   DECLARE @c_sc  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Santa Claus');
   DECLARE @c_eb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Easter Bunny');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us'),
    (@c_sc, 'Santa Claus',                 '', '325 S. Santa Claus Lane', '', 'North Pole',
     'AK', '', '99705',     '','us'),
    (@c_eb,  'Easter Bunny','and friends', 'Apt 3', '1234 Left Turnpike',   'Nowhere',
     'ZZ', '', '44444',     '','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);
   DECLARE @ba_sc  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_sc);
   DECLARE @ba_eb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_eb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us'),
      (@ba_sc,  @c_sc,  '325 S. Santa Claus Lane', '', 'North Pole','AK','','99705',     '', 'us'),
      (@ba_eb,  @c_eb,  'Apt 3', '1234 Left Turnpike', 'Nowhere',   'ZZ', '','44444',    '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test INSERT Shipping Address using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test INSERT Shipping Address using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test INSERT Shipping Address using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
    --Act
    DECLARE @cust int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO dbo.ShippingAddress
    (ShippingAddressID, CustomerID, Address1, Address2, City, [State],
     Postal1, Postal2, Country, CountryCode)
    VALUES
    ('Store #222', @cust, '6543 Park Street', '', 'Bear Wallow', 'NC',
     '', '28792', '', 'us')

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');
   DECLARE @sa_bb04 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #222');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb),
    (@sa_bb04, 'Store #222',  @c_bb,  '6543 Park Street',  '',      'Bear Wallow', 'NC','', '28792',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test INSERT multiple Shipping Addresses using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test INSERT multiple Shipping Addresses using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test INSERT multiple Shipping Addresses using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
    --Act
    DECLARE @cust1 int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
    DECLARE @cust2 int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO dbo.ShippingAddress
    (ShippingAddressID, CustomerID, Address1, Address2, City, [State],
     Postal1, Postal2, Country, CountryCode)
    VALUES
    ('Store #222', @cust2, '6543 Park Street', '', 'Bear Wallow', 'NC',
     '', '28792', '', 'us'),
    ('Satellite 2', @cust1, 'Apt 1101', '13 Binary Road', 'San Jose', 'CA',
    '',  '10101', '', 'us');

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_fpr3 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 2');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');
   DECLARE @sa_bb04 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #222');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr3, 'Satellite 2', @c_fpr, 'Apt 1101', '13 Binary Road', 'San Jose', 'CA',   '',  '10101',     '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb),
    (@sa_bb04, 'Store #222',  @c_bb,  '6543 Park Street',  '',      'Bear Wallow', 'NC','', '28792',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test changing a customer billing address using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test changing a customer billing address using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test changing a customer billing address using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;

    --Act
    --   According to https://personal.help.royalmail.com/app/answers/detail/a_id/112
    --   this is a valid German mailing address    
    UPDATE Customer
         SET BillingAddress1 = 'Weberstr. 2',
          BillingAddress2 = 'Postfach 260',
          BillingCity     = 'BONN',
          BillingState    = '',
          BillingPostal1  = '53113',
          BillingPostal2  = '1',
          BillingCountry  = 'GERMANY',
          BillingCountryCode = 'de'
    WHERE Name1 = 'Big Business';

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', 'Weberstr. 2', 'Postfach 260', 'BONN',
     '', '53113', '1', 'GERMANY', 'de');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  'Weberstr. 2', 'Postfach 260', 'BONN',   '', '53113', '1', 'GERMANY', 'de');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test changing multiple customer billing addresses using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test changing multiple customer billing addresses using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test changing multiple customer billing addresses using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;

    --Act
    UPDATE Customer
         SET BillingAddress1 = 'Weberstr. 2',
          BillingAddress2 = 'Postfach 260',
          BillingCity     = 'BONN',
          BillingState    = '',
          BillingPostal1  = '53113',
          BillingPostal2  = '1',
          BillingCountry  = 'GERMANY',
          BillingCountryCode = 'de'
    WHERE Name1 > 'Big Business';

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', 'Weberstr. 2', 'Postfach 260', 'BONN',
     '', '53113', '1', 'GERMANY', 'de'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Weberstr. 2', 'Postfach 260', 'BONN',
     '', '53113', '1', 'GERMANY', 'de'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '',    '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
     (@c_fpr, @ba_fpr, 'Weberstr. 2', 'Postfach 260', 'BONN',       '',   '53113', '1',        'GERMANY', 'de'),
     (@c_jhw, @ba_jhw, 'Weberstr. 2', 'Postfach 260', 'BONN',       '',   '53113', '1',        'GERMANY', 'de'),
     (@c_bb,  @ba_bb,  '456 Second Street',       '', 'Metropolis', 'YY', '',      '98765-4321','',       'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test changing a customer non-address data using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test changing a customer non-address data using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test changing a customer non-address data using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;

    --Act
    --   According to https://personal.help.royalmail.com/app/answers/detail/a_id/112
    --   this is a valid German mailing address    
    UPDATE Customer
         SET Name2 = 'Comglomerate'
    WHERE Name1 = 'Big Business';

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

   INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',   'Comglomerate', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test changing a customer non-address data using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test changing multiple customer non-address data using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test changing multiple customer non-address data using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;

    --Act
    --   According to https://personal.help.royalmail.com/app/answers/detail/a_id/112
    --   this is a valid German mailing address    
    UPDATE Customer
         SET Name1 = '** ' + Name1;

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = '** Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = '** Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = '** Big Business');

   INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, '** Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, '** Dr. John H. Watson',         '', 'Apt. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  '** Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'Apt. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test UPDATE of old address that only changes case]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test UPDATE of old address that only changes case];
GO
CREATE PROCEDURE testSplitTableTriggers.[test UPDATE of old address that only changes case]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
    --Act
    UPDATE Customer
       SET BillingAddress1 = 'APT. B'
    WHERE Name1 = 'Dr. John H. Watson';

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_jhw, 'Dr. John H. Watson',         '', 'APT. B','221 Baker Street', 'Gotham',
     'ZZ', '', '22222',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_jhw int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_jhw);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_jhw, @c_jhw, 'APT. B','221 Baker Street','Gotham',    'ZZ', '', '22222',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_jhw1, '',            @c_jhw, 'Apt. B', '221 Baker Street', 'Gotham',     'ZZ', '', '22222',      '', 'us', @ba_jhw),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test Customer delete]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test Customer delete];
GO
CREATE PROCEDURE testSplitTableTriggers.[test Customer delete]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected_customer') IS NOT NULL DROP TABLE expected_customer;
    IF OBJECT_ID('expected_billing_address')  IS NOT NULL DROP TABLE expected_billing_address;
    IF OBJECT_ID('expected_shipping_address') IS NOT NULL DROP TABLE expected_shipping_address;
    
    --Act
    --   (ShippingAddress has a foreign key on Customer, so we delete that record first.)
    DELETE FROM ShippingAddress 
    WHERE Address1 = 'Apt. B';

    DELETE FROM Customer
    WHERE Name1 = 'Dr. John H. Watson';

    --Assert
    CREATE TABLE expected_customer (
      CustomerID       int,
      Name1            varchar(30),
      Name2            varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   DECLARE @c_fpr int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Fidgett, Panneck, and Runn');
   DECLARE @c_jhw int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Dr. John H. Watson');
   DECLARE @c_bb  int = (SELECT CustomerID FROM Customer WHERE Name1 = 'Big Business');

    INSERT INTO expected_customer
    (CustomerID, Name1, Name2, BillingAddress1, BillingAddress2, BillingCity, 
     BillingState, BillingPostal1,BillingPostal2,BillingCountry,BillingCountryCode)
    VALUES
    (@c_fpr, 'Fidgett, Panneck, and Runn', '', '123 Main Street',       '', 'Fairview', 
     'XX', '', '12345',     '','us'),
    (@c_bb,  'Big Business',               '', '456 Second Street',     '', 'Metropolis',
     'YY', '', '98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected_customer', 'Customer';

   CREATE TABLE expected_billing_address  (
      BillingAddressID int,
      CustomerId       int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2)
   );

   DECLARE @ba_fpr int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_fpr);
   DECLARE @ba_bb  int = (SELECT BillingAddressID FROM BillingAddress WHERE CustomerId = @c_bb);

   INSERT INTO expected_billing_address
      (BillingAddressID, CustomerId, Address1, Address2, City, [State], Postal1, Postal2,Country,CountryCode)
   VALUES
      (@ba_fpr, @c_fpr, '123 Main Street','',       'Fairview',  'XX', '', '12345',      '', 'us'),
      (@ba_bb,  @c_bb,  '456 Second Street','',     'Metropolis','YY', '', '98765-4321', '', 'us');

	EXEC tSQLt.AssertEqualsTable 'expected_billing_address', 'BillingAddress';

   CREATE TABLE expected_shipping_address  (
      ShippingAddressInternalId int,
      ShippingAddressID nvarchar(20),
      CustomerID  int,
      Address1  nvarchar(64),
      Address2  nvarchar(64),
      City      nvarchar(64),
      [State]   char(2),
      Postal1   nvarchar(11),
      Postal2   nvarchar(11),
      Country   nvarchar(64),
      CountryCode nchar(2),
      BillingAddressID  int
   );

   DECLARE @sa_fpr1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Main Office');
   DECLARE @sa_fpr2 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_fpr
                            AND ShippingAddressID = 'Satellite 1');
   DECLARE @sa_jhw1 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_jhw
                            AND ShippingAddressID = '');
   DECLARE @sa_bb01 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #101');
   DECLARE @sa_bb02 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #102');
   DECLARE @sa_bb03 int = (SELECT ShippingAddressInternalId 
                          FROM ShippingAddress 
                          WHERE CustomerId = @c_bb
                            AND ShippingAddressID = 'Store #103');

   INSERT INTO expected_shipping_address
   (ShippingAddressInternalId,ShippingAddressID,CustomerID,Address1,Address2,City,[State],Postal1,Postal2,Country,CountryCode,BillingAddressID)
   VALUES
    (@sa_fpr1, 'Main Office', @c_fpr, '123 Main Street',   '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_fpr2, 'Satellite 1', @c_fpr, '9901 First Street', '',      'Fairview',   'XX', '', '12345',      '', 'us', @ba_fpr),
    (@sa_bb01, 'Store #101',  @c_bb,  '456 Second Street', '',      'Metropolis', 'YY', '', '98765-4321', '', 'us', @ba_bb),
    (@sa_bb02, 'Store #102',  @c_bb,  '9 Ninth Street',    '',      'Metropolis', 'YY', '', '98765-9999', '', 'us', @ba_bb),
    (@sa_bb03, 'Store #103',  @c_bb,  '101 Main Street',   '',      'Little Town','YY', '', '88888',      '', 'us', @ba_bb);

	EXEC tSQLt.AssertEqualsTable 'expected_shipping_address', 'ShippingAddress';
END;
GO
--
--
-- TODO: Add these tests
--       INSERT via new definitions, a new customer
--       INSERT (via new definitions) a new billing address for an existing customer
--       INSERT via new definitions, a new shipping address
--       UPDATE via new definitions, a customer's billing address
--       UPDATE via new definitions, a customer's other data
--       UPDATE multiple billing addresses using new data?
--       UPDATE, via new definitions, a billing address affecting only the letter case
--       DELETE (new)(after deleting the shipping addresses), a billing address
--       DELETE (new)(after deleting all addresses), a customer
--
--IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using new columns]','P') IS NOT NULL
--IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using new Name1 column]','P') IS NOT NULL
--
--   When I gave the 10 minute presentation, someone in the audience asked if
--   I had tried an update where only the case of the value was changed - many
--   collations imply that WHERE clauses are case-insensitive. After some
--   thought, I realized his question raised a valid issue but was misworded.
--   To be safe, I create FOUR tests.
--     BTW, the database collation is SQL_Latin1_General_CP1_CI_AS,
--   which is case-insensitive (CI) and accent-sensitive (AS).
--
--IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE old with only a case difference]','P') IS NOT NULL
--IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE new with only a case difference]','P') IS NOT NULL
--IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case]','P') IS NOT NULL
--       ...differs from an existing row only by case
--IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to new correctly]','P') IS NOT NULL
   
--
--  Run all tests for application
--
--EXEC tSQLt.Run 'testSplitTableTriggers';
EXEC tsqlt.Run N'testSplitTableTriggers.[test Customer delete]';
