
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


CREATE PROCEDURE SelectCustomers
    @customerCursor CURSOR VARYING OUTPUT
AS
BEGIN
   
    SET @customerCursor = CURSOR FOR
    SELECT id, firstName, lastName, patronymic, contractDate
    FROM Customer;

    
    OPEN @customerCursor;
END;
GO

-- Демонстрация работы
DECLARE @cursor CURSOR;

EXEC SelectCustomers @customerCursor = @cursor OUTPUT;


DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), @patronymic NVARCHAR(70), @contractDate DATE;


FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
          ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10));
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate;
END


CLOSE @cursor;
DEALLOCATE @cursor;
GO

-- 2) Модифицировать хранимую процедуру п.1. таким
-- образом, чтобы выборка осуществлялась с
-- формированием столбца, значение которого
-- формируется пользовательской функцией.

-- 2.1) Создание пользовательской функции
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

-- 2.2) Изменение хранимой процедуры SelectCustomers с добавлением нового столбца FullName, который формируется функцией
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
        dbo.GetFullName(firstName, lastName) AS FullName 
    FROM Customer;


    OPEN @customerCursor;
END;
GO


DECLARE @cursor CURSOR;


EXEC SelectCustomers @customerCursor = @cursor OUTPUT;


DECLARE @id INT, @firstName NVARCHAR(50), @lastName NVARCHAR(70), @patronymic NVARCHAR(70), @contractDate DATE, @fullName NVARCHAR(120);


FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'ID: ' + CAST(@id AS NVARCHAR(10)) + ', First Name: ' + @firstName + ', Last Name: ' + @lastName + 
          ', Patronymic: ' + ISNULL(@patronymic, 'NULL') + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10)) +
          ', Full Name: ' + @fullName;
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;
END


CLOSE @cursor;
DEALLOCATE @cursor;
GO

-- 3) Создать хранимую процедуру, вызывающую процедуру
-- п.1., осуществляющую прокрутку возвращаемого
-- курсора и выводящую сообщения, сформированные из
-- записей при выполнении условия, заданного еще одной
-- пользовательской функцией.
-- 3.1) Создание пользовательской функции для проверки условия
CREATE FUNCTION dbo.IsRecentContract
(
    @contractDate DATE
)
RETURNS BIT
AS
BEGIN
    RETURN CASE 
               WHEN @contractDate > DATEADD(YEAR, -3, GETDATE()) THEN 1
               ELSE 0
           END;
END;
GO

-- 3.2) Создание хранимой процедуры, вызывающей SelectCustomers
CREATE PROCEDURE ProcessCustomers
AS
BEGIN
    -- Объявление курсора
    DECLARE @cursor CURSOR;
    
    -- Вызов процедуры SelectCustomers
    EXEC SelectCustomers @customerCursor = @cursor OUTPUT;

    -- Переменные для хранения значений текущей записи курсора
    DECLARE @id INT, 
            @firstName NVARCHAR(50), 
            @lastName NVARCHAR(70), 
            @patronymic NVARCHAR(70), 
            @contractDate DATE, 
            @fullName NVARCHAR(120);

    -- Прокрутка курсора
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Проверка условия с помощью функции dbo.IsRecentContract
        IF dbo.IsRecentContract(@contractDate) = 1
        BEGIN
            PRINT 'Recent Contract - Full Name: ' + @fullName + ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10));
        END;

        FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;
    END;

    -- Закрытие и освобождение ресурсов курсора
    CLOSE @cursor;
    DEALLOCATE @cursor;
END;
GO

-- Демонстрация работы процедуры ProcessCustomers
EXEC ProcessCustomers;
GO


-- 4) Модифицировать хранимую процедуру п.2. таким образом, чтобы выборка формировалась с помощью табличной функции.
-- Процедура, использующая табличную функцию и выполняющая дополнительные проверки

-- 4.1) Создание табличной функции
CREATE FUNCTION dbo.GetCustomersTable()
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
        dbo.GetFullName(firstName, lastName) AS FullName
    FROM Customer
);
GO

-- 4.2) Изменение хранимой процедуры SelectCustomers для использования табличной функции
ALTER PROCEDURE SelectCustomers
    @customerCursor CURSOR VARYING OUTPUT
AS
BEGIN
    -- Определение курсора для выборки из табличной функции dbo.GetCustomersTable
    SET @customerCursor = CURSOR FOR
    SELECT *
    FROM dbo.GetCustomersTable();

    OPEN @customerCursor;
END;
GO

-- 4.3) Создание новой процедуры, использующей SelectCustomers и выполняющей дополнительные проверки
CREATE PROCEDURE ProcessAndCheckCustomers
AS
BEGIN
    -- Объявление курсора
    DECLARE @cursor CURSOR;

    -- Вызов процедуры SelectCustomers
    EXEC SelectCustomers @customerCursor = @cursor OUTPUT;

    -- Переменные для хранения значений текущей записи курсора
    DECLARE @id INT,
            @firstName NVARCHAR(50),
            @lastName NVARCHAR(70),
            @patronymic NVARCHAR(70),
            @contractDate DATE,
            @fullName NVARCHAR(120);

    -- Прокрутка курсора
    FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Дополнительная проверка: контракт должен быть заключён не ранее 2023 года
        IF @contractDate >= '2023-01-01'
        BEGIN
            PRINT 'Valid Contract - ID: ' + CAST(@id AS NVARCHAR(10)) + 
                  ', Full Name: ' + @fullName + 
                  ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10));
        END
        ELSE
        BEGIN
            PRINT 'Ignored Contract - ID: ' + CAST(@id AS NVARCHAR(10)) + 
                  ', Full Name: ' + @fullName + 
                  ', Contract Date: ' + CAST(@contractDate AS NVARCHAR(10));
        END;

        FETCH NEXT FROM @cursor INTO @id, @firstName, @lastName, @patronymic, @contractDate, @fullName;
    END;

    -- Закрытие и освобождение ресурсов курсора
    CLOSE @cursor;
    DEALLOCATE @cursor;
END;
GO

-- 4.4) Демонстрация работы процедуры ProcessAndCheckCustomers
EXEC ProcessAndCheckCustomers;
GO
