-- ==============================
-- Секция 1: Создание базы данных
-- ==============================
USE MASTER;
GO

IF db_id(N'SkiRental') IS NOT NULL
    DROP DATABASE SkiRental;
GO

CREATE DATABASE SkiRental ON
(
    name = SkiRentalData,
    filename = 'D:\SkiRental.mdf',  
    size = 10,
    maxsize = unlimited,
    filegrowth = 5%
);
GO

-- ==============================
-- Секция 2: Создание таблицы и данных
-- ==============================
INSERT INTO EQUIPMENT (NAME, TYPE, SIZE, AVAILABLE) VALUES
('SKI SET 1', 'SKI', 'M', 1),
('SKI SET 2', 'SKI', 'L', 1),
('SNOWBOARD 1', 'SNOWBOARD', 'M', 1),
('SNOWBOARD 2', 'SNOWBOARD', 'L', 1);
GO

IF OBJECT_ID(N'CUSTOMER') IS NOT NULL
    DROP TABLE CUSTOMER;
GO

CREATE TABLE CUSTOMER
(
    CUSTOMER_ID INT IDENTITY(1,1) PRIMARY KEY,
    FIRSTNAME NVARCHAR(50) NOT NULL CHECK (LEN(FIRSTNAME) > 0),
    LASTNAME NVARCHAR(50) NOT NULL CHECK (LEN(LASTNAME) > 0),
    PHONE NVARCHAR(15) NOT NULL,
    EMAIL NVARCHAR(256) NOT NULL CHECK (LEN(EMAIL) > 0)
);
GO

INSERT INTO CUSTOMER (FIRSTNAME, LASTNAME, PHONE, EMAIL) VALUES
('IVAN', 'IVANOV', '79261111111', 'IVANOV@GMAIL.COM'),
('PETR', 'PETROV', '79262222222', 'PETROV@GMAIL.COM'),
('OLEG', 'OLEGOV', '79263333333', 'OLEGOV@GMAIL.COM'),
('NIKITA', 'NIKITIN', '79264444444', 'NIKITIN@GMAIL.COM');
GO

IF OBJECT_ID(N'LEASE') IS NOT NULL
    DROP TABLE LEASE;
GO

CREATE TABLE LEASE
(
    LEASE_ID INT IDENTITY(1,1) PRIMARY KEY,
    EQUIPMENT_ID INT NOT NULL FOREIGN KEY REFERENCES EQUIPMENT(EQUIPMENT_ID),
    CUSTOMER_ID INT NOT NULL FOREIGN KEY REFERENCES CUSTOMER(CUSTOMER_ID),
    LEASE_DATE DATETIME NOT NULL DEFAULT GETDATE(),
    RETURN_DATE DATETIME NULL
);
GO

INSERT INTO LEASE (EQUIPMENT_ID, CUSTOMER_ID, LEASE_DATE) VALUES
(1, 1, GETDATE()), 
(2, 2, GETDATE()), 
(3, 3, GETDATE());
GO

-- ==============================
-- СЕКЦИЯ 3: ИССЛЕДОВАНИЕ УРОВНЕЙ ИЗОЛЯЦИИ
-- ==============================

-- УРОВЕНЬ ИЗОЛЯЦИИ: READ UNCOMMITTED
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM EQUIPMENT;
COMMIT TRANSACTION;
GO

-- УРОВЕНЬ ИЗОЛЯЦИИ: READ COMMITTED
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM EQUIPMENT;
COMMIT TRANSACTION;
GO

-- УРОВЕНЬ ИЗОЛЯЦИИ: REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT WHERE AVAILABLE = 1;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM EQUIPMENT WHERE AVAILABLE = 1;
COMMIT TRANSACTION;
GO

-- УРОВЕНЬ ИЗОЛЯЦИИ: SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT WHERE AVAILABLE = 1;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM EQUIPMENT WHERE AVAILABLE = 1;
COMMIT TRANSACTION;
GO

-- ==============================
-- СЕКЦИЯ 4: ИССЛЕДОВАНИЕ БЛОКИРОВОК
-- ==============================

-- СЦЕНАРИЙ 1: ОБНОВЛЕНИЕ СТРОКИ
BEGIN TRANSACTION
    UPDATE EQUIPMENT SET AVAILABLE = 0 WHERE NAME = 'SKI SET 1';
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';  -- Симуляция ожидания для захвата блокировки
ROLLBACK TRANSACTION;
GO

-- СЦЕНАРИЙ 2: ВСТАВКА СТРОКИ
BEGIN TRANSACTION
    INSERT INTO EQUIPMENT (NAME, TYPE, SIZE, AVAILABLE) VALUES
    ('SKI SET 3', 'SKI', 'S', 1);
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
COMMIT TRANSACTION;
GO

-- СЦЕНАРИЙ 3: УДАЛЕНИЕ СТРОКИ
BEGIN TRANSACTION
    DELETE FROM EQUIPMENT WHERE NAME = 'SKI SET 2';
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';
ROLLBACK TRANSACTION;
GO

-- СЦЕНАРИЙ 4: ЧТЕНИЕ СТРОКИ С БЛОКИРОВКОЙ
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT WHERE NAME = 'SKI SET 1';
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';
COMMIT TRANSACTION;
GO

-- СЦЕНАРИЙ 5: ВСТАВКА С БЛОКИРОВКОЙ СТРОК
BEGIN TRANSACTION
    INSERT INTO EQUIPMENT (NAME, TYPE, SIZE, AVAILABLE) VALUES
    ('SNOWBOARD SET 3', 'SNOWBOARD', 'S', 1);
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';  -- Задержка для захвата блокировки
COMMIT TRANSACTION;
GO

-- СЦЕНАРИЙ 6: СИМУЛЯЦИЯ СЕРВИСНОЙ ЗАДАЧИ (Чтение блокируемой строки)
BEGIN TRANSACTION
    SELECT * FROM EQUIPMENT WHERE NAME = 'SKI SET 1';
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';  -- Преимуществительная блокировка чтения
ROLLBACK TRANSACTION;
GO

-- СЦЕНАРИЙ 7: ЧТЕНИЕ С ЗАБЛОКИРОВАННЫМИ ДАННЫМИ ВО ВРЕМЯ ОБНОВЛЕНИЯ
BEGIN TRANSACTION
    UPDATE EQUIPMENT SET AVAILABLE = 0 WHERE NAME = 'SNOWBOARD 1';
    SELECT * FROM EQUIPMENT WHERE NAME = 'SNOWBOARD 1';
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05';  -- Преимуществительная блокировка на чтение
ROLLBACK TRANSACTION;
GO

-- СЦЕНАРИЙ 8: ВСТАВКА С ВОЖДЕННЫМ ВРЕМЕНЕМ
BEGIN TRANSACTION
    INSERT INTO EQUIPMENT (NAME, TYPE, SIZE, AVAILABLE) VALUES
    ('SKI SET 4', 'SKI', 'M', 1);
    SELECT RESOURCE_TYPE, RESOURCE_SUBTYPE, REQUEST_MODE 
    FROM SYS.DM_TRAN_LOCKS WHERE REQUEST_SESSION_ID = @@SPID;
    WAITFOR DELAY '00:00:05'; -- Задержка для симуляции блокировки
COMMIT TRANSACTION;
GO