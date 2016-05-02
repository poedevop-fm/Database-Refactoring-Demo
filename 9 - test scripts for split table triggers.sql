--
--   Define test scripts for split-table triggers
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
IF OBJECT_ID(N'testSplitTableTriggers.[test that Setup loads Customer table]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that Setup loads Customer table];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that Setup loads Customer table]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act

------Assert
    -- Since we don't control the value of CustomerID nor the order of tests, checking its values is pointless.
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

    --      Values BEFORE conversion begins
    --INSERT INTO expected
    --(CustomerId,Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
    -- BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
    -- BillingCountryCode)
    --VALUES
    --(1,'Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    '','','','','','us'),
    --(2,'Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    '','','','','','us'),
    --(3,'BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','','','','','','us');

    INSERT INTO expected
    (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,
     BillingZIP,Name1,Name2,BillingPostal1,BillingPostal2,BillingCountry,
     BillingCountryCode)
    VALUES
    ('Fidgett, Panneck, and Runn','123 Main Street',       '', 'Fairview',  'XX','12345',    'Fidgett, Panneck, and Runn','','','12345',     '','us'),
    ('Dr. John H. Watson',        'Apt. B','221 Baker Street', 'Gotham',    'ZZ','22222',    'Dr. John H. Watson',        '','','22222',     '','us'),
    ('BigBusiness',               '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',               '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--
IF OBJECT_ID(N'testSplitTableTriggers.[test that trigger handles INSERT using old columns]','P') IS NOT NULL
   DROP PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using old columns];
GO
CREATE PROCEDURE testSplitTableTriggers.[test that trigger handles INSERT using old columns]
AS
BEGIN
    --Arrange
    IF OBJECT_ID('expected') IS NOT NULL DROP TABLE expected;

------Act
   INSERT INTO Customer
   (Name,BillingAddress1,BillingAddress2,BillingCity,BillingState,BillingZIP)
   VALUES
   ('Santa Claus','325 S. Santa Claus Lane','','North Pole', 'AK','99705');

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
    ('Santa Claus',               '325 S. Santa Claus Lane','','North Pole','AK','99705',    'Santa Claus',               '','','99705',     '','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
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
    ('BigBusiness',                '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',                '','','98765-4321','','us');

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
    ('BigBusiness',                '456 Second Street',     '', 'Metropolis','YY','987654321','BigBusiness',                '','','98765-4321','','us');

	EXEC tSQLt.AssertEqualsTable 'expected', 'Customer';
END;
GO
--
--  Run all tests for application
--
EXEC tSQLt.Run 'testSplitTableTriggers';
