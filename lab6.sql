USE master;
GO

IF DB_ID(N'lab6') IS NOT NULL
    DROP DATABASE lab6;
GO

CREATE DATABASE lab6
ON
(
    NAME = lab6dat,
    FILENAME = 'D:\lab6dat.mdf', 
    SIZE = 10,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
)

USE lab6;
GO

-- 1. Создать таблицу с автоинкрементным первичным ключом.
-- Изучить функции, предназначенные для получения сгенерированного значения IDENTITY.
DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer
(
    id INT IDENTITY(1,1) PRIMARY KEY,  -- Автоинкрементный первичный ключ
    firstName NVARCHAR(50) NOT NULL,   
    lastName NVARCHAR(70) NOT NULL,     
    patronymic NVARCHAR(70) NULL,   
    contractDate DATE NOT NULL           
);
GO

-- Вставка данных в таблицу Customer и изучение функций получения сгенерированного значения IDENTITY.
INSERT INTO Customer(firstName, lastName, patronymic, contractDate) VALUES
('Олег', 'Петров', 'Сергеевич', '2024-01-15'),
('Анна', 'Иванова', 'Петровна', '2024-02-20');
GO

SELECT SCOPE_IDENTITY() AS CustomerID_scope;  -- Получение последнего сгенерированного значения IDENTITY в текущей сессии
SELECT @@IDENTITY AS CustomerID;  -- Получение последнего сгенерированного значения IDENTITY
SELECT IDENT_CURRENT('Customer') AS CustomerID_current;  -- Получение последнего сгенерированного значения IDENTITY для указанной таблицы

SELECT * FROM Customer;  
GO


-- 2. Добавить поля, для которых используются ограничения (CHECK), значения по умолчанию (DEFAULT),
-- также использовать встроенные функции для вычисления значений.
DROP TABLE IF EXISTS EquipmentType;
GO

CREATE TABLE EquipmentType
(
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT(NEWID()),
    name NVARCHAR(40) UNIQUE NOT NULL CHECK (LEN(name) > 1),
    price FLOAT NOT NULL CHECK (price > 0),
    duration NVARCHAR(80) NOT NULL CHECK (duration IN('1 day', '7 days', '30 days', '1 season'))
);
GO

INSERT INTO EquipmentType(name, price, duration) VALUES
('Ski Package', 100, '1 day'),
('Snowboard Package', 120, '1 day');
GO

SELECT * FROM EquipmentType;
GO

-- 3. Создать таблицу с первичным ключом на основе глобального уникального идентификатора.
DROP TABLE IF EXISTS Equipment;
GO

CREATE TABLE Equipment
(
    id UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,  -- Глобальный уникальный идентификатор
    name NVARCHAR(50) NOT NULL,                        
    type NVARCHAR(50) NOT NULL,                        
    brand NVARCHAR(50) NOT NULL,                       
    rentalPrice FLOAT NOT NULL CHECK (rentalPrice > 0),  
    availableCount INT NOT NULL CHECK (availableCount >= 0)  
);
GO

INSERT INTO Equipment(name, type, brand, rentalPrice, availableCount) VALUES
('Горные лыжи', 'лыжи', 'Rossignol', 50.0, 10),
('Сноуборд', 'сноуборд', 'Burton', 60.0, 5);
GO

SELECT * FROM Equipment;  -- Вывод всех данных из таблицы Equipment
GO


-- 4. Создать таблицу с первичным ключом на основе последовательности.
DROP SEQUENCE IF EXISTS InstructorSeq;
GO

CREATE SEQUENCE InstructorSeq 
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 100;  -- Увеличим максимальное значение для большего количества инструкторов
GO

-- Создание таблицы Instructors
CREATE TABLE Instructors
(
    id INT PRIMARY KEY DEFAULT NEXT VALUE FOR InstructorSeq,  -- Первичный ключ на основе последовательности
    firstName NVARCHAR(50) NOT NULL,                         
    lastName NVARCHAR(50) NOT NULL,                          
    email NVARCHAR(100) NOT NULL UNIQUE,                     
    dateOfBirth DATE NOT NULL,                              
    specialty NVARCHAR(50) NOT NULL                          
);
GO

-- Вставка данных в таблицу Instructors.
INSERT INTO Instructors(firstName, lastName, email, dateOfBirth, specialty) VALUES
('Ivan', 'Ivanov', 'ivan.ivanov@mail.ru', '1985-05-15', 'лыжи'),
('Petr', 'Petrov', 'petr.petrov@mail.ru', '1990-08-22', 'сноуборд'),
('Anna', 'Sidorova', 'anna.sidorova@mail.ru', '1995-12-10', 'лыжи');
GO

SELECT * FROM Instructors;  -- Вывод всех данных из таблицы Instructors
GO



-- 5. Создать две связанные таблицы и протестировать на них различные варианты действий
-- для ограничений ссылочной целостности (NO ACTION | CASCADE | SET | SET DEFAULT).


DROP TABLE IF EXISTS Rental;


DROP TABLE IF EXISTS EquipmentType;


CREATE TABLE EquipmentType (
    name NVARCHAR(40) PRIMARY KEY,
    price DECIMAL(10, 2) NOT NULL  
);

-- Вставляем записи в таблицу EquipmentType с указанием цены
INSERT INTO EquipmentType(name, price) VALUES 
('Ski Package', 150.00), 
('Snowboard Package', 120.00);
GO

-- Создаем таблицу Rental с действием CASCADE
CREATE TABLE Rental
(
    id INT IDENTITY(1,1) PRIMARY KEY,
    rentalDate DATE NOT NULL,
    returnDate DATE NOT NULL CHECK (returnDate > DATEADD(year, -12, GETDATE())),
    equipmentTypeName NVARCHAR(40),
    FOREIGN KEY (equipmentTypeName) REFERENCES EquipmentType(name)
    ON DELETE CASCADE  -- Пример действия на ограничение ссылочной целостности
);
GO

-- Вставляем записи в таблицу Rental
INSERT INTO Rental(rentalDate, returnDate, equipmentTypeName) VALUES
('2024-02-06', '2024-02-06', 'Ski Package'),
('2025-03-06', '2025-03-06', 'Snowboard Package');
GO



DROP TABLE IF EXISTS EquipmentTypeNoAction;


CREATE TABLE EquipmentTypeNoAction (
    name NVARCHAR(40) PRIMARY KEY
);


INSERT INTO EquipmentTypeNoAction(name) VALUES 
('Ski Package'), 
('Snowboard Package');
GO

-- Пример действия NO ACTION
ALTER TABLE Rental
ADD CONSTRAINT FK_EquipmentTypeNoAction
FOREIGN KEY (equipmentTypeName) REFERENCES EquipmentTypeNoAction(name) 
ON DELETE NO ACTION;  
GO

-- Для демонстрации действия SET
DROP TABLE IF EXISTS EquipmentTypeSet;

CREATE TABLE EquipmentTypeSet (
    name NVARCHAR(40) PRIMARY KEY
);

-- Вставляем данные в EquipmentTypeSet
INSERT INTO EquipmentTypeSet(name) VALUES 
('Ski Package'), 
('Snowboard Package');
GO

ALTER TABLE Rental
ADD CONSTRAINT FK_EquipmentTypeSet
FOREIGN KEY (equipmentTypeName) REFERENCES EquipmentTypeSet(name) 
ON DELETE SET NULL;  -- Действие SET NULL
GO


-- Удаляем запись из EquipmentTypeSet и проверяем результат
DELETE FROM EquipmentTypeSet WHERE name = 'Ski Package';

-- Проверка данных в Rental после удаления
SELECT * FROM Rental;
