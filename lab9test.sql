USE lab6;
GO
-- 1) Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, при
-- выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).
-- Удаляем существующие триггеры, если они есть
DROP TRIGGER IF EXISTS trg_Customer_Insert;
DROP TRIGGER IF EXISTS trg_Customer_Delete;
DROP TRIGGER IF EXISTS trg_Customer_Update;
GO

-- Создание триггера на вставку
CREATE TRIGGER trg_Customer_Insert
ON Customer
AFTER INSERT
AS
BEGIN
    PRINT 'Новая запись добавлена в таблицу Customer.';
    -- Логика триггера: например, проверка на наличие определенного значения
    IF EXISTS (SELECT * FROM inserted WHERE lastName = 'Иванов')
    BEGIN
        RAISERROR ('Фамилия Иванов запрещена для добавления!', 16, 1);
        ROLLBACK TRANSACTION; -- Отмена транзакции
    END
END;
GO

-- Создание триггера на удаление
CREATE TRIGGER trg_Customer_Delete
ON Customer
AFTER DELETE
AS
BEGIN
    PRINT 'Запись была удалена из таблицы Customer.';
END;
GO

-- Создание триггера на обновление
CREATE TRIGGER trg_Customer_Update
ON Customer
AFTER UPDATE
AS
BEGIN
    PRINT 'Запись в таблице Customer была обновлена.';
    
    -- Логика триггера: проверка, изменилось ли поле contractDate и соответствует ли оно условию
    IF EXISTS (SELECT * 
               FROM inserted 
               JOIN deleted ON inserted.id = deleted.id 
               WHERE inserted.contractDate < '2020-01-01' 
                     AND inserted.contractDate <> deleted.contractDate)
    BEGIN
        THROW 50000, 'Дата контракта не может быть раньше 2020 года!', 1;
    END
END;
GO


-- Тестирование триггеров

--------------------------------------------------------------------------------------------
-- Попытка вставить запрещённую фамилию "Иванов"
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Пётр', 'Иванов', 'Алексеевич', '2024-03-01');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Попытка вставить фамилию "Петров"
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Иван', 'Петров', 'Васильевич', '2024-03-02');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Customer
-- Попытка вставить запрещённую фамилию "Иванов" с другим именем
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Анна', 'Иванов', 'Михайловна', '2024-03-03');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Попытка вставить фамилию "Смирнов"
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Алексей', 'Смирнов', 'Игоревич', '2024-03-04');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Попытка вставить запрещённую фамилию "Иванов" без отчества
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Мария', 'Иванов', NULL, '2024-03-05');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Попытка вставить фамилию "Кузнецов"
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('Сергей', 'Кузнецов', 'Олегович', '2024-03-06');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Адекват но без отчества
BEGIN TRY
    INSERT INTO Customer (firstName, lastName, patronymic, contractDate)
    VALUES ('А', 'Б', NULL, '2024-03-06');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;


-------------------------------------------------------------------------------------------------------
-- Попытка обновить контракт на дату раньше 2020 года
BEGIN TRY
    UPDATE Customer
    SET contractDate = '2019-12-31'
    WHERE id = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- еще один тест
BEGIN TRY
    UPDATE Customer
    SET contractDate = '2023-06-15'
    WHERE id = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- тест
BEGIN TRY
    UPDATE Customer
    SET contractDate = CASE 
        WHEN id = 1 THEN '2023-07-10' -- валидное значение
        WHEN id = 2 THEN '2018-05-22' -- невалидное значение
    END
    WHERE id IN (1, 2);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Customer;

------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------
-- Удаление записи
DELETE FROM Customer WHERE id = 1;
------------------------------------------------------------------------------------------



-- 2) Для представления пункта 2 задания 7 создать триггеры на вставку, удаление и добавление, обеспечивающие возможность выполнения
-- операций с данными непосредственно через представление.
USE lab6;
GO

-- Удаляем существующие триггеры, если они есть
DROP TRIGGER IF EXISTS trg_RentalWithEquipmentPrice_Insert;
DROP TRIGGER IF EXISTS trg_RentalWithEquipmentPrice_Delete;
DROP TRIGGER IF EXISTS trg_RentalWithEquipmentPrice_Update;
GO

-- Триггер на вставку
CREATE TRIGGER trg_RentalWithEquipmentPrice_Insert
ON RentalWithEquipmentPrice
INSTEAD OF INSERT
AS
BEGIN
    -- Перенаправляем вставку данных в базовые таблицы
    INSERT INTO Rental (rentalDate, returnDate, equipmentTypeName)
    SELECT rentalDate, returnDate, equipmentTypeName
    FROM inserted;

    PRINT 'Данные успешно вставлены через представление.';
END;
GO

-- Триггер на удаление
CREATE TRIGGER trg_RentalWithEquipmentPrice_Delete
ON RentalWithEquipmentPrice
INSTEAD OF DELETE
AS
BEGIN
    -- Перенаправляем удаление данных на таблицу Rental
    DELETE FROM Rental
    WHERE id IN (SELECT RentalID FROM deleted);

    PRINT 'Данные успешно удалены через представление.';
END;
GO

-- Триггер на обновление
CREATE TRIGGER trg_RentalWithEquipmentPrice_Update
ON RentalWithEquipmentPrice
INSTEAD OF UPDATE
AS
BEGIN
    -- Перенаправляем обновление данных на таблицу Rental
    UPDATE Rental
    SET rentalDate = inserted.rentalDate,
        returnDate = inserted.returnDate,
        equipmentTypeName = inserted.equipmentTypeName
    FROM Rental
    JOIN inserted ON Rental.id = inserted.RentalID;

    PRINT 'Данные успешно обновлены через представление.';
END;
GO

-- Тестирование вставки
-- Вставляем новую запись через представление
INSERT INTO RentalWithEquipmentPrice (rentalDate, returnDate, equipmentTypeName, EquipmentPrice)
VALUES ('2024-06-01', '2024-06-07', 'Ski Package', 150.00);

-- Проверяем содержимое таблицы Rental
SELECT * FROM Rental;
GO

-- Тестирование удаления
-- Удаляем запись через представление
DELETE FROM RentalWithEquipmentPrice
WHERE RentalID = 1;

-- Проверяем содержимое таблицы Rental
SELECT * FROM Rental;
GO


-- Тестирование обновления
-- Обновляем запись через представление
UPDATE RentalWithEquipmentPrice
SET rentalDate = '2024-07-01', returnDate = '2024-07-08'
WHERE RentalID = 2;

-- Проверяем содержимое таблицы Rental
SELECT * FROM Rental;
GO
