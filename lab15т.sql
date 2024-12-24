USE lab13db1
go

IF OBJECT_ID(N'TypeOfCustomer') IS NOT NULL
	DROP TABLE TypeOfCustomer;
go

CREATE TABLE TypeOfCustomer(
	Name NVarChar(100) PRIMARY KEY NOT NULL,
	Description NVarChar(500),
);

USE lab13db2
go

IF OBJECT_ID(N'Customer') IS NOT NULL
	DROP TABLE Customer;
go

CREATE TABLE Customer(
	ID INT IDENTITY(1,1) PRIMARY KEY  NOT NULL, 
	Name NVarChar(100) NOT NULL,
	StartTime SmallDateTime NOT NULL DEFAULT GETDATE(),
	EndTime SmallDateTime NULL,
	Coef FLOAT NULL,
	HoursOfRent FLOAT NULL,
);
go

-- 2. Создать необходимые элементы базы данных (представления, триггеры), обеспечивающие работу
-- с данными связанных таблиц (выборку, вставку, изменение, удаление).

IF OBJECT_ID(N'CustomerView') IS NOT NULL
	DROP VIEW CustomerView;
go

CREATE VIEW CustomerView AS
	SELECT f.ID, f.Name, s.Description, f.StartTime, f.EndTime, f.Coef, f.HoursOfRent FROM Customer as f INNER JOIN lab13db1.dbo.TypeOfCustomer as s ON f.Name = s.Name
go

USE lab13db1
go

IF OBJECT_ID(N'Type_delete_trg') IS NOT NULL
	DROP TRIGGER Type_delete_trg;
go

IF OBJECT_ID(N'Type_update_trg') IS NOT NULL
	DROP TRIGGER Type_update_trg;
go


CREATE TRIGGER Type_delete_trg ON TypeOfCustomer
FOR DELETE AS
	DELETE Customer FROM lab13db2.dbo.Customer AS Customer
		INNER JOIN deleted ON Customer.Name= deleted.Name
GO

CREATE TRIGGER Type_update_trg ON TypeOfCustomer
FOR UPDATE AS 
	IF UPDATE(Name)
	BEGIN
        RAISERROR('Нельзя менять название у созданного типа работы', 16, 1);
		ROLLBACK;
    END
go

USE lab13db2
go


IF OBJECT_ID(N'Customer_insert_trg') IS NOT NULL
	DROP TRIGGER Customer_insert_trg;
go

IF OBJECT_ID(N'Customer_update_trg') IS NOT NULL
	DROP TRIGGER Customer_update_trg;
go


CREATE TRIGGER Customer_update_trg ON Customer
FOR UPDATE AS 
	IF UPDATE(Name) AND 
		EXISTS (SELECT 1 FROM lab13db1.dbo.TypeOfCustomer as type RIGHT JOIN inserted ON inserted.Name = type.Name WHERE type.Name IS NULL) -- фикс
	BEGIN
        RAISERROR('При обновлении необходимо выбрать существующий тип работы', 16, 1);
		ROLLBACK;
    END
go

CREATE TRIGGER Customer_insert_trg ON Customer
FOR INSERT AS
	IF EXISTS (SELECT 1 FROM lab13db1.dbo.TypeOfCustomer as type RIGHT JOIN inserted ON inserted.Name = type.Name WHERE type.Name IS NULL) -- фикс
	BEGIN
		RAISERROR('При вставке необходимо выбрать существующий тип работы', 16, 1);
		ROLLBACK;
	END
GO

USE lab13db1
go

INSERT INTO TypeOfCustomer VALUES
(N'Прокат лыж', N'Аренда комплекта лыж для катания по трассе'),
(N'Прокат сноуборда', N'Замена масла на масло Castrol'),
(N'Прокат горнолыжных ботинок', N'Аренда ботинок для лыжных комплексов')
go


SELECT * FROM TypeOfCustomer;
go

USE lab13db2
go

INSERT INTO Customer (Name, Coef, HoursOfRent) VALUES
(N'Прокат лыж', 1, 2.0),
(N'Прокат сноуборда', 2, 2.0);
go

SELECT * FROM CustomerView;
go

--проверка триггеров TypeOfCustomer
UPDATE lab13db1.dbo.TypeOfCustomer SET Name = N'Обновлённое название' WHERE Name = N'Прокат лыж';
go

UPDATE lab13db1.dbo.TypeOfCustomer SET Description = N'Обновлённое описание' WHERE Name = N'Прокат лыж';
go

SELECT * FROM CustomerView;
go

DELETE FROM lab13db1.dbo.TypeOfCustomer WHERE Name = N'Прокат лыж';
go

SELECT * FROM CustomerView;
go

--проверка триггеров Customer
INSERT INTO Customer (Name, Coef, HoursOfRent) VALUES
(N'Несуществующее название', 1, 2.0),
(N'Прокат горнолыжных ботинок', 1, 2.0);
go -- это ломает

SELECT * FROM Customer;
go

UPDATE Customer SET Name = N'Прокат сноуборда' WHERE Name = N'Прокат горнолыжных ботинок';
go

SELECT * FROM lab13db1.dbo.TypeOfCustomer;
go

SELECT * FROM CustomerView;
go

UPDATE Customer SET Name = N'Прокат горнолыжных ботинок' WHERE ID = 2;
go

SELECT * FROM CustomerView;
go

