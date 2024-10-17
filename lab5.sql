USE MASTER;
GO

-- 1) Создать базу данных (CREATE DATABASE…,
-- определение настроек размеров файлов).

IF db_id(N'SKI_RENT') IS NOT NULL
DROP DATABASE SKI_RENT;
GO

CREATE DATABASE SKI_RENT ON
(
	name = SKI_RENT,
	filename = 'D:\SKI_RENT.mdf',
	size = 10,
	maxsize = unlimited,
	filegrowth = 3%
)
GO

-- 2) Создать произвольную таблицу (CREATE TABLE…).
USE SKI_RENT;
GO
IF OBJECT_ID(N'CUSTOMER') IS NOT NULL
	DROP TABLE CUSTOMER;
GO

CREATE TABLE CUSTOMER
(
	CustomerID INT NOT NULL PRIMARY KEY, 
    PhoneNumber NVARCHAR(15) NOT NULL,             
    Name NVARCHAR(50) NOT NULL,           
    Surname NVARCHAR(50) NOT NULL,        
    Patronymic NVARCHAR(50),                     
    Email NVARCHAR(50) NULL    
);
GO

-- SELECT * FROM CUSTOMER

-- 3) Добавить файловую группу и файл данных (ALTER DATABASE…).

ALTER DATABASE SKI_RENT
ADD FILEGROUP FG;
GO

ALTER DATABASE SKI_RENT
ADD FILE
(
	name = new_file,
	filename = 'D:\SKI_RENT.ndf',
	size = 1MB,
	maxsize = 25MB,
	filegrowth = 5MB
) to filegroup FG
GO

/*SELECT 
    fg.name AS FileGroupName,
    fg.type_desc AS FileGroupType
FROM 
    sys.filegroups AS fg; 
*/

-- 4) Сделать созданную файловую группу файловой группой по умолчанию.

ALTER DATABASE SKI_RENT
MODIFY FILEGROUP FG DEFAULT;
GO

/* USE SKI_RENT
SELECT
    fg.name AS DefaultFilegroup
FROM
    sys.filegroups fg
WHERE
    fg.is_default = 1;
GO
*/

-- 5) (*) Создать еще одну произвольную таблицу.

IF OBJECT_ID(N'RentalAgreement') IS NOT NULL
	DROP TABLE RentalAgreement;
GO

CREATE TABLE RentalAgreement
(
	AgreementID INT NOT NULL PRIMARY KEY,
    CustomerID INT NOT NULL,
    DateOfAgreement NVARCHAR(50) NOT NULL,
    RentalStartDate DATETIME NOT NULL,
    RentalEndDate DATETIME NOT NULL,
    TotalPrice DECIMAL(10, 2) NOT NULL

);
GO

--SELECT * FROM RentalAgreement

-- 6) (*) Удалить созданную вручную файловую группу.

ALTER DATABASE SKI_RENT
MODIFY FILEGROUP [primary] DEFAULT;
GO

DROP TABLE RentalAgreement;
GO

ALTER DATABASE SKI_RENT
REMOVE FILE new_file;
GO

ALTER DATABASE SKI_RENT
REMOVE FILEGROUP FG;
GO

/* SELECT 
    fg.name AS FileGroupName,
    fg.type_desc AS FileGroupType
FROM 
    sys.filegroups AS fg; 
*/


-- 7) Создать схему, переместить в нее одну из таблиц, удалить схему.

IF SCHEMA_ID(N'RSchema') IS NOT NULL
	DROP SCHEMA RSchema;
GO

CREATE SCHEMA RSchema;
GO

ALTER SCHEMA RSchema
	TRANSFER CUSTOMER;
GO

IF OBJECT_ID(N'RSchema.CUSTOMER') IS NOT NULL
	DROP TABLE RSchema.CUSTOMER;
GO

DROP SCHEMA RSchema;
