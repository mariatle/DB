USE master;
GO

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

-- Создать в базах данных п.1. горизонтально фрагментированные таблицы для аренды снаряжения.
USE lab13db1
GO

IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
go

CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL CHECK (EquipmentID < 3),
	SerialNumber CHAR(17) NOT NULL CHECK (LEN(SerialNumber) = 17),
	Model NVARCHAR(50) NOT NULL CHECK (LEN(Model) > 1),
	RentalPrice DECIMAL(10, 2) NOT NULL,
	AvailabilityStatus NVARCHAR(50) NOT NULL,
	ProductionDate SMALLDATETIME NOT NULL
);
go

USE lab13db2
GO

IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
go

CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL CHECK (EquipmentID >= 3),
	SerialNumber CHAR(17) NOT NULL CHECK (LEN(SerialNumber) = 17),
	Model NVARCHAR(50) NOT NULL CHECK (LEN(Model) > 1),
	RentalPrice DECIMAL(10, 2) NOT NULL,
	AvailabilityStatus NVARCHAR(50) NOT NULL,
	ProductionDate SMALLDATETIME NOT NULL
);
go

-- Создать секционированные представления, обеспечивающие работу с данными таблиц для аренды снаряжения.
IF OBJECT_ID(N'EquipmentView') IS NOT NULL
	DROP VIEW EquipmentView;
go

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
(5, 'SN123456789012349', 'Snowboard Boots', 180.00, 'Rented', '2022-02-01')
go

SELECT * FROM EquipmentView ORDER BY ProductionDate;

SELECT * FROM lab13db1.dbo.Equipment
SELECT * FROM lab13db2.dbo.Equipment
GO

UPDATE EquipmentView
SET AvailabilityStatus = 'Rented' WHERE Model = 'Snowboard'
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
