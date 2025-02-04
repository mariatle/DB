USE master
GO

IF DB_ID (N'lab9') IS NOT NULL
	DROP DATABASE lab9;
GO

CREATE DATABASE lab9
ON
(
	NAME = lab9,
	FILENAME = 'D:\lab9.mdf',
	SIZE = 10,
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 5%
)

USE lab9;
GO

IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO

CREATE TABLE Equipment
(
    EquipmentID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    Name NVARCHAR(50) NOT NULL, 
    Size NVARCHAR(10) NOT NULL, 
    PricePerHour FLOAT NOT NULL, 
    Condition NVARCHAR(20) NOT NULL CHECK (Condition IN ('Excellent', 'Good', 'Fair', 'Poor')), 
    IsAvailable BIT NOT NULL DEFAULT 1 
);

INSERT INTO Equipment (Name, Size, PricePerHour, Condition, IsAvailable) VALUES
('Ski Set - Advanced', '175 cm', 25.0, 'Excellent', 1),
('Ski Set - Beginner', '150 cm', 20.0, 'Good', 1),
('Snowboard', '160 cm', 22.5, 'Excellent', 1),
('Ski Boots', '42 EU', 10.0, 'Good', 1),
('Ski Boots', '38 EU', 10.0, 'Fair', 1),
('Ski Poles', '120 cm', 5.0, 'Good', 1),
('Helmet', 'M', 7.5, 'Excellent', 1),
('Helmet', 'L', 7.5, 'Good', 0), -- Недоступно для аренды
('Goggles', 'One Size', 5.0, 'Excellent', 1),
('Jacket', 'L', 15.0, 'Fair', 1),
('Pants', 'M', 12.0, 'Good', 1);

SELECT * FROM Equipment

IF OBJECT_ID(N'Rental') IS NOT NULL
	DROP TABLE Rental;
GO


CREATE TABLE Rental
(
    RentalID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    EquipmentID INT NOT NULL FOREIGN KEY REFERENCES Equipment(EquipmentID) ON DELETE CASCADE,
    CustomerName NVARCHAR(50) NOT NULL, 
    StartTime SmallDateTime NOT NULL DEFAULT GETDATE(), 
    EndTime SmallDateTime NULL, 
    TotalPrice FLOAT NULL 
);
GO

INSERT INTO Rental (EquipmentID, CustomerName, StartTime, EndTime, TotalPrice) VALUES
(1, 'John Doe', '2024-12-01 09:00', '2024-12-01 13:00', 100.0),  
(2, 'Alice Smith', '2024-12-01 10:00', '2024-12-01 12:00', 40.0), 
(3, 'Bob Johnson', '2024-12-01 11:00', '2024-12-01 14:30', 67.5), 
(4, 'Mary Lee', '2024-12-01 09:30', '2024-12-01 11:30', 20.0),    
(6, 'Tom Hardy', '2024-12-01 14:00', '2024-12-01 16:30', 12.5),   
(9, 'Sarah Connor', '2024-12-01 15:00', '2024-12-01 17:00', 10.0); 
GO

-- Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, при
-- выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).

IF OBJECT_ID(N'trg_Insert_Equipment') IS NOT NULL
	DROP TRIGGER trg_Insert_Equipment;
IF OBJECT_ID(N'trg_Delete_Equipment') IS NOT NULL
	DROP TRIGGER trg_Delete_Equipment;
IF OBJECT_ID(N'trg_Update_Equipment') IS NOT NULL
	DROP TRIGGER trg_Update_Equipment;
GO

CREATE TRIGGER TRG_Equipment_Insert
ON Equipment
AFTER INSERT
AS
BEGIN
    -- Проверяем, если состояние "Poor" и оборудование недоступно
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Condition = 'Poor' AND IsAvailable = 0
    )
    BEGIN
        RAISERROR('Cannot insert equipment with "Poor" condition when it is not available for rental.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


IF OBJECT_ID(N'EquipmentLog') IS NULL
CREATE TABLE EquipmentLog (
    LogID INT IDENTITY(1,1),
    EquipmentID INT,
    EquipmentName NVARCHAR(50),
    DeletedAt DATETIME DEFAULT GETDATE()
);
GO



CREATE TRIGGER TRG_Equipment_Delete
ON Equipment
AFTER DELETE
AS
BEGIN
    -- Логируем удалённое оборудование
    INSERT INTO EquipmentLog (EquipmentID, EquipmentName)
    SELECT EquipmentID, Name
    FROM deleted;

    -- Проверяем, если удаляемое оборудование доступно для аренды
    IF EXISTS (
        SELECT 1
        FROM deleted
        WHERE IsAvailable = 1
    )
    BEGIN
        RAISERROR('Cannot delete equipment that is currently marked as available for rental.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE TRIGGER TRG_Equipment_Update
ON Equipment
AFTER UPDATE
AS
BEGIN
    -- Проверяем, если состояние обновлено на "Poor", а оборудование доступно
    IF EXISTS (
        SELECT 1
        FROM inserted
        INNER JOIN deleted ON inserted.EquipmentID = deleted.EquipmentID
        WHERE inserted.Condition = 'Poor' AND inserted.IsAvailable = 1 AND deleted.Condition != 'Poor'
    )
    BEGIN
        RAISERROR('Cannot set equipment to "Poor" condition while it is available for rental.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

INSERT INTO Equipment (Name, Size, PricePerHour, Condition, IsAvailable)
VALUES ('Test Equipment', 'One Size', 15.0, 'Good', 1);
GO

INSERT INTO Equipment (Name, Size, PricePerHour, Condition, IsAvailable)
VALUES ('Faulty Equipment', 'One Size', 15.0, 'Poor', 0);
GO

SELECT * FROM Rental
SELECT * FROM Equipment

DELETE FROM Equipment WHERE EquipmentID = 1;
GO

DELETE FROM Equipment WHERE EquipmentID = 8;
GO 

SELECT * FROM EquipmentLog;
GO


UPDATE Equipment
SET Condition = 'Good'
WHERE EquipmentID = 3;
GO


UPDATE Equipment
SET Condition = 'Poor'
WHERE EquipmentID = 3; -- IsAvailable = 1
GO


-- Для представления пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, обеспечивающие возможность выполнения
-- операций с данными непосредственно через представление.

IF OBJECT_ID(N'EquipmentWarranty') IS NOT NULL
    DROP TABLE EquipmentWarranty;
GO

CREATE TABLE EquipmentWarranty
(
    WarrantyID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    EquipmentID INT NOT NULL UNIQUE,  -- Уникальный индекс на EquipmentID для 1 к 1
    WarrantyStartDate DATE NOT NULL,
    WarrantyEndDate DATE NOT NULL,
    WarrantyDetails NVARCHAR(255) NULL,
    FOREIGN KEY (EquipmentID) REFERENCES Equipment(EquipmentID) ON DELETE CASCADE
);
GO

SELECT * FROM EquipmentWarranty
INSERT INTO EquipmentWarranty (EquipmentID, WarrantyStartDate, WarrantyEndDate, WarrantyDetails) VALUES
(1, '2024-11-01', '2025-11-01', N'1 year warranty covering manufacturing defects'),
(2, '2024-08-15', '2025-08-15', N'1 year warranty, repair parts included'),
(3, '2024-10-01', '2025-10-01', N'1 year warranty for product replacement'),
(4, '2024-12-01', '2025-12-01', N'1 year warranty covering defects'),
(5, '2024-12-01', '2025-12-01', N'1 year warranty covering defects');

GO


IF OBJECT_ID(N'EquipmentWithWarranty') IS NOT NULL
    DROP VIEW EquipmentWithWarranty;
GO


CREATE VIEW EquipmentWithWarranty AS
SELECT 
    e.EquipmentID,
    e.Name,
    e.Size,
    e.PricePerHour,
    e.Condition,
    e.IsAvailable,
    ew.WarrantyID,
    ew.WarrantyStartDate,
    ew.WarrantyEndDate,
    ew.WarrantyDetails
FROM 
    Equipment e
JOIN 
    EquipmentWarranty ew
    ON e.EquipmentID = ew.EquipmentID;
GO


SELECT * FROM EquipmentWithWarranty;

-- Триггеры для работы через представление EquipmentWithWarranty

IF OBJECT_ID(N'TRG_EquipmentWithWarranty_Insert') IS NOT NULL
    DROP TRIGGER TRG_EquipmentWithWarranty_Insert;
GO

CREATE TRIGGER TRG_EquipmentWithWarranty_Insert
ON EquipmentWithWarranty
INSTEAD OF INSERT
AS
BEGIN
    
    INSERT INTO Equipment (Name, Size, PricePerHour, Condition, IsAvailable)
    SELECT Name, Size, PricePerHour, Condition, IsAvailable
    FROM inserted;

    
    INSERT INTO EquipmentWarranty (EquipmentID, WarrantyStartDate, WarrantyEndDate, WarrantyDetails)
    SELECT e.EquipmentID, i.WarrantyStartDate, i.WarrantyEndDate, i.WarrantyDetails
    FROM inserted i
    JOIN Equipment e ON e.Name = i.Name AND e.Size = i.Size;
END;
GO

IF OBJECT_ID(N'TRG_EquipmentWithWarranty_Update') IS NOT NULL
    DROP TRIGGER TRG_EquipmentWithWarranty_Update;
GO

CREATE TRIGGER TRG_EquipmentWithWarranty_Update
ON EquipmentWithWarranty
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(EquipmentID)
	    BEGIN
		    RAISERROR('Изменение EquipmentID forbidden.', 16, 1);
		END
		ELSE
		BEGIN
            UPDATE Equipment
		SET 
			Name = i.Name, Size = i.Size, PricePerHour = i.PricePerHour,
			Condition = i.Condition, IsAvailable = i.IsAvailable
		FROM Equipment e
		INNER JOIN inserted i ON e.EquipmentID = i.EquipmentID;

    
		UPDATE EquipmentWarranty
		SET 
			WarrantyStartDate = i.WarrantyStartDate,
			WarrantyEndDate = i.WarrantyEndDate,
			WarrantyDetails = i.WarrantyDetails
		FROM EquipmentWarranty ew
		INNER JOIN inserted i ON ew.EquipmentID = i.EquipmentID;
	END
END;
GO
    

IF OBJECT_ID(N'TRG_EquipmentWithWarranty_Delete') IS NOT NULL
    DROP TRIGGER TRG_EquipmentWithWarranty_Delete;
GO

CREATE TRIGGER TRG_EquipmentWithWarranty_Delete
ON EquipmentWithWarranty
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM Equipment
    WHERE EquipmentID IN (SELECT EquipmentID FROM deleted);
END;
GO



-- Тест вставки через представление
INSERT INTO EquipmentWithWarranty (Name, Size, PricePerHour, Condition, IsAvailable, WarrantyStartDate, WarrantyEndDate, WarrantyDetails)
VALUES ('New Ski Set', '180 cm', 30.0, 'Excellent', 0, '2024-12-01', '2025-12-01', N'1-year full warranty');


SELECT * FROM Equipment WHERE Name = 'New Ski Set';
SELECT * FROM EquipmentWarranty WHERE EquipmentID = (SELECT EquipmentID FROM Equipment WHERE Name = 'New Ski Set');


-- Тест обновления через представление
UPDATE EquipmentWithWarranty
SET 
    PricePerHour = 35.0,
    Condition = 'Good',
    WarrantyDetails = N'Updated warranty details'
WHERE EquipmentID = 1;


SELECT * FROM Equipment WHERE EquipmentID = 1;
SELECT * FROM EquipmentWarranty WHERE EquipmentID = 1;



-- Тест удаления через представление
DELETE FROM EquipmentWithWarranty WHERE EquipmentID = 14;

SELECT * FROM EquipmentWithWarranty


SELECT * FROM Equipment WHERE EquipmentID = 14;
SELECT * FROM EquipmentWarranty WHERE EquipmentID = 14;

SELECT * FROM EquipmentWarranty
update EquipmentWarranty set WarrantyDetails=WarrantyDetails + 'x', EquipmentID=EquipmentID+1
SELECT * FROM EquipmentWarranty			

-- Проверка согласованности данных
SELECT e.EquipmentID, ew.EquipmentID
FROM Equipment e
FULL OUTER JOIN EquipmentWarranty ew ON e.EquipmentID = ew.EquipmentID
WHERE e.EquipmentID IS NULL OR ew.EquipmentID IS NULL;

-- Записи, которые есть в EquipmentWarranty, но отсутствуют в Equipment
SELECT 'Missing in Equipment' AS Issue, ew.EquipmentID
FROM EquipmentWarranty ew
LEFT JOIN Equipment e ON ew.EquipmentID = e.EquipmentID
WHERE e.EquipmentID IS NULL;

-- Записи, которые есть в Equipment, но отсутствуют в EquipmentWarranty
SELECT 'Missing in EquipmentWarranty' AS Issue, e.EquipmentID
FROM Equipment e
LEFT JOIN EquipmentWarranty ew ON e.EquipmentID = ew.EquipmentID
WHERE ew.EquipmentID IS NULL;

