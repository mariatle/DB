USE lab13db1
go

IF OBJECT_ID(N'TypeOfAgreement') IS NOT NULL
	DROP TABLE TypeOfAgreement;
go

CREATE TABLE TypeOfAgreement(
	Name NVarChar(100) PRIMARY KEY NOT NULL,
	Description NVarChar(500),
	AgreementDuration INT NULL,  -- Продолжительность аренды в днях
	DepositRequired BIT NULL
);

USE lab13db2
go

IF OBJECT_ID(N'Agreement') IS NOT NULL
	DROP TABLE Agreement;
go

CREATE TABLE Agreement(
	ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL, 
	Name NVarChar(100) NOT NULL,
	StartTime SmallDateTime NOT NULL DEFAULT GETDATE(),
	EndTime SmallDateTime NULL,
	TypeOfAgreementName NVarChar(100) NOT NULL,  -- Ссылка на тип соглашения
	CustomerID INT NOT NULL,                    -- Идентификатор клиента
	TotalAmount FLOAT NULL,                     -- Общая сумма аренды
	DepositAmount FLOAT NULL,                   -- Сумма залога
	AgreementStatus NVarChar(50) NULL           -- Статус соглашения (например, "Активно", "Завершено")
);
go

USE lab13db2
go

IF OBJECT_ID(N'AgreementView') IS NOT NULL
	DROP VIEW AgreementView;
go

CREATE VIEW AgreementView AS
	SELECT 
		a.ID, 
		a.Name, 
		a.StartTime, 
		a.EndTime, 
		a.TotalAmount, 
		a.DepositAmount, 
		a.AgreementStatus, 
		t.Description AS TypeOfAgreementDescription, 
		t.AgreementDuration, 
		t.DepositRequired
	FROM Agreement AS a
	INNER JOIN lab13db1.dbo.TypeOfAgreement AS t 
		ON a.TypeOfAgreementName = t.Name;
go

select * from AgreementView

USE lab13db1
go

IF OBJECT_ID(N'Type_delete_trg') IS NOT NULL
	DROP TRIGGER Type_delete_trg;
go

IF OBJECT_ID(N'Type_update_trg') IS NOT NULL
	DROP TRIGGER Type_update_trg;
go


CREATE TRIGGER TypeOfAgreement_delete_trg 
ON lab13db1.dbo.TypeOfAgreement
FOR DELETE AS
BEGIN
    DELETE a
    FROM lab13db2.dbo.Agreement AS a
    INNER JOIN deleted AS d
    ON a.TypeOfAgreementName = d.Name;
END
go

CREATE TRIGGER TypeOfAgreement_update_trg
ON lab13db1.dbo.TypeOfAgreement
FOR UPDATE AS
BEGIN
    IF UPDATE(Name)
    BEGIN
        RAISERROR('Нельзя менять название у созданного типа соглашения', 16, 1);
        ROLLBACK;
    END
END
go

USE lab13db2
go

IF OBJECT_ID(N'Agreement_insert_trg') IS NOT NULL
	DROP TRIGGER Agreement_insert_trg;
go

IF OBJECT_ID(N'Agreement_update_trg') IS NOT NULL
	DROP TRIGGER Agreement_update_trg;
go

-- Триггер для обновления данных в Agreement
CREATE TRIGGER Agreement_update_trg ON Agreement
FOR UPDATE AS
BEGIN
    IF UPDATE(TypeOfAgreementName) 
    AND EXISTS (
        SELECT 1 
        FROM lab13db1.dbo.TypeOfAgreement AS type
        RIGHT JOIN inserted ON inserted.TypeOfAgreementName = type.Name
        WHERE type.Name IS NULL -- Если в TypeOfAgreement нет соответствующего типа соглашения
    )
    BEGIN
        RAISERROR('При обновлении необходимо выбрать существующий тип соглашения', 16, 1);
        ROLLBACK;
    END
END
go

-- Триггер для вставки данных в Agreement
CREATE TRIGGER Agreement_insert_trg ON Agreement
FOR INSERT AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM lab13db1.dbo.TypeOfAgreement AS type
        RIGHT JOIN inserted ON inserted.TypeOfAgreementName = type.Name
        WHERE type.Name IS NULL -- Если в TypeOfAgreement нет соответствующего типа соглашения
    )
    BEGIN
        RAISERROR('При вставке необходимо выбрать существующий тип соглашения', 16, 1);
        ROLLBACK;
    END
END
go


USE lab13db1
go

INSERT INTO TypeOfAgreement (Name, Description, AgreementDuration, DepositRequired) VALUES
(N'Ежедневная аренда', N'Аренда на один день', 1, 1),  -- 1 день аренды, требуется залог
(N'Сезонная аренда', N'Аренда на весь сезон', 90, 1),  -- 90 дней аренды, требуется залог
(N'Экспресс-аренда', N'Аренда на 3 часа', 0, 0);        -- 3 часа аренды, без залога
go

SELECT * FROM TypeOfAgreement;
go

USE lab13db2
go

INSERT INTO Agreement (Name, StartTime, EndTime, TypeOfAgreementName, CustomerID, TotalAmount, DepositAmount, AgreementStatus) VALUES
(N'Аренда на 1 день', '2024-12-24', '2024-12-24', N'Ежедневная аренда', 1, 1500.0, 500.0, N'Активно'),
(N'Аренда на сезон', '2024-12-01', '2025-03-01', N'Сезонная аренда', 2, 5000.0, 1500.0, N'Активно');
go

SELECT * FROM AgreementView;
go





--1. Тестирование триггера TypeOfAgreement_delete_trg
INSERT INTO Agreement (Name, StartTime, EndTime, TypeOfAgreementName, CustomerID, TotalAmount, DepositAmount, AgreementStatus) 
VALUES (N'Аренда на 1 день', '2024-12-24', '2024-12-24', N'Ежедневная аренда', 1, 1500.0, 500.0, N'Активно');

USE lab13db1
go

DELETE FROM TypeOfAgreement WHERE Name = N'Ежедневная аренда';

use lab13db2
go

SELECT * FROM Agreement WHERE TypeOfAgreementName = N'Ежедневная аренда';



use lab13db1
go
--2. Тестирование триггера TypeOfAgreement_update_trg
UPDATE TypeOfAgreement
SET Name = N'Экспресс-аренда 2'
WHERE Name = N'Экспресс-аренда';


SELECT * FROM TypeOfAgreement WHERE Name = N'Экспресс-аренда';


-- Попробуем вставить новое соглашение с несуществующим типом соглашения
INSERT INTO lab13db2.dbo.Agreement (Name, StartTime, EndTime, TypeOfAgreementName, CustomerID, TotalAmount, DepositAmount, AgreementStatus)
VALUES (N'Аренда на 1 день', '2024-12-24', '2024-12-24', N'Не существующий тип аренды', 1, 1500.0, 500.0, N'Активно');


-- Попробуем обновить тип соглашения на несуществующий тип
UPDATE lab13db2.dbo.Agreement
SET TypeOfAgreementName = N'Не существующий тип аренды'
WHERE Name = N'Аренда на 1 день';


-- Проверим вставленные данные
SELECT * FROM lab13db2.dbo.Agreement;


-- Вставим новые записи
INSERT INTO lab13db2.dbo.Agreement (Name, StartTime, EndTime, TypeOfAgreementName, CustomerID, TotalAmount, DepositAmount, AgreementStatus)
VALUES (N'Аренда на 1 день', '2024-12-24', '2024-12-24', N'Ежедневная аренда', 1, 1500.0, 500.0, N'Активно'),
       (N'Аренда на сезон', '2024-12-01', '2025-03-01', N'Сезонная аренда', 2, 5000.0, 1500.0, N'Активно');

-- Проверим вставленные данные
SELECT * FROM lab13db2.dbo.Agreement;
