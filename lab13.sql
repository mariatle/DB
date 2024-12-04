USE master;
GO
-- 1) Создать две базы данных на одном экземпляре СУБД SQL Server 2012

IF DB_ID('lab13db1') IS NOT NULL
	DROP DATABASE lab13db1;
GO

IF DB_ID('lab13db2') IS NOT NULL
	DROP DATABASE lab13db2;
GO


CREATE DATABASE lab13db1
ON 
(
	NAME = lab13db1,
	FILENAME = 'D:\lab13db1.mdf',
	SIZE = 10,
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5%
)
GO 

CREATE DATABASE lab13db2 
ON 
(
	NAME = lab13db2,
	FILENAME = 'D:\lab13db2.mdf',
	SIZE = 10,
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5%
);
GO

-- 2) Создать в базах данных п.1. горизонтально фрагментированные таблицы для аренды снаряжения.
USE lab13db1
GO

IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO

CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL CHECK (EquipmentID < 3),
	SerialNumber CHAR(17) NOT NULL CHECK (LEN(SerialNumber) = 17),
	Model NVARCHAR(50) NOT NULL CHECK (LEN(Model) > 1),
	RentalPrice DECIMAL(10, 2) NOT NULL,
	AvailabilityStatus NVARCHAR(50) NOT NULL,
	ProductionDate SMALLDATETIME NOT NULL
);
GO

USE lab13db2
GO

IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO

CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL CHECK (EquipmentID >= 3),
	SerialNumber CHAR(17) NOT NULL CHECK (LEN(SerialNumber) = 17),
	Model NVARCHAR(50) NOT NULL CHECK (LEN(Model) > 1),
	RentalPrice DECIMAL(10, 2) NOT NULL,
	AvailabilityStatus NVARCHAR(50) NOT NULL,
	ProductionDate SMALLDATETIME NOT NULL
);
GO

-- 3) Создать секционированные представления, обеспечивающие работу с данными таблиц для аренды снаряжения.
IF OBJECT_ID(N'EquipmentView') IS NOT NULL
	DROP VIEW EquipmentView;
GO

CREATE VIEW EquipmentView AS
	SELECT * FROM lab13db1.dbo.Equipment
	UNION ALL
	SELECT * FROM lab13db2.dbo.Equipment
GO

INSERT INTO EquipmentView (EquipmentID, SerialNumber, Model, RentalPrice, AvailabilityStatus, ProductionDate) VALUES
(1, 'SN123456789012345', 'Ski Poles', 150.00, 'Available', '2022-12-01'),
(2, 'SN123456789012346', 'Snowboard', 300.00, 'Available', '2021-05-01'),
(3, 'SN123456789012347', 'Ski Boots', 200.00, 'Rented', '2023-01-01'),
(4, 'SN123456789012348', 'Helmet', 50.00, 'Available', '2021-11-01'),
(5, 'SN123456789012349', 'Snowboard', 180.00, 'Rented', '2022-02-01'), 
(6, 'SN123456789012350', 'Gloves', 30.00, 'Available', '2020-12-15'),
(7, 'SN123456789012351', 'Jacket', 400.00, 'Rented', '2023-04-10'),
(8, 'SN123456789012352', 'Helmet', 250.00, 'Available', '2022-06-05'), 
(9, 'SN123456789012353', 'Ski Goggles', 100.00, 'Available', '2021-03-20'),
(10, 'SN123456789012354', 'Ski Backpack', 120.00, 'Rented', '2023-02-01'),
(11, 'SN123456789012355', 'Ski Poles', 500.00, 'Available', '2022-09-01'), 
(12, 'SN123456789012356', 'Ski Suit', 800.00, 'Rented', '2023-07-10'),
(13, 'SN123456789012357', 'Ski Gloves', 35.00, 'Available', '2020-10-25'),
(14, 'SN123456789012358', 'Snowboard Bag', 220.00, 'Rented', '2021-08-01'),
(15, 'SN123456789012359', 'Helmet', 70.00, 'Available', '2023-03-15'), 
(16, 'SN123456789012360', 'Boot Warmers', 60.00, 'Available', '2022-01-10'),
(17, 'SN123456789012361', 'Avalanche Beacon', 1200.00, 'Available', '2023-05-22'),
(18, 'SN123456789012362', 'Snowshoes', 180.00, 'Available', '2020-11-15'),
(19, 'SN123456789012363', 'Ski Poles', 160.00, 'Available', '2021-12-01'), 
(20, 'SN123456789012364', 'Ski Boots', 300.00, 'Rented', '2023-06-12');
GO


SELECT * FROM EquipmentView ORDER BY ProductionDate;

SELECT * FROM lab13db1.dbo.Equipment
SELECT * FROM lab13db2.dbo.Equipment
GO

UPDATE EquipmentView
SET AvailabilityStatus = 'Rented' WHERE Model = 'Ski Poles'
GO

SELECT * FROM lab13db1.dbo.Equipment
SELECT * FROM lab13db2.dbo.Equipment
GO

DELETE FROM EquipmentView
	WHERE Model= 'Ski Poles'
GO 

SELECT * FROM lab13db1.dbo.Equipment
SELECT * FROM lab13db2.dbo.Equipment
GO
