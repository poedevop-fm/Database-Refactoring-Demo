--
--   Define test scripts for split-table triggers
--
--   Tests are:
--       INSERT via old definitions, a new customer
--       INSERT via old definitions, a new shipping address
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
--  setup procedure. It is also the template for all the tests scripts that
--  follow.
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
EXEC tsqlt.Run N'testSplitTableTriggers.[test INSERT multiple Shipping Addresses using old columns]';
--
-- TODO: Add these tests
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
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using new columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   INSERT INTO Customer
   (Name1,BillingAddress1,BillingAddress2, BillingCity, BillingState,BillingPostal2)
   VALUES
   ('Bullwinke J. Moose', '1 Veronica Lake', '', 'Frostbite Falls','MN','56649-1111');

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us'),
    ('Bullwinke J. Moose',        '1 Veronica Lake',       '', 'Frostbite Falls','MN','566491111','Bullwinke J. Moose',   '','','56649-1111','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE of address column]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE of address column];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles UPDATE of address column]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
      SET BillingAddress1 = '2 Second Street'
    WHERE Name = 'BigBusiness';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('BigBusiness',               '2 Second Street',       '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE of old Name column]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE of old Name column];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE of old Name column]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
      SET Name = 'Really Big Business'
    WHERE Name = 'BigBusiness';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('Really Big Business',       '456 Second Street',     '', 'Metropolis','YY','987654321','Really Big Business',       '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE of old ZIP code column]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE of old ZIP code column];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE of old ZIP code column]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
       SET BillingZIP = '222223333'
    WHERE Name = 'Dr. John H. Watson'

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','222223333',    'Dr. John H. Watson',    '','','22222-3333','','us'),
    ('BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using new Name1 column]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new Name1 column];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new Name1 column]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
       SET Name1 = 'The big business'
    WHERE Name1 = 'BigBusiness';


------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('The big business',          '456 Second Street',     '', 'Metropolis','YY','987654321','The big business',          '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using new Postal2 column]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new Postal2 column];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using new Postal2 column]
AS
BEGIN
   --Arrange
   IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   UPDATE Customer
      SET BillingPostal2 = '12345-9876'
   WHERE Name1 = 'Fidgett, Panneck, and Runn'

------Assert
   CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

   INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
   VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','123459876','Fidgett, Panneck, and Runn','','','12345-9876','','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--   When I gave the 10 minute presentation, someone in the audience asked if
--   I had tried an update where only the case of the value was changed - many
--   collations imply that WHERE clauses are case-insensitive. After some
--   thought, I realized his question raised a valid issue but was misworded.
--   To be safe, I create FOUR tests.
--     BTW, the database collation is SQL_Latin1_General_CP1_CI_AS,
--   which is case-insensitive (CI) and accent-sensitive (AS).
--
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE old with only a case difference]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE old with only a case difference];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles UPDATE old with only a case difference]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   UPDATE Customer
      SET Name = 'Bigbusiness'
   WHERE Name = 'BigBusiness';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('Bigbusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','Bigbusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles UPDATE new with only a case difference]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles UPDATE new with only a case difference];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles UPDATE new with only a case difference]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   UPDATE Customer
      SET Name1 = 'Bigbusiness'
   WHERE Name1 = 'BigBusiness';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('Bigbusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','Bigbusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   INSERT INTO Customer
   (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
   VALUES
   ('Bigbusiness','325 Santa Claus Lane','','North Pole', 'AK','99705');

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us'),
    ('Bigbusiness',               '325 Santa Claus Lane',  '','North Pole', 'AK','99705',    'Bigbusiness',               '','','99705',     '','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles INSERT old that differs only by case]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   INSERT INTO Customer
   (Name1,BillingAddress1,BillingAddress2, BillingCity, BillingState,BillingPostal2)
   VALUES
   ('Big Business','325 Santa Claus Lane','','North Pole', 'AK','99705');

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('Big Business',              '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us'),
    ('Big Business',              '325 Santa Claus Lane',  '','North Pole', 'AK','99705',    'Bigbusiness',               '','','99705',     '','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--   Someone at the 10 minute presentation came up to me afterwards and said
--   they tried to use triggers but couldn't get them to work on more than one
--   row.  Verify that multi-row UPDATEs work correctly.
--
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to old correctly]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to old correctly];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to old correctly]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
      SET Name = '*' + Name
    WHERE Name > 'C';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('*Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    '*Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('*Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    '*Dr. John H. Watson',        '','','22222',     '','us'),
    ('Big Business',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',                '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
IF    OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to new correctly]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to new correctly];
GO
CREATE PROCEDURE  testSplitTableTriggers.[test that trigger handles multi-row UPDATEs to new correctly]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
    UPDATE Customer
      SET Name1 = '*' + Name1
    WHERE Name1 > 'C';

------Assert
    CREATE TABLE expected (
      Name             varchar(30),
      BillingAddress1  nvarchar(64),
      BillingAddress2  nvarchar(64),
      BillingCity      nvarchar(64),
      BillingState     nchar(2),
      BillingZIP       char(9),
      Name1            nvarchar(64),
      Name2            nvarchar(64),
      BillingPostal1   nvarchar(11),
      BillingPostal2   nvarchar(11),
      BillingCountry   nvarchar(64),
      BillingCountryCode nchar(2)
    );

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('*Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    '*Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('*Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    '*Dr. John H. Watson',        '','','22222',     '','us'),
    ('Big Business',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',                '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--  Run all tests for application
--
EXEC tSQLt.Run 'testSplitTableTriggers';
--EXEC tSQLt.Run N'testSplitTableTriggers.[test that Setup loads tables correctly]';
EXEC tSQLt.Run N'testSplitTableTriggers.[test that trigger handles INSERT Customer using old columns]';