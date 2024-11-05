-- 1) Создать представление на основе одной из таблиц задания 6
USE lab6;
GO

DROP VIEW IF EXISTS Customer2024;
GO

-- Создание представления Customer2024 для отображения клиентов, заключивших контракт в 2024 году
CREATE VIEW Customer2024 AS
SELECT id, firstName, lastName, patronymic, contractDate
FROM Customer
WHERE YEAR(contractDate) = 2024;
GO

-- Проверка работы представления
SELECT * FROM Customer2024;
GO

-- 2) Создать представление на основе полей обеих связанных таблиц задания 6
USE lab6;
GO

DROP VIEW IF EXISTS RentalWithEquipmentPrice;
GO
-- Создание представления RentalWithEquipmentPrice на основе связанных таблиц Rental и EquipmentType
CREATE VIEW RentalWithEquipmentPrice AS
SELECT 
    Rental.id AS RentalID,
    Rental.rentalDate,
    Rental.returnDate,
    Rental.equipmentTypeName,
    EquipmentType.price AS EquipmentPrice
FROM 
    Rental
JOIN 
    EquipmentType ON Rental.equipmentTypeName = EquipmentType.name;
GO

-- Проверка работы представления
SELECT * FROM RentalWithEquipmentPrice;
GO
-- ctrl shift r

-- 3) Создать индекс для одной из таблиц задания 6, включив в него дополнительные неключевые поля.
USE lab6;
GO

-- Создание индекса для таблицы Customer
CREATE INDEX IDX_Customer_LastName ON Customer(lastName)
INCLUDE (firstName, contractDate);
GO

-- Проверка создания индекса
-- Используйте запрос, чтобы посмотреть, как индекс влияет на выполнение выборки
SELECT id, firstName, lastName, contractDate 
FROM Customer
WHERE lastName = 'Иванова';
GO

-- 4) Создать индексированное представление.

USE lab6;
GO

-- Удаляем представление, если оно уже существует
DROP VIEW IF EXISTS RentalWithEquipmentPrice;
GO

-- Создаём представление, которое соответствует требованиям для индексированных представлений
CREATE VIEW RentalWithEquipmentPrice
WITH SCHEMABINDING -- Требование для индексированных представлений
AS
SELECT 
    Rental.id AS RentalID,
    Rental.rentalDate,
    Rental.returnDate,
    Rental.equipmentTypeName,
    EquipmentType.price AS EquipmentPrice
FROM 
    dbo.Rental AS Rental
JOIN 
    dbo.EquipmentType AS EquipmentType ON Rental.equipmentTypeName = EquipmentType.name;
GO

-- Создание кластерного индекса для индексированного представления
CREATE UNIQUE CLUSTERED INDEX IDX_RentalWithEquipmentPrice ON RentalWithEquipmentPrice(RentalID);
GO

-- Проверка работы индексированного представления
SELECT * FROM RentalWithEquipmentPrice;
GO
