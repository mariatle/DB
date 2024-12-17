USE lab13db1
GO

-- Удаление таблицы EquipmentType, если она существует
IF OBJECT_ID(N'EquipmentType') IS NOT NULL
    DROP TABLE EquipmentType;
GO

-- Создание таблицы типов снаряжения
CREATE TABLE EquipmentType (
    Name NVARCHAR(100) PRIMARY KEY NOT NULL,
    Description NVARCHAR(500)
);
GO

USE lab13db2
GO

-- Удаление таблицы RentalService, если она существует
IF OBJECT_ID(N'RentalService') IS NOT NULL
    DROP TABLE RentalService;
GO

-- Создание таблицы сервисов аренды
CREATE TABLE RentalService (
    ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Name NVARCHAR(100) NOT NULL,
    StartTime SMALLDATETIME NOT NULL DEFAULT GETDATE(),
    EndTime SMALLDATETIME NULL,
    Cost FLOAT NULL,
    DurationHours FLOAT NULL
);
GO

-- Создание представления для работы с данными обеих таблиц
IF OBJECT_ID(N'RentalServiceView') IS NOT NULL
    DROP VIEW RentalServiceView;
GO

CREATE VIEW RentalServiceView AS
    SELECT r.ID, r.Name, e.Description, r.StartTime, r.EndTime, r.Cost, r.DurationHours
    FROM RentalService AS r
    INNER JOIN lab13db1.dbo.EquipmentType AS e ON r.Name = e.Name;
GO

SELECT * FROM RentalServiceView;
GO

USE lab13db1
GO

-- Удаление и создание триггеров для таблицы EquipmentType
IF OBJECT_ID(N'EquipmentType_delete_trg') IS NOT NULL
    DROP TRIGGER EquipmentType_delete_trg;
GO

IF OBJECT_ID(N'EquipmentType_update_trg') IS NOT NULL
    DROP TRIGGER EquipmentType_update_trg;
GO

CREATE TRIGGER EquipmentType_delete_trg ON EquipmentType
FOR DELETE AS
    DELETE rental 
    FROM lab13db2.dbo.RentalService AS rental
    INNER JOIN deleted ON rental.Name = deleted.Name;
GO

CREATE TRIGGER EquipmentType_update_trg ON EquipmentType
FOR UPDATE AS 
    IF UPDATE(Name)
    BEGIN
        RAISERROR('Нельзя изменять название типа снаряжения.', 16, 1);
        ROLLBACK;
    END;
GO

USE lab13db2
GO

-- Удаление и создание триггеров для таблицы RentalService
IF OBJECT_ID(N'RentalService_insert_trg') IS NOT NULL
    DROP TRIGGER RentalService_insert_trg;
GO

IF OBJECT_ID(N'RentalService_update_trg') IS NOT NULL
    DROP TRIGGER RentalService_update_trg;
GO

CREATE TRIGGER RentalService_update_trg ON RentalService
FOR UPDATE AS 
    IF UPDATE(Name) AND 
        EXISTS (
            SELECT 1 
            FROM lab13db1.dbo.EquipmentType AS e 
            RIGHT JOIN inserted ON inserted.Name = e.Name 
            WHERE e.Name IS NULL
        )
    BEGIN
        RAISERROR('Тип снаряжения должен существовать.', 16, 1);
        ROLLBACK;
    END;
GO

CREATE TRIGGER RentalService_insert_trg ON RentalService
FOR INSERT AS
    IF EXISTS (
        SELECT 1 
        FROM lab13db1.dbo.EquipmentType AS e 
        RIGHT JOIN inserted ON inserted.Name = e.Name 
        WHERE e.Name IS NULL
    )
    BEGIN
        RAISERROR('Тип снаряжения должен существовать при добавлении записи.', 16, 1);
        ROLLBACK;
    END;
GO

USE lab13db1
GO

-- Добавление данных в таблицу EquipmentType
INSERT INTO EquipmentType VALUES
(N'Горные лыжи', N'Профессиональные горные лыжи для проката'),
(N'Сноуборд', N'Сноуборд с креплениями для начинающих'),
(N'Шлем', N'Горнолыжный шлем повышенной прочности');
GO

SELECT * FROM EquipmentType;
GO

USE lab13db2
GO

-- Добавление данных в таблицу RentalService
INSERT INTO RentalService (Name, Cost, DurationHours) VALUES
(N'Горные лыжи', 50.0, 4.0),
(N'Сноуборд', 60.0, 5.0);
GO

SELECT * FROM RentalServiceView;
GO

-- Проверка триггеров EquipmentType
UPDATE lab13db1.dbo.EquipmentType SET Name = N'Обновлённое название' WHERE Name = N'Горные лыжи';
GO

UPDATE lab13db1.dbo.EquipmentType SET Description = N'Обновлённое описание' WHERE Name = N'Горные лыжи';
GO

SELECT * FROM RentalServiceView;
GO

DELETE FROM lab13db1.dbo.EquipmentType WHERE Name = N'Горные лыжи';
GO

SELECT * FROM RentalServiceView;
GO

-- Проверка триггеров RentalService
INSERT INTO RentalService (Name, Cost, DurationHours) VALUES
(N'Несуществующее снаряжение', 30.0, 2.0),
(N'Шлем', 20.0, 2.0);
GO

SELECT * FROM RentalService;
GO

UPDATE RentalService SET Name = N'Сноуборд' WHERE Name = N'Шлем';
GO

SELECT * FROM lab13db1.dbo.EquipmentType;
GO

SELECT * FROM RentalServiceView;
GO

UPDATE RentalService SET Name = N'Шлем' WHERE ID = 2;
GO

SELECT * FROM RentalServiceView;
GO
