--   Demo of incremental table change
--   9. Cleanup
--
USE tempdb;
GO
IF OBJECT_ID('FK_ShippingAddress_Customer', 'F') IS NOT NULL
   ALTER TABLE ShippingAddress DROP CONSTRAINT FK_ShippingAddress_Customer;
GO
IF OBJECT_ID('ShippingAddress','U') IS NOT NULL DROP TABLE ShippingAddress;
IF OBJECT_ID('Customer',       'U') IS NOT NULL DROP TABLE Customer;
GO
