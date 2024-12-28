USE lab13db1
GO

IF OBJECT_ID(N'EquipmentType') IS NOT NULL
	DROP TABLE EquipmentType;
GO

CREATE TABLE EquipmentType(
	Name NVarChar(100) PRIMARY KEY NOT NULL,
	Description NVarChar(500)
);
GO

USE lab13db2
GO

IF OBJECT_ID(N'EquipmentRental') IS NOT NULL
	DROP TABLE EquipmentRental;
GO

CREATE TABLE EquipmentRental(
	ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Name NVarChar(100) NOT NULL,
	StartTime SmallDateTime NOT NULL DEFAULT GETDATE(),
	EndTime SmallDateTime NULL,
	HoursRented FLOAT NULL
);
GO

-- Создание представления
IF OBJECT_ID(N'RentalView') IS NOT NULL
	DROP VIEW RentalView;
GO

CREATE VIEW RentalView AS
	SELECT r.ID, r.Name, e.Description, r.StartTime, r.EndTime, r.HoursRented 
	FROM EquipmentRental AS r 
	INNER JOIN lab13db1.dbo.EquipmentType AS e ON r.Name = e.Name;
GO

select * from RentalView

USE lab13db1
GO

-- Создание триггеров для таблицы EquipmentType
IF OBJECT_ID(N'EquipmentType_delete_trg') IS NOT NULL
	DROP TRIGGER EquipmentType_delete_trg;
GO

IF OBJECT_ID(N'EquipmentType_update_trg') IS NOT NULL
	DROP TRIGGER EquipmentType_update_trg;
GO


-- срабатывает при удалении записи из EquipmentType, удаляет все записи в таблице EquipmentRental где тип совп с удаляемым
CREATE TRIGGER EquipmentType_delete_trg ON EquipmentType
FOR DELETE AS
	DELETE rental 
	FROM lab13db2.dbo.EquipmentRental AS rental
	INNER JOIN deleted ON rental.Name = deleted.Name;
GO

CREATE TRIGGER EquipmentType_update_trg ON EquipmentType
FOR UPDATE AS
	IF UPDATE(Name)
	BEGIN
        RAISERROR('Название типа нельзя изменить!!!!!!!!!', 16, 1);
		ROLLBACK;
    END;
GO

USE lab13db2
GO

-- Создание триггеров для таблицы EquipmentRental
IF OBJECT_ID(N'EquipmentRental_insert_trg') IS NOT NULL
	DROP TRIGGER EquipmentRental_insert_trg;
GO

IF OBJECT_ID(N'EquipmentRental_update_trg') IS NOT NULL
	DROP TRIGGER EquipmentRental_update_trg;
GO


-- чек сущ-т ли указанный тип оборудования в таблице EquipmentType, если такого типа нет, то вставка откатывается.
CREATE TRIGGER EquipmentRental_insert_trg ON EquipmentRental
FOR INSERT AS
	IF EXISTS (SELECT 1 FROM lab13db1.dbo.EquipmentType AS type 
		RIGHT JOIN inserted ON inserted.Name = type.Name 
		WHERE type.Name IS NULL
	)
	BEGIN
		RAISERROR('При добавлении необходимо указать существующий тип оборудования.', 16, 1);
		ROLLBACK;
	END;
GO

-- если апд тип оборудования и он не сущ-т в таблице EquipmentType, операция откатывается
CREATE TRIGGER EquipmentRental_update_trg ON EquipmentRental
FOR UPDATE AS
	IF UPDATE(Name) AND EXISTS ( -- чек, была ли изменена колонка Name в таблице EquipmentRental, если апд, то true
			SELECT 1 
			FROM lab13db1.dbo.EquipmentType AS type 
			RIGHT JOIN inserted ON inserted.Name = type.Name   --все записи из inserted, для которых нет соответствующего типа оборудования в EquipmentType
			WHERE type.Name IS NULL
		)
	BEGIN
        RAISERROR('Обновление возможно только с существующим типом оборудования.', 16, 1);
		ROLLBACK;
    END;
GO

USE lab13db1
GO


INSERT INTO EquipmentType VALUES
(N'Горные лыжи', N'Комплект горных лыж с палками'),
(N'Сноуборд', N'Комплект сноуборда с креплениями и ботинками'),
(N'Шлем', N'Защитный шлем для зимних видов спорта');
GO

SELECT * FROM EquipmentType;
GO

USE lab13db2
GO


INSERT INTO EquipmentRental (Name, HoursRented) VALUES
(N'Горные лыжи', 4.0),
(N'Сноуборд', 3.0);
GO

SELECT * FROM RentalView;
GO


UPDATE lab13db1.dbo.EquipmentType 
SET Name = N'Обновлённое название' 
WHERE Name = N'Горные лыжи';
GO

UPDATE lab13db1.dbo.EquipmentType 
SET Description = N'Обновлённое описание' 
WHERE Name = N'Горные лыжи';
GO

DELETE FROM lab13db1.dbo.EquipmentType 
WHERE Name = N'Горные лыжи';
GO

SELECT * FROM RentalView;
GO

-- Проверка триггеров EquipmentRental
INSERT INTO EquipmentRental (Name, HoursRented) VALUES
(N'Кринж название', 2.0),
(N'Шлем', 1.0);
GO

SELECT * FROM EquipmentRental;
GO

UPDATE EquipmentRental 
SET Name = N'Шлем' 
WHERE Name = N'Сноуборд';
GO

SELECT * FROM lab13db1.dbo.EquipmentType;
GO

SELECT * FROM RentalView;
GO

UPDATE EquipmentRental 
SET Name = N'Амням' 
WHERE ID = 2;
GO

select * from EquipmentRental
SELECT * FROM lab13db1.dbo.EquipmentType;


UPDATE EquipmentRental 
SET Name = N'Шлем' 
WHERE ID = 2;
GO

SELECT * FROM RentalView;
GO
