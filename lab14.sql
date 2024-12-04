
USE lab13db1;
GO


IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO


CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL,
	SerialNumber CHAR(17) NOT NULL CHECK (LEN(SerialNumber) = 17),
	Model NVARCHAR(50) NOT NULL CHECK (LEN(Model) > 1),
	RentalPrice DECIMAL(10, 2) NOT NULL
);
GO


USE lab13db2;
GO


IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO


CREATE TABLE Equipment
(
	EquipmentID INT PRIMARY KEY NOT NULL,
	AvailabilityStatus NVARCHAR(50) NOT NULL,
	ProductionDate SMALLDATETIME NOT NULL
);
GO


IF OBJECT_ID(N'EquipmentView') IS NOT NULL
	DROP VIEW EquipmentView;
GO


CREATE VIEW EquipmentView AS
SELECT 
    first.EquipmentID, 
    first.SerialNumber, 
    first.Model, 
    first.RentalPrice, 
    second.AvailabilityStatus, 
    second.ProductionDate
FROM lab13db1.dbo.Equipment AS first
JOIN lab13db2.dbo.Equipment AS second
ON first.EquipmentID = second.EquipmentID;
GO


IF OBJECT_ID(N'trg_Insert_EquipmentView') IS NOT NULL
	DROP TRIGGER trg_Insert_EquipmentView;
GO


CREATE TRIGGER trg_Insert_EquipmentView ON EquipmentView
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO lab13db1.dbo.Equipment (EquipmentID, SerialNumber, Model, RentalPrice)
    SELECT EquipmentID, SerialNumber, Model, RentalPrice FROM inserted;

    INSERT INTO lab13db2.dbo.Equipment (EquipmentID, AvailabilityStatus, ProductionDate)
    SELECT EquipmentID, AvailabilityStatus, ProductionDate FROM inserted;
END;
GO


INSERT INTO EquipmentView (EquipmentID, SerialNumber, Model, RentalPrice, AvailabilityStatus, ProductionDate) 
VALUES 
(1, 'SN123456789012345', 'Ski Poles', 150.00, 'Available', '2022-12-01'),
(2, 'SN123456789012346', 'Snowboard', 300.00, 'Rented', '2021-05-01'),
(3, 'SN123456789012347', 'Ski Boots', 200.00, 'Available', '2023-01-15'),
(4, 'SN123456789012348', 'Helmet', 50.00, 'Available', '2020-11-20'),
(5, 'SN123456789012349', 'Gloves', 25.00, 'Unavailable', '2021-02-10'),
(6, 'SN123456789012350', 'Goggles', 75.00, 'Available', '2019-12-15'),
(7, 'SN123456789012351', 'Snowmobile', 1000.00, 'Rented', '2023-03-01'),
(8, 'SN123456789012352', 'Skis', 500.00, 'Available', '2022-10-10'),
(9, 'SN123456789012353', 'Ice Skates', 120.00, 'Available', '2023-06-15');
GO


-- Проверка данных
SELECT * FROM EquipmentView ORDER BY EquipmentID;
SELECT * FROM lab13db1.dbo.Equipment;
SELECT * FROM lab13db2.dbo.Equipment;
GO

-- Удаление триггера на обновление, если он существует
IF OBJECT_ID(N'trg_Update_EquipmentView') IS NOT NULL
	DROP TRIGGER trg_Update_EquipmentView;
GO

-- Создание триггера на обновление
CREATE TRIGGER trg_Update_EquipmentView ON EquipmentView
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(EquipmentID)
    BEGIN
        RAISERROR('Изменение EquipmentID запрещено.', 16, 1);
    END
    ELSE
    BEGIN
        UPDATE lab13db1.dbo.Equipment
        SET SerialNumber = inserted.SerialNumber, 
            Model = inserted.Model, 
            RentalPrice = inserted.RentalPrice
        FROM lab13db1.dbo.Equipment AS first
        INNER JOIN inserted ON first.EquipmentID = inserted.EquipmentID;

        UPDATE lab13db2.dbo.Equipment
        SET AvailabilityStatus = inserted.AvailabilityStatus, 
            ProductionDate = inserted.ProductionDate
        FROM lab13db2.dbo.Equipment AS second
        INNER JOIN inserted ON second.EquipmentID = inserted.EquipmentID;
    END
END;
GO


UPDATE EquipmentView
SET Model = 'Updated Model', RentalPrice = 200.00
WHERE EquipmentID = 1;
GO


SELECT * FROM EquipmentView ORDER BY EquipmentID;
GO


IF OBJECT_ID(N'trg_Delete_EquipmentView') IS NOT NULL
	DROP TRIGGER trg_Delete_EquipmentView;
GO


CREATE TRIGGER trg_Delete_EquipmentView ON EquipmentView
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM lab13db1.dbo.Equipment
    WHERE EquipmentID IN (SELECT EquipmentID FROM deleted);

    DELETE FROM lab13db2.dbo.Equipment
    WHERE EquipmentID IN (SELECT EquipmentID FROM deleted);
END;
GO


DELETE FROM EquipmentView WHERE EquipmentID = 2;
GO


SELECT * FROM EquipmentView;
SELECT * FROM lab13db1.dbo.Equipment;
SELECT * FROM lab13db2.dbo.Equipment;
GO
