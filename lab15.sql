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



USE lab13db1;
GO

DROP TABLE IF EXISTS CLIENT;
GO

CREATE TABLE CLIENT (
    client_id INT IDENTITY(1, 1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) UNIQUE NOT NULL,
    max_rentals TINYINT DEFAULT 3 
);
GO

DROP TABLE IF EXISTS RENTAL;
GO

CREATE TABLE RENTAL (
    rental_id INT IDENTITY(1, 1) PRIMARY KEY,
    client_id INT NOT NULL,
    equipment_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    FOREIGN KEY (client_id) REFERENCES CLIENT(client_id)
);
GO



USE lab13db2;
GO

DROP TABLE IF EXISTS EQUIPMENT_ITEM;
GO

CREATE TABLE EQUIPMENT_ITEM (
    equipment_id INT IDENTITY(1, 1) PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    serial_number NVARCHAR(20) UNIQUE NOT NULL,
    category NVARCHAR(20) NOT NULL CHECK (category IN ('ski', 'snowboard', 'boots')), 
    status NVARCHAR(10) DEFAULT 'available' CHECK (status IN ('available', 'rented')) 
);
GO

-- 4) Триггеры в базе данных lab13db1

USE lab13db1;
GO

-- Ограничение на максимальное количество аренд у клиента
CREATE TRIGGER OnInsertRental
ON RENTAL
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @client_id INT, @equipment_id INT, @start_date DATE;

    SELECT @client_id = client_id, @equipment_id = equipment_id, @start_date = start_date
    FROM inserted;

    -- Проверка существования клиента
    IF NOT EXISTS (SELECT 1 FROM CLIENT WHERE client_id = @client_id)
        RAISERROR('Клиент не найден.', 11, 1);

    -- Проверка доступности снаряжения
    IF NOT EXISTS (SELECT 1 FROM lab13db2.dbo.EQUIPMENT_ITEM WHERE equipment_id = @equipment_id AND status = 'available')
        RAISERROR('Снаряжение недоступно для аренды.', 11, 1);

    -- Проверка текущего количества аренд у клиента
    DECLARE @current_rentals INT;
    SELECT @current_rentals = COUNT(*)
    FROM RENTAL
    WHERE client_id = @client_id AND end_date IS NULL;

    DECLARE @max_rentals TINYINT;
    SELECT @max_rentals = max_rentals FROM CLIENT WHERE client_id = @client_id;

    IF @current_rentals >= @max_rentals
        RAISERROR('Превышено максимальное количество аренд для клиента.', 11, 1);

    -- Добавление аренды
    INSERT INTO RENTAL (client_id, equipment_id, start_date)
    VALUES (@client_id, @equipment_id, @start_date);

    -- Обновление статуса снаряжения
    UPDATE lab13db2.dbo.EQUIPMENT_ITEM
    SET status = 'rented'
    WHERE equipment_id = @equipment_id;
END;
GO

-- Триггер для завершения аренды
CREATE TRIGGER OnUpdateRental
ON RENTAL
INSTEAD OF UPDATE
AS
BEGIN
    DECLARE @rental_id INT, @end_date DATE;

    SELECT @rental_id = rental_id, @end_date = end_date
    FROM inserted;

    -- Завершение аренды
    UPDATE RENTAL
    SET end_date = @end_date
    WHERE rental_id = @rental_id;

    -- Обновление статуса снаряжения
    DECLARE @equipment_id INT;
    SELECT @equipment_id = equipment_id FROM RENTAL WHERE rental_id = @rental_id;

    UPDATE lab13db2.dbo.EQUIPMENT_ITEM
    SET status = 'available'
    WHERE equipment_id = @equipment_id;
END;
GO

-- 5) Представление для удобства работы

USE lab13db1;
GO

DROP VIEW IF EXISTS RENTAL_VIEW;
GO

CREATE VIEW RENTAL_VIEW AS
SELECT
    C.name AS client_name,
    C.email AS client_email,
    E.name AS equipment_name,
    E.serial_number AS equipment_serial,
    R.start_date,
    R.end_date
FROM RENTAL R
JOIN CLIENT C ON R.client_id = C.client_id
JOIN lab13db2.dbo.EQUIPMENT_ITEM E ON R.equipment_id = E.equipment_id;
GO

-- 6) Тестовые данные

USE lab13db1;
GO

INSERT INTO CLIENT (name, email) VALUES 
('Иван Иванов', 'ivan@gmail.com'),
('Анна Смирнова', 'anna@gmail.com');

USE lab13db2;
GO

INSERT INTO EQUIPMENT_ITEM (name, serial_number, category) VALUES 
('Лыжи Atomic', 'SN12345', 'ski'),
('Сноуборд Burton', 'SN54321', 'snowboard'),
('Ботинки Salomon', 'SN67890', 'boots');
GO

-- Добавление аренды
USE lab13db1;
GO

INSERT INTO RENTAL (client_id, equipment_id, start_date)
VALUES (1, 1, '2024-06-23');
GO

-- Просмотр данных
SELECT * FROM RENTAL_VIEW;
GO

