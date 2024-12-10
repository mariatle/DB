-- Инициализация базы данных
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

-- Создание и заполнение таблиц
-- Таблица Client
CREATE TABLE Client (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    phone_number VARCHAR(15) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) DEFAULT 'Не указано',  
    email VARCHAR(100) UNIQUE 
);
GO

INSERT INTO Client (phone_number, first_name, last_name, middle_name, email)
VALUES
('9876543210', 'Анна', 'Смирнова', 'Петровна', 'anna.smirnova@example.com'),
('8765432109', 'Олег', 'Кузнецов', '',  'oleg.kuznetsov@example.com');
GO

-- Таблица Rental_Agreement
CREATE TABLE Rental_Agreement (
    agreement_id INT PRIMARY KEY IDENTITY(1,1),
    client_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    agreement_date DATE NOT NULL DEFAULT GETDATE(),
    total_cost DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (client_id) REFERENCES Client(client_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

INSERT INTO Rental_Agreement (client_id, start_date, end_date, agreement_date, total_cost)
VALUES
(1, '2024-12-20', '2024-12-25', '2024-12-20', 500.00), 
(2, '2024-12-22', '2024-12-27', '2024-12-22', 600.00);
GO

-- Таблица Equipment
CREATE TABLE Equipment (
    equipment_id INT PRIMARY KEY IDENTITY(1,1),
    equipment_name VARCHAR(100) NOT NULL,
    equipment_type VARCHAR(50) NOT NULL,
    manufacturer VARCHAR(50),
    model VARCHAR(50),
    rental_cost DECIMAL(10, 2) NOT NULL
);
GO

INSERT INTO Equipment (equipment_name, equipment_type, manufacturer, model, rental_cost)
VALUES
('Лыжи', 'Горнолыжное снаряжение', 'Rossignol', 'Hero Elite', 300.00),
('Лыжные ботинки', 'Горнолыжное снаряжение', 'Salomon', 'X-Pro 120', 200.00),
('Палки лыжные', 'Горнолыжное снаряжение', 'Leki', 'Carbon 14', 100.00);
GO

-- Таблица Instance
CREATE TABLE Instance (
    instance_id INT PRIMARY KEY IDENTITY(1,1),
    inventory_number VARCHAR(50) NOT NULL UNIQUE,
    size VARCHAR(20),
    condition VARCHAR(50),
    equipment_id INT NOT NULL,
    FOREIGN KEY (equipment_id) REFERENCES Equipment(equipment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

INSERT INTO Instance (inventory_number, size, condition, equipment_id)
VALUES
('SKI001', '175 см', 'Новое', 1), 
('SKI002', '180 см', 'Хорошее', 1), 
('BOOT001', '42', 'Новое', 2), 
('BOOT002', '44', 'Хорошее', 2), 
('POLE001', '120 см', 'Новое', 3), 
('POLE002', '125 см', 'Хорошее', 3);
GO

-- Таблица Rental_Instance
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
GO

INSERT INTO Rental_Instance (rental_id, instance_id)
VALUES
(1, 1), 
(1, 3), 
(1, 5), 
(2, 2), 
(2, 4), 
(2, 6);
GO

-- Индексы
CREATE INDEX idx_client_id ON Rental_Agreement(client_id);
GO

CREATE INDEX idx_equipment_id ON Instance(equipment_id);
GO

-- Функция для вычисления общей стоимости аренды
CREATE FUNCTION CalculateRentalCost (@agreement_id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_cost DECIMAL(10,2);

    -- Вычисление стоимости аренды на основе количества дней аренды и стоимости оборудования
    SELECT @total_cost = SUM(e.rental_cost)
    FROM Rental_Instance ri
    JOIN Instance i ON ri.instance_id = i.instance_id
    JOIN Equipment e ON i.equipment_id = e.equipment_id
    JOIN Rental_Agreement ra ON ri.rental_id = ra.agreement_id
    WHERE ra.agreement_id = @agreement_id
    AND ra.start_date <= GETDATE() AND ra.end_date >= GETDATE();

    RETURN @total_cost;
END;
GO

-- Обновить стоимость аренды в договоре
UPDATE Rental_Agreement
SET total_cost = dbo.CalculateRentalCost(1)
WHERE agreement_id = 1;


-- Хранимая процедура
CREATE PROCEDURE CalculateTotalRentalCost
    @agreement_id INT
AS
BEGIN
    DECLARE @total_cost DECIMAL(10,2);
    SELECT @total_cost = SUM(e.rental_cost)
    FROM Rental_Instance ri
    JOIN Instance i ON ri.instance_id = i.instance_id
    JOIN Equipment e ON i.equipment_id = e.equipment_id
    WHERE ri.rental_id = @agreement_id;
    UPDATE Rental_Agreement
    SET total_cost = @total_cost
    WHERE agreement_id = @agreement_id;
END;
GO

-- Триггер
CREATE TRIGGER trg_UpdateRentalCost
ON Rental_Instance
AFTER INSERT, DELETE
AS
BEGIN
    DECLARE @rental_id INT;
    SELECT @rental_id = rental_id FROM inserted;
    EXEC CalculateTotalRentalCost @rental_id;
END;
GO

-- Представления
CREATE VIEW ClientRentalInfo AS
SELECT c.client_id, c.first_name, c.last_name, c.phone_number, ra.agreement_id, ra.start_date, ra.end_date, ra.total_cost
FROM Client c
JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO

-- Примеры запросов с JOIN

-- INNER JOIN: Получение клиентов и их договоров
SELECT c.first_name, c.last_name, ra.agreement_id, ra.start_date, ra.total_cost
FROM Client c
INNER JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO

-- LEFT JOIN: Все клиенты, включая тех, у кого нет договоров
SELECT c.first_name, c.last_name, ra.agreement_id
FROM Client c
LEFT JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO

-- FULL OUTER JOIN: Все клиенты и все договоры
SELECT c.first_name, c.last_name, ra.agreement_id
FROM Client c
FULL OUTER JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO

-- Примеры использования DISTINCT
-- Уникальные типы оборудования
SELECT DISTINCT equipment_type
FROM Equipment;
GO

-- Примеры упорядочивания и создания псевдонимов для полей
-- Список клиентов с договорами, упорядоченных по имени клиента
SELECT 
    c.first_name AS Имя, 
    c.last_name AS Фамилия, 
    ra.agreement_id AS Договор, 
    ra.total_cost AS Стоимость
FROM Client c
JOIN Rental_Agreement ra ON c.client_id = ra.client_id
ORDER BY c.first_name ASC, c.last_name ASC;
GO
