USE master;
GO


IF DB_ID(N'lab11') IS NOT NULL
    DROP DATABASE lab11;
GO


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

IF OBJECT_ID(N'Client') IS NOT NULL
	DROP TABLE Client;
GO

CREATE TABLE Client (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    phone_number VARCHAR(15) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) DEFAULT 'Не указано',  
    email VARCHAR(100) UNIQUE 
);
GO

IF OBJECT_ID(N'TempClient') IS NOT NULL
	DROP TABLE TempClient;
GO

CREATE TABLE TempClient (
    client_id INT PRIMARY KEY IDENTITY(1,1),
    phone_number VARCHAR(15) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) DEFAULT 'Не указано',  
    email VARCHAR(100) UNIQUE 
);
GO

INSERT INTO TempClient (phone_number, first_name, last_name, middle_name, email)
VALUES
('1234567890', 'Мария', 'Иванова', 'Александровна', 'maria.ivanova@example.com'),
('2345678901', 'Дмитрий', 'Сидоров', NULL, 'dmitry.sidorov@example.com'),
('3456789012', 'Екатерина', 'Федорова', 'Васильевна', 'ekaterina.fedorova@example.com'),
('4567890123', 'Александр', 'Новиков', '', 'alex.novikov@example.com'),
('5678901234', 'Ольга', 'Морозова', 'Ивановна', 'olga.morozova@example.com'),
('6789012345', 'Виктор', 'Климов', 'Сергеевич', 'viktor.klimov@example.com'),
('1234567891', 'Игорь', 'Соколов', 'Сергеевич', 'igor.sokolov@example.com');
GO


INSERT INTO Client (phone_number, first_name, last_name, middle_name, email)
SELECT phone_number, first_name, last_name, middle_name, email
FROM TempClient
WHERE NOT EXISTS (
    SELECT 1 
    FROM Client 
    WHERE Client.phone_number = TempClient.phone_number
);

SELECT * FROM Client

GO

IF OBJECT_ID(N'Rental_Agreement') IS NOT NULL
	DROP TABLE Rental_Agreement;
GO

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


SELECT * FROM Rental_Agreement

ALTER TABLE Rental_Agreement
ADD column_name VARCHAR(10);

ALTER TABLE Rental_Agreement
DROP COLUMN column_name ;



INSERT INTO Rental_Agreement (client_id, start_date, end_date, agreement_date, total_cost)
VALUES
(1, '2023-01-15', '2023-01-20', '2023-01-10', 1200.00), 
(2, '2023-06-05', '2023-06-10', '2023-06-01', 750.00), 
(3, '2024-02-10', '2024-02-15', '2024-02-08', 950.00), 
(4, '2022-07-20', '2022-07-25', '2022-07-18', 1400.00), 
(5, '2025-03-05', '2025-03-10', '2025-03-02', 880.00), 
(6, '2023-10-10', '2023-10-15', '2023-10-07', 640.00), 
(7, '2022-05-01', '2022-05-05', '2022-04-28', 520.00);



IF OBJECT_ID(N'Equipment') IS NOT NULL
	DROP TABLE Equipment;
GO

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
('Горные лыжи', 'Лыжное оборудование', 'Atomic', 'Redster X7', 320.00),
('Лыжные ботинки', 'Лыжное оборудование', 'Head', 'Vector 120S', 250.00),
('Лыжные палки', 'Лыжное оборудование', 'Komperdell', 'Nationalteam Carbon', 150.00),
('Шлем лыжный', 'Защитное снаряжение', 'Giro', 'Range MIPS', 180.00),
('Горнолыжные перчатки', 'Одежда', 'Reusch', 'Volcano Pro', 100.00),
('Маска лыжная', 'Защитное снаряжение', 'Oakley', 'Flight Deck', 140.00),
('Куртка горнолыжная', 'Одежда', 'Columbia', 'Powder Lite', 400.00),
('Брюки горнолыжные', 'Одежда', 'The North Face', 'Freedom Insulated', 300.00),
('Сноуборд', 'Сноубордическое оборудование', 'Burton', 'Custom X', 500.00),
('Сноубордические ботинки', 'Сноубордическое оборудование', 'DC', 'Phase', 220.00);
GO


IF OBJECT_ID(N'Instance') IS NOT NULL
	DROP TABLE Instance;
GO


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
-- Горные лыжи
('SKI003', '170 см', 'Новое', 1), 
('SKI004', '185 см', 'Удовлетворительное', 1), 
-- Лыжные ботинки
('BOOT003', '43', 'Новое', 2), 
('BOOT004', '45', 'Удовлетворительное', 2), 
-- Лыжные палки
('POLE003', '115 см', 'Новое', 3), 
('POLE004', '130 см', 'Удовлетворительное', 3), 
-- Шлемы лыжные
('HELM001', 'M', 'Новое', 4), 
('HELM002', 'L', 'Хорошее', 4), 
-- Горнолыжные перчатки
('GLOVE001', 'S', 'Новое', 5), 
('GLOVE002', 'M', 'Хорошее', 5), 
-- Маски лыжные
('MASK001', '-', 'Новое', 6), 
('MASK002', '-', 'Хорошее', 6), 
-- Куртки горнолыжные
('JACKET001', 'M', 'Новое', 7), 
('JACKET002', 'L', 'Удовлетворительное', 7), 
-- Брюки горнолыжные
('PANTS001', 'M', 'Новое', 8), 
('PANTS002', 'L', 'Хорошее', 8), 
-- Сноуборды
('SNOW001', '150 см', 'Новое', 9), 
('SNOW002', '160 см', 'Хорошее', 9), 
-- Сноубордические ботинки
('SNOWBOOT001', '41', 'Новое', 10), 
('SNOWBOOT002', '42', 'Хорошее', 10);
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



-- вычисляет общую стоимость аренды на основе связанного оборудования
CREATE FUNCTION dbo.CalculateRentalCost (@agreement_id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total_cost DECIMAL(10,2);

    -- Проверка существования соглашения
    IF NOT EXISTS (SELECT 1 FROM Rental_Agreement WHERE agreement_id = @agreement_id)
    BEGIN
        RETURN 0;
    END

    -- Вычисление стоимости аренды с учетом возможных NULL значений
    SELECT @total_cost = SUM(COALESCE(e.rental_cost, 0))
    FROM Rental_Instance ri
    JOIN Instance i ON ri.instance_id = i.instance_id
    JOIN Equipment e ON i.equipment_id = e.equipment_id
    JOIN Rental_Agreement ra ON ri.rental_id = ra.agreement_id
    WHERE ra.agreement_id = @agreement_id;

    RETURN @total_cost;
END;

---------------------------------------------------------------------
SELECT ri.rental_id, ri.instance_id, i.equipment_id, e.rental_cost
FROM Rental_Instance ri
JOIN Instance i ON ri.instance_id = i.instance_id
JOIN Equipment e ON i.equipment_id = e.equipment_id
WHERE ri.rental_id IN (1, 2, 3);


SELECT *
FROM Rental_Instance
WHERE rental_id = 2;


SELECT dbo.CalculateRentalCost(1) AS TotalCost_Rental_1;
SELECT dbo.CalculateRentalCost(2) AS TotalCost_Rental_2;
SELECT dbo.CalculateRentalCost(3) AS TotalCost_Rental_3;
--------------------------------------------------------------------


-- до апд
SELECT agreement_id, total_cost
FROM Rental_Agreement
WHERE agreement_id = 1;

-- Обновить стоимость аренды в договоре
UPDATE Rental_Agreement
SET total_cost = dbo.CalculateRentalCost(1)
WHERE agreement_id = 1;

-- после апд
SELECT agreement_id, total_cost
FROM Rental_Agreement
WHERE agreement_id = 1;

-- обновляет общую стоимость аренды в таблице Rental_Agreement на основе количества арендуемого оборудования
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

-- Выполним вызов процедуры для обновления общей стоимости аренды по договору с ID 1
EXEC CalculateTotalRentalCost @agreement_id = 3;

-- Проверим обновленную стоимость аренды в таблице Rental_Agreement
SELECT agreement_id, total_cost
FROM Rental_Agreement
WHERE agreement_id = 3;

DROP TRIGGER trg_UpdateRentalCost;
CREATE TRIGGER trg_UpdateRentalCost
ON Rental_Instance
AFTER INSERT, DELETE
AS
BEGIN
    -- Обновляем стоимость аренды при добавлении записей
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE Rental_Agreement
        SET total_cost = total_cost + ISNULL(added_costs.total_cost_delta, 0)
        FROM Rental_Agreement ra
        JOIN (
            SELECT ri.rental_id, SUM(e.rental_cost) AS total_cost_delta
            FROM inserted i
            JOIN Rental_Instance ri ON i.rental_id = ri.rental_id
            JOIN Instance inst ON ri.instance_id = inst.instance_id
            JOIN Equipment e ON inst.equipment_id = e.equipment_id
            GROUP BY ri.rental_id
        ) AS added_costs ON ra.agreement_id = added_costs.rental_id;
    END

    -- Обновляем стоимость аренды при удалении записей
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE Rental_Agreement
        SET total_cost = total_cost - ISNULL(removed_costs.total_cost_delta, 0)
        FROM Rental_Agreement ra
        JOIN (
            SELECT ri.rental_id, SUM(e.rental_cost) AS total_cost_delta
            FROM deleted d
            JOIN Rental_Instance ri ON d.rental_id = ri.rental_id
            JOIN Instance inst ON ri.instance_id = inst.instance_id
            JOIN Equipment e ON inst.equipment_id = e.equipment_id
            GROUP BY ri.rental_id
        ) AS removed_costs ON ra.agreement_id = removed_costs.rental_id;
    END
END;
GO


--тест для 2х rental id и agreemnet_id
------------------------------------------------------------------------------------------------------------------------
-- Проверяем текущие данные в таблицах
SELECT * FROM Rental_Instance;
SELECT * FROM Instance;
SELECT * FROM Equipment;
SELECT * FROM Rental_Agreement;



INSERT INTO Rental_Instance (rental_id, instance_id)
VALUES (2, 10), (2, 11);  


SELECT agreement_id, total_cost
FROM Rental_Agreement
WHERE agreement_id = 1;
-----------------------------------------------------------
SELECT ri.rental_id, e.rental_cost
FROM Rental_Instance ri
JOIN Instance inst ON ri.instance_id = inst.instance_id
JOIN Equipment e ON inst.equipment_id = e.equipment_id;

SELECT ra.agreement_id, ri.rental_id, ri.instance_id
FROM Rental_Agreement ra
LEFT JOIN Rental_Instance ri ON ra.agreement_id = ri.rental_id;
-------------------------------------------------------------------

DELETE FROM Rental_Instance
WHERE (rental_id = 1 AND instance_id = 8)
   OR (rental_id = 1 AND instance_id = 9);




SELECT agreement_id, total_cost
FROM Rental_Agreement
WHERE agreement_id = 1;
------------------------------------------------------------------------------------------------------------------------

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

-- RIGHT JOIN: Все договоры аренды, включая те, которые не привязаны к клиентам
SELECT c.first_name, c.last_name, ra.agreement_id
FROM Client c
RIGHT JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO


-- FULL OUTER JOIN: Все клиенты и все договоры
SELECT c.first_name, c.last_name, ra.agreement_id
FROM Client c
FULL OUTER JOIN Rental_Agreement ra ON c.client_id = ra.client_id;
GO


SELECT equipment_type
FROM Equipment
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


-- Группировка по типу оборудования и подсчет количества каждого типа
SELECT equipment_type, COUNT(*) AS Количество
FROM Equipment
GROUP BY equipment_type;




SELECT first_name, last_name FROM Client
UNION
SELECT first_name, last_name FROM TempClient;



SELECT equipment_type, COUNT(*) AS Количество
FROM Equipment
GROUP BY equipment_type
HAVING COUNT(*) > 5;


SELECT first_name, last_name, phone_number, email
FROM Client
WHERE first_name LIKE 'М%';


