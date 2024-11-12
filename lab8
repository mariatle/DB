USE master;
GO

IF DB_ID(N'lab8sql') IS NOT NULL
    DROP DATABASE lab8sql;
GO

CREATE DATABASE lab8sql ON 
(
    NAME = lab8sqldat,
    FILENAME = 'D:\lab8sqldat.mdf', 
    SIZE = 10,
    MAXSIZE = UNLIMITED, 
    FILEGROWTH = 5%
);
GO

USE lab8sql;
GO

DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer
(
    id INT IDENTITY(1,1) PRIMARY KEY,  
    firstName NVARCHAR(50) NOT NULL,   
    lastName NVARCHAR(70) NOT NULL,     
    patronymic NVARCHAR(70) NULL,   
    contractDate DATE NOT NULL           
);
GO

INSERT INTO Customer(firstName, lastName, patronymic, contractDate) VALUES
('Олег', 'Петров', 'Сергеевич', '2021-01-15'),
('Анна', 'Иванова', 'Петровна', '2022-02-20'),
('Иван', 'Сидоров', 'Алексеевич', '2023-03-10'),
('Мария', 'Кузнецова', 'Ивановна', '2024-04-05'),
('Павел', 'Смирнов', 'Владимирович', '2021-05-12'),
('Екатерина', 'Федорова', 'Андреевна', '2022-06-18'),
('Алексей', 'Волков', 'Дмитриевич', '2023-07-22'),
('Наталья', 'Соколова', 'Михайловна', '2024-08-30'),
('Сергей', 'Морозов', 'Игоревич', '2021-09-14'),
('Ольга', 'Мельникова', 'Евгеньевна', '2022-10-25');
GO

-- 1) Создать хранимую процедуру, производящую выборку
-- из некоторой таблицы и возвращающую результат
-- выборки в виде курсора.


-- Создание хранимой процедуры, возвращающей курсор
CREATE PROCEDURE SelectCustomers
    @customerCursor CURSOR VARYING OUTPUT
AS
BEGIN
    -- Определение курсора для выборки из таблицы Customer
    SET @customerCursor = CURSOR FOR
    SELECT id, firstName, lastName, patronymic, contractDate
    FROM Customer;

    -- Открытие курсора
    OPEN @customerCursor;
END;
GO

-- Пример использования хранимой процедуры
DECLARE @cursor CURSOR;

-- Вызов процедуры с передачей курсора как параметра OUTPUT
EXEC SelectCustomers @customerCursor = @cursor OUTPUT;

-- Переменные для хранения данных из курсора
DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), @patronymic NVARCHAR(70), @contractDate DATE;

-- Извлечение и вывод данных из курсора
FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
          ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10));
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;
END

-- Закрытие и освобождение курсора
CLOSE @cursor;
DEALLOCATE @cursor;
GO

-- 2) Модифицировать хранимую процедуру п.1. таким
-- образом, чтобы выборка осуществлялась с
-- формированием столбца, значение которого
-- формируется пользовательской функцией.

-- 2.1) Создание пользовательской функции для формирования полного имени
CREATE FUNCTION dbo.GetFullName
(
    @firstName NVARCHAR(50),
    @lastName NVARCHAR(70)
)
RETURNS NVARCHAR(120)
AS
BEGIN
    RETURN @firstName + ' ' + @lastName;
END;
GO

-- 2.2) Модификация хранимой процедуры SelectCustomers с добавлением нового столбца FullName, который формируется функцией
ALTER PROCEDURE SelectCustomers
    @customerCursor CURSOR VARYING OUTPUT
AS
BEGIN
    -- Определение курсора для выборки из таблицы Customer с добавлением нового столбца
    SET @customerCursor = CURSOR FOR
    SELECT 
        id,
        firstName,
        lastName,
        patronymic,
        contractDate,
        dbo.GetFullName(firstName, lastName) AS FullName -- Новый столбец, сформированный функцией
    FROM Customer;

    -- Открытие курсора
    OPEN @customerCursor;
END;
GO

-- Пример использования модифицированной хранимой процедуры
DECLARE @cursor CURSOR;

-- Вызов процедуры с передачей курсора как параметра OUTPUT
EXEC SelectCustomers @customerCursor = @cursor OUTPUT;

-- Переменные для хранения данных из курсора, включая новый столбец FullName
DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), @patronymic NVARCHAR(70), @contractDate DATE, @fullName NVARCHAR(120);

-- Извлечение и вывод данных из курсора
FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
          ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) +
          ', Full Name: ' + @fullName;
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;
END

-- Закрытие и освобождение курсора
CLOSE @cursor;
DEALLOCATE @cursor;
GO

-- 3) Создать хранимую процедуру, вызывающую процедуру
-- п.1., осуществляющую прокрутку возвращаемого
-- курсора и выводящую сообщения, сформированные из
-- записей при выполнении условия, заданного еще одной
-- пользовательской функцией.

CREATE PROCEDURE CheckCustomerContracts
AS
BEGIN
    DECLARE @cursor CURSOR;
    DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), @patronymic NVARCHAR(70), @contractDate DATE;
    
    -- Вызов процедуры для получения курсора
    EXEC SelectCustomers @customerCursor = @cursor OUTPUT;

    -- Извлечение и вывод данных из курсора
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Проверка условия с использованием функции CheckContractYear
        IF dbo.CheckContractYear(@contractDate) = 1
        BEGIN
            PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
                  ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) + 
                  ' (Contract Year >= 2022)';
        END
        ELSE
        BEGIN
            PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
                  ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) + 
                  ' (Contract Year < 2022)';
        END

        FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;
    END

    -- Закрытие и освобождение курсора
    CLOSE @cursor;
    DEALLOCATE @cursor;
END;
GO

-- 4) Модифицировать хранимую процедуру п.2. таким образом, чтобы выборка формировалась с помощью табличной функции.
-- Процедура, использующая табличную функцию и выполняющая дополнительные проверки

IF OBJECT_ID('CheckCustomerContracts', 'P') IS NOT NULL
    DROP PROCEDURE CheckCustomerContracts;
GO

-- 2. Создание табличной функции GetCustomersWithFullName, которая формирует полный список с полным именем
CREATE FUNCTION dbo.GetCustomersWithFullName()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        id,
        firstName,
        lastName,
        patronymic,
        contractDate,
        -- Формирование полного имени с использованием конкатенации
        firstName + ' ' + lastName AS FullName
    FROM Customer
);
GO

-- 3. Создание хранимой процедуры CheckCustomerContracts, которая использует курсор для прокрутки данных из табличной функции
CREATE PROCEDURE CheckCustomerContracts
AS
BEGIN
    -- Объявление переменных для хранения данных из курсора
    DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), 
            @patronymic NVARCHAR(70), @contractDate DATE, @fullName NVARCHAR(120);

    -- Объявление курсора для выборки данных из табличной функции GetCustomersWithFullName
    DECLARE customer_cursor CURSOR FOR
    SELECT id, firstName, lastName, patronymic, contractDate, FullName
    FROM dbo.GetCustomersWithFullName();

    -- Открытие курсора
    OPEN customer_cursor;

    -- Извлечение первой строки из курсора
    FETCH NEXT FROM customer_cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;

    -- Цикл обработки каждой записи
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Проверка условия с использованием функции CheckContractYear
        IF dbo.CheckContractYear(@contractDate) = 1
        BEGIN
            -- Вывод сообщения, если контракт с годом >= 2022
            PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + 
                  ', Full Name: ' + @fullName + 
                  ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) + 
                  ' (Contract Year >= 2022)';
        END
        ELSE
        BEGIN
            -- Вывод сообщения, если контракт с годом < 2022
            PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + 
                  ', Full Name: ' + @fullName + 
                  ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) + 
                  ' (Contract Year < 2022)';
        END

        -- Извлечение следующей строки
        FETCH NEXT FROM customer_cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;
    END

    -- Закрытие и освобождение курсора
    CLOSE customer_cursor;
    DEALLOCATE customer_cursor;
END;
GO

-- 4. Использование процедуры
EXEC CheckCustomerContracts;
GO
