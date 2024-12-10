USE master;
GO

-- Удаление базы данных, если она существует
IF DB_ID(N'lab11') IS NOT NULL
    DROP DATABASE lab11;
GO

-- Создание новой базы данных
CREATE DATABASE lab11
ON
(
    NAME = lab11,
    FILENAME = 'D:\lab11.mdf',
    SIZE = 10,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
);
GO

USE lab11;
GO

-- Создание таблицы Client
CREATE TABLE Client (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    phone_number VARCHAR(15) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) DEFAULT 'Не указано',  -- Значение по умолчанию
    email VARCHAR(100) UNIQUE -- Ограничение UNIQUE для поля email
);

-- Заполнение таблицы Client
INSERT INTO Client (phone_number, first_name, last_name, middle_name, email)
VALUES
('9876543210', 'Анна', 'Смирнова', 'Петровна', 'anna.smirnova@example.com'),
('8765432109', 'Олег', 'Кузнецов', '',  'oleg.kuznetsov@example.com');
GO

-- Создание таблицы Rental_Agreement
CREATE TABLE Rental_Agreement (
    agreement_id INT PRIMARY KEY IDENTITY(1,1),
    client_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    agreement_date DATE NOT NULL DEFAULT GETDATE(),  -- Значение по умолчанию
    total_cost DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (client_id) REFERENCES Client(client_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Заполнение таблицы Rental_Agreement
INSERT INTO Rental_Agreement (client_id, start_date, end_date, agreement_date, total_cost)
VALUES
(1, '2024-12-20', '2024-12-25', '2024-12-20', 500.00), 
(2, '2024-12-22', '2024-12-27', '2024-12-22', 600.00);
GO

-- Создание таблицы Equipment
CREATE TABLE Equipment (
    equipment_id INT PRIMARY KEY IDENTITY(1,1),
    equipment_name VARCHAR(100) NOT NULL,
    equipment_type VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(50),
    model VARCHAR(50),
    rental_cost DECIMAL(10, 2) NOT NULL
);

-- Заполнение таблицы Equipment
INSERT INTO Equipment (equipment_name, equipment_type, manufacturer, model, rental_cost)
VALUES
('Лыжи', 'Горнолыжное снаряжение', 'Rossignol', 'Hero Elite', 300.00),
('Лыжные ботинки', 'Горнолыжное снаряжение', 'Salomon', 'X-Pro 120', 200.00),
('Палки лыжные', 'Горнолыжное снаряжение', 'Leki', 'Carbon 14', 100.00);
GO

-- Создание таблицы Instance
CREATE TABLE Instance (
    instance_id INT PRIMARY KEY IDENTITY(1,1),
    inventory_number VARCHAR(50) NOT NULL UNIQUE,  -- Ограничение UNIQUE
    size VARCHAR(20),
    condition VARCHAR(50),
    equipment_id INT NOT NULL,
    FOREIGN KEY (equipment_id) REFERENCES Equipment(equipment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Заполнение таблицы Instance
INSERT INTO Instance (inventory_number, size, condition, equipment_id)
VALUES
('SKI001', '175 см', 'Новое', 1), 
('SKI002', '180 см', 'Хорошее', 1), 
('BOOT001', '42', 'Новое', 2), 
('BOOT002', '44', 'Хорошее', 2), 
('POLE001', '120 см', 'Новое', 3), 
('POLE002', '125 см', 'Хорошее', 3);
GO

-- Создание таблицы Rental_Instance
CREATE TABLE Rental_Instance (
    rental_id INT NOT NULL,
    instance_id INT NOT NULL,
    PRIMARY KEY (rental_id, instance_id),
    FOREIGN KEY (rental_id) REFERENCES Rental_Agreement(agreement_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (instance_id) REFERENCES Instance(instance_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Заполнение таблицы Rental_Instance
INSERT INTO Rental_Instance (rental_id, instance_id)
VALUES
(1, 1), 
(1, 3), 
(1, 5), 
(2, 2), 
(2, 4), 
(2, 6);
GO

-- Создание индекса на поле client_id в таблице Rental_Agreement
CREATE INDEX idx_client_id ON Rental_Agreement(client_id);
GO

-- Создание индекса на поле equipment_id в таблице Instance
CREATE INDEX idx_equipment_id ON Instance(equipment_id);
GO

-- Создание хранимой процедуры для вычисления общей стоимости аренды
CREATE PROCEDURE CalculateTotalRentalCost
    @agreement_id INT
AS
BEGIN
    DECLARE @total_cost DECIMAL(10,2);
    
    -- Расчет общей стоимости аренды на основе арендуемых экземпляров
    SELECT @total_cost = SUM(e.rental_cost)
    FROM Rental_Instance ri
    JOIN Instance i ON ri.instance_id = i.instance_id
    JOIN Equipment e ON i.equipment_id = e.equipment_id
    WHERE ri.rental_id = @agreement_id;
    
    -- Обновление стоимости аренды в таблице Rental_Agreement
    UPDATE Rental_Agreement
    SET total_cost = @total_cost
    WHERE agreement_id = @agreement_id;
END;
GO

-- Создание триггера для обновления стоимости аренды при добавлении или удалении экземпляров
CREATE TRIGGER trg_UpdateRentalCost
ON Rental_Instance
AFTER INSERT, DELETE
AS
BEGIN
    DECLARE @rental_id INT;

    -- Получение rental_id из таблицы inserted
    SELECT @rental_id = rental_id FROM inserted;

    -- Вызов процедуры для пересчета стоимости аренды
    EXEC CalculateTotalRentalCost @rental_id;
END;
GO

-- Создание представления для отображения информации о клиентах и их арендах
CREATE VIEW ClientRentalInfo AS
SELECT c.client_id, c.first_name, c.last_name, c.phone_number, ra.agreement_id, ra.start_date, ra.end_date, ra.total_cost
FROM Client c
JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO

-- 1. Запросы для выборки записей (SELECT)

-- Выборка всех клиентов с их договорами аренды
SELECT 
    c.client_id, 
    c.first_name, 
    c.last_name, 
    c.phone_number, 
    ra.agreement_id, 
    ra.start_date, 
    ra.end_date, 
    ra.total_cost
FROM 
    Client c
JOIN 
    Rental_Agreement ra ON c.client_id = ra.client_id;

-- Выборка всех арендуемых экземпляров с их состоянием и оборудованием
SELECT 
    i.inventory_number, 
    i.size, 
    i.condition, 
    e.equipment_name, 
    ra.start_date, 
    ra.end_date, 
    ra.total_cost
FROM 
    Instance i
JOIN 
    Equipment e ON i.equipment_id = e.equipment_id
JOIN 
    Rental_Instance ri ON i.instance_id = ri.instance_id
JOIN 
    Rental_Agreement ra ON ri.rental_id = ra.agreement_id;

-- 2. Запросы для добавления новых записей (INSERT)

-- Добавление нового клиента
INSERT INTO Client (phone_number, first_name, last_name, middle_name, email)
VALUES 
('9123456789', 'Ирина', 'Петрова', 'Александровна', 'irina.petrovа@example.com');

-- Добавление нового договора аренды на основе данных из существующего клиента
INSERT INTO Rental_Agreement (client_id, start_date, end_date, agreement_date, total_cost)
SELECT client_id, '2024-12-30', '2024-12-31', GETDATE(), 450.00
FROM Client
WHERE email = 'irina.petrovа@example.com';

-- 3. Запросы для модификации записей (UPDATE)

-- Обновление информации о клиенте (например, изменение номера телефона)
UPDATE Client
SET phone_number = '9998887776'
WHERE client_id = 1;

-- Обновление стоимости аренды в таблице Rental_Agreement
UPDATE Rental_Agreement
SET total_cost = 550.00
WHERE agreement_id = 1;

-- 4. Запросы для удаления записей (DELETE)

-- Удаление клиента и его записей из таблицы Rental_Agreement (с использованием ON DELETE CASCADE)
DELETE FROM Client
WHERE client_id = 2;

-- Удаление экземпляра с его связями в Rental_Instance и Instance
DELETE FROM Instance
WHERE instance_id = 3;
GO

