-- 02_load_and_validate.sql
-- Run 01_create_schema.sql first.
-- 1. Copy the csv folder onto the SQL Server machine, for example C:\DigitalBankData\
--    DimCustomer.csv must sit directly in that folder.
-- 2. Set @DataPath below. The SQL Server service account has to be able to read it.
-- 3. Execute this script.
-- The load prints row counts. The validation grid is PASS, FAIL, or INFO.
-- Any FAIL raises an error after the grid.
-- CSV line endings are LF. A trailing CR is stripped, so a CRLF copy still loads.

USE DigitalBankDW;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF SCHEMA_ID(N'stg') IS NULL
    EXEC(N'CREATE SCHEMA stg');
GO

DROP TABLE IF EXISTS stg.FactPayments;
DROP TABLE IF EXISTS stg.FactApplication;
DROP TABLE IF EXISTS stg.FactOnboardingEvents;
DROP TABLE IF EXISTS stg.DimAccount;
DROP TABLE IF EXISTS stg.DimCustomer;
DROP TABLE IF EXISTS stg.DimChannel;
DROP TABLE IF EXISTS stg.DimOnboardingStep;
DROP TABLE IF EXISTS stg.DimFailureReason;
DROP TABLE IF EXISTS stg.DimBank;
DROP TABLE IF EXISTS stg.DimDate;
DROP TABLE IF EXISTS stg.DimTime;

CREATE TABLE stg.DimCustomer (
    [CustomerKey] nvarchar(120) NULL,
    [CustomerID] nvarchar(120) NULL,
    [CNICToken] nvarchar(120) NULL,
    [AgeBand] nvarchar(120) NULL,
    [Gender] nvarchar(120) NULL,
    [Occupation] nvarchar(120) NULL,
    [Province] nvarchar(120) NULL,
    [City] nvarchar(120) NULL,
    [UrbanRural] nvarchar(120) NULL,
    [MobileNetwork] nvarchar(120) NULL,
    [DeviceOS] nvarchar(120) NULL,
    [DeviceBrand] nvarchar(120) NULL,
    [AppVersion] nvarchar(120) NULL,
    [SignupDate] nvarchar(120) NULL,
    [SignupDateKey] nvarchar(120) NULL
);

CREATE TABLE stg.DimAccount (
    [AccountKey] nvarchar(120) NULL,
    [AccountID] nvarchar(120) NULL,
    [CustomerKey] nvarchar(120) NULL,
    [Product] nvarchar(120) NULL,
    [Tier] nvarchar(120) NULL,
    [Status] nvarchar(120) NULL,
    [OpenDateTime] nvarchar(120) NULL,
    [OpenDate] nvarchar(120) NULL,
    [OpenDateKey] nvarchar(120) NULL,
    [RaastIDLinked] nvarchar(120) NULL
);

CREATE TABLE stg.DimChannel (
    [ChannelKey] nvarchar(120) NULL,
    [ChannelName] nvarchar(120) NULL,
    [ChannelGroup] nvarchar(120) NULL
);

CREATE TABLE stg.DimOnboardingStep (
    [StepKey] nvarchar(120) NULL,
    [StepName] nvarchar(120) NULL,
    [StepOrder] nvarchar(120) NULL,
    [FunnelStage] nvarchar(120) NULL
);

CREATE TABLE stg.DimFailureReason (
    [FailureReasonKey] nvarchar(120) NULL,
    [Reason] nvarchar(120) NULL,
    [Category] nvarchar(120) NULL,
    [IsRetryable] nvarchar(120) NULL,
    [AppliesTo] nvarchar(120) NULL
);

CREATE TABLE stg.DimBank (
    [BankKey] nvarchar(120) NULL,
    [BankName] nvarchar(120) NULL,
    [BankType] nvarchar(120) NULL
);

CREATE TABLE stg.DimDate (
    [DateKey] nvarchar(120) NULL,
    [FullDate] nvarchar(120) NULL,
    [CalendarYear] nvarchar(120) NULL,
    [Quarter] nvarchar(120) NULL,
    [MonthNumber] nvarchar(120) NULL,
    [MonthName] nvarchar(120) NULL,
    [YearMonth] nvarchar(120) NULL,
    [DayOfMonth] nvarchar(120) NULL,
    [DayOfWeek] nvarchar(120) NULL,
    [DayName] nvarchar(120) NULL,
    [IsWeekend] nvarchar(120) NULL,
    [IsSalaryWeek] nvarchar(120) NULL,
    [IsRamadan] nvarchar(120) NULL,
    [IsEid] nvarchar(120) NULL,
    [EidName] nvarchar(120) NULL,
    [IsMonthEnd] nvarchar(120) NULL
);

CREATE TABLE stg.DimTime (
    [TimeKey] nvarchar(120) NULL,
    [HourOfDay] nvarchar(120) NULL,
    [HourLabel] nvarchar(120) NULL,
    [TimeBand] nvarchar(120) NULL,
    [IsPeakHour] nvarchar(120) NULL
);

CREATE TABLE stg.FactOnboardingEvents (
    [EventKey] nvarchar(120) NULL,
    [CustomerKey] nvarchar(120) NULL,
    [StepKey] nvarchar(120) NULL,
    [EventDateTime] nvarchar(120) NULL,
    [DateKey] nvarchar(120) NULL,
    [TimeKey] nvarchar(120) NULL,
    [Outcome] nvarchar(120) NULL,
    [FailureReasonKey] nvarchar(120) NULL,
    [RetryNumber] nvarchar(120) NULL,
    [ReferralSource] nvarchar(120) NULL
);

CREATE TABLE stg.FactApplication (
    [ApplicationKey] nvarchar(120) NULL,
    [CustomerKey] nvarchar(120) NULL,
    [AccountKey] nvarchar(120) NULL,
    [StartDateTime] nvarchar(120) NULL,
    [StartDateKey] nvarchar(120) NULL,
    [StartTimeKey] nvarchar(120) NULL,
    [EndDateTime] nvarchar(120) NULL,
    [EndDateKey] nvarchar(120) NULL,
    [EndTimeKey] nvarchar(120) NULL,
    [FinalStatus] nvarchar(120) NULL,
    [MinutesToOpen] nvarchar(120) NULL,
    [TotalRetries] nvarchar(120) NULL,
    [FailedStepKey] nvarchar(120) NULL,
    [ActivationDateKey] nvarchar(120) NULL,
    [FirstPaymentDateKey] nvarchar(120) NULL,
    [FirstPaymentStatus] nvarchar(120) NULL,
    [ReferralSource] nvarchar(120) NULL
);

CREATE TABLE stg.FactPayments (
    [PaymentKey] nvarchar(120) NULL,
    [PaymentID] nvarchar(120) NULL,
    [AccountKey] nvarchar(120) NULL,
    [ChannelKey] nvarchar(120) NULL,
    [BankKey] nvarchar(120) NULL,
    [PaymentDateTime] nvarchar(120) NULL,
    [DateKey] nvarchar(120) NULL,
    [TimeKey] nvarchar(120) NULL,
    [AmountPKR] nvarchar(120) NULL,
    [Status] nvarchar(120) NULL,
    [FailureReasonKey] nvarchar(120) NULL,
    [LatencyMs] nvarchar(120) NULL,
    [IsRetry] nvarchar(120) NULL,
    [OriginalPaymentKey] nvarchar(120) NULL
);

GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DataPath nvarchar(400) = N'C:\DigitalBankData\';
DECLARE @sql nvarchar(max);
DECLARE @actual int;
DECLARE @msg nvarchar(400);

IF RIGHT(@DataPath, 1) <> N'\'
    SET @DataPath += N'\';

IF EXISTS (SELECT 1 FROM dbo.DimCustomer)
    THROW 50001, N'Tables are not empty. Run 01_create_schema.sql before loading again.', 1;

TRUNCATE TABLE stg.DimDate;
SET @sql = N'BULK INSERT stg.DimDate
    FROM ''' + @DataPath + N'DimDate.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimDate);
IF @actual <> 365
BEGIN
    SET @msg = N'DimDate.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 365.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimDate ([DateKey], [FullDate], [CalendarYear], [Quarter], [MonthNumber], [MonthName], [YearMonth], [DayOfMonth], [DayOfWeek], [DayName], [IsWeekend], [IsSalaryWeek], [IsRamadan], [IsEid], [EidName], [IsMonthEnd])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[DateKey], CHAR(13), ''), '')) AS [DateKey],
        TRY_CONVERT(date, NULLIF(REPLACE(s.[FullDate], CHAR(13), ''), '')) AS [FullDate],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[CalendarYear], CHAR(13), ''), '')) AS [CalendarYear],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[Quarter], CHAR(13), ''), '')) AS [Quarter],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[MonthNumber], CHAR(13), ''), '')) AS [MonthNumber],
        NULLIF(REPLACE(s.[MonthName], CHAR(13), ''), '') AS [MonthName],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[YearMonth], CHAR(13), ''), '')) AS [YearMonth],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[DayOfMonth], CHAR(13), ''), '')) AS [DayOfMonth],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[DayOfWeek], CHAR(13), ''), '')) AS [DayOfWeek],
        NULLIF(REPLACE(s.[DayName], CHAR(13), ''), '') AS [DayName],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsWeekend], CHAR(13), ''), '')) AS [IsWeekend],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsSalaryWeek], CHAR(13), ''), '')) AS [IsSalaryWeek],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsRamadan], CHAR(13), ''), '')) AS [IsRamadan],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsEid], CHAR(13), ''), '')) AS [IsEid],
        NULLIF(REPLACE(s.[EidName], CHAR(13), ''), '') AS [EidName],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsMonthEnd], CHAR(13), ''), '')) AS [IsMonthEnd]
FROM stg.DimDate AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimDate.csv could not be converted into dbo.DimDate. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimTime;
SET @sql = N'BULK INSERT stg.DimTime
    FROM ''' + @DataPath + N'DimTime.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimTime);
IF @actual <> 24
BEGIN
    SET @msg = N'DimTime.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 24.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimTime ([TimeKey], [HourOfDay], [HourLabel], [TimeBand], [IsPeakHour])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[TimeKey], CHAR(13), ''), '')) AS [TimeKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[HourOfDay], CHAR(13), ''), '')) AS [HourOfDay],
        NULLIF(REPLACE(s.[HourLabel], CHAR(13), ''), '') AS [HourLabel],
        NULLIF(REPLACE(s.[TimeBand], CHAR(13), ''), '') AS [TimeBand],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsPeakHour], CHAR(13), ''), '')) AS [IsPeakHour]
FROM stg.DimTime AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimTime.csv could not be converted into dbo.DimTime. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimChannel;
SET @sql = N'BULK INSERT stg.DimChannel
    FROM ''' + @DataPath + N'DimChannel.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimChannel);
IF @actual <> 7
BEGIN
    SET @msg = N'DimChannel.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 7.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimChannel ([ChannelKey], [ChannelName], [ChannelGroup])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[ChannelKey], CHAR(13), ''), '')) AS [ChannelKey],
        NULLIF(REPLACE(s.[ChannelName], CHAR(13), ''), '') AS [ChannelName],
        NULLIF(REPLACE(s.[ChannelGroup], CHAR(13), ''), '') AS [ChannelGroup]
FROM stg.DimChannel AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimChannel.csv could not be converted into dbo.DimChannel. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimOnboardingStep;
SET @sql = N'BULK INSERT stg.DimOnboardingStep
    FROM ''' + @DataPath + N'DimOnboardingStep.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimOnboardingStep);
IF @actual <> 8
BEGIN
    SET @msg = N'DimOnboardingStep.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 8.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimOnboardingStep ([StepKey], [StepName], [StepOrder], [FunnelStage])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[StepKey], CHAR(13), ''), '')) AS [StepKey],
        NULLIF(REPLACE(s.[StepName], CHAR(13), ''), '') AS [StepName],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[StepOrder], CHAR(13), ''), '')) AS [StepOrder],
        NULLIF(REPLACE(s.[FunnelStage], CHAR(13), ''), '') AS [FunnelStage]
FROM stg.DimOnboardingStep AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimOnboardingStep.csv could not be converted into dbo.DimOnboardingStep. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimFailureReason;
SET @sql = N'BULK INSERT stg.DimFailureReason
    FROM ''' + @DataPath + N'DimFailureReason.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimFailureReason);
IF @actual <> 14
BEGIN
    SET @msg = N'DimFailureReason.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 14.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimFailureReason ([FailureReasonKey], [Reason], [Category], [IsRetryable], [AppliesTo])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[FailureReasonKey], CHAR(13), ''), '')) AS [FailureReasonKey],
        NULLIF(REPLACE(s.[Reason], CHAR(13), ''), '') AS [Reason],
        NULLIF(REPLACE(s.[Category], CHAR(13), ''), '') AS [Category],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsRetryable], CHAR(13), ''), '')) AS [IsRetryable],
        NULLIF(REPLACE(s.[AppliesTo], CHAR(13), ''), '') AS [AppliesTo]
FROM stg.DimFailureReason AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimFailureReason.csv could not be converted into dbo.DimFailureReason. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimBank;
SET @sql = N'BULK INSERT stg.DimBank
    FROM ''' + @DataPath + N'DimBank.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimBank);
IF @actual <> 34
BEGIN
    SET @msg = N'DimBank.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 34.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimBank ([BankKey], [BankName], [BankType])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[BankKey], CHAR(13), ''), '')) AS [BankKey],
        NULLIF(REPLACE(s.[BankName], CHAR(13), ''), '') AS [BankName],
        NULLIF(REPLACE(s.[BankType], CHAR(13), ''), '') AS [BankType]
FROM stg.DimBank AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimBank.csv could not be converted into dbo.DimBank. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimCustomer;
SET @sql = N'BULK INSERT stg.DimCustomer
    FROM ''' + @DataPath + N'DimCustomer.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimCustomer);
IF @actual <> 50000
BEGIN
    SET @msg = N'DimCustomer.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 50000.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimCustomer ([CustomerKey], [CustomerID], [CNICToken], [AgeBand], [Gender], [Occupation], [Province], [City], [UrbanRural], [MobileNetwork], [DeviceOS], [DeviceBrand], [AppVersion], [SignupDate], [SignupDateKey])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[CustomerKey], CHAR(13), ''), '')) AS [CustomerKey],
        NULLIF(REPLACE(s.[CustomerID], CHAR(13), ''), '') AS [CustomerID],
        NULLIF(REPLACE(s.[CNICToken], CHAR(13), ''), '') AS [CNICToken],
        NULLIF(REPLACE(s.[AgeBand], CHAR(13), ''), '') AS [AgeBand],
        NULLIF(REPLACE(s.[Gender], CHAR(13), ''), '') AS [Gender],
        NULLIF(REPLACE(s.[Occupation], CHAR(13), ''), '') AS [Occupation],
        NULLIF(REPLACE(s.[Province], CHAR(13), ''), '') AS [Province],
        NULLIF(REPLACE(s.[City], CHAR(13), ''), '') AS [City],
        NULLIF(REPLACE(s.[UrbanRural], CHAR(13), ''), '') AS [UrbanRural],
        NULLIF(REPLACE(s.[MobileNetwork], CHAR(13), ''), '') AS [MobileNetwork],
        NULLIF(REPLACE(s.[DeviceOS], CHAR(13), ''), '') AS [DeviceOS],
        NULLIF(REPLACE(s.[DeviceBrand], CHAR(13), ''), '') AS [DeviceBrand],
        NULLIF(REPLACE(s.[AppVersion], CHAR(13), ''), '') AS [AppVersion],
        TRY_CONVERT(date, NULLIF(REPLACE(s.[SignupDate], CHAR(13), ''), '')) AS [SignupDate],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[SignupDateKey], CHAR(13), ''), '')) AS [SignupDateKey]
FROM stg.DimCustomer AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimCustomer.csv could not be converted into dbo.DimCustomer. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.DimAccount;
SET @sql = N'BULK INSERT stg.DimAccount
    FROM ''' + @DataPath + N'DimAccount.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.DimAccount);
IF @actual <> 36366
BEGIN
    SET @msg = N'DimAccount.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 36366.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.DimAccount ([AccountKey], [AccountID], [CustomerKey], [Product], [Tier], [Status], [OpenDateTime], [OpenDate], [OpenDateKey], [RaastIDLinked])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[AccountKey], CHAR(13), ''), '')) AS [AccountKey],
        NULLIF(REPLACE(s.[AccountID], CHAR(13), ''), '') AS [AccountID],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[CustomerKey], CHAR(13), ''), '')) AS [CustomerKey],
        NULLIF(REPLACE(s.[Product], CHAR(13), ''), '') AS [Product],
        NULLIF(REPLACE(s.[Tier], CHAR(13), ''), '') AS [Tier],
        NULLIF(REPLACE(s.[Status], CHAR(13), ''), '') AS [Status],
        TRY_CONVERT(datetime2, NULLIF(REPLACE(s.[OpenDateTime], CHAR(13), ''), ''), 120) AS [OpenDateTime],
        TRY_CONVERT(date, NULLIF(REPLACE(s.[OpenDate], CHAR(13), ''), '')) AS [OpenDate],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[OpenDateKey], CHAR(13), ''), '')) AS [OpenDateKey],
        NULLIF(REPLACE(s.[RaastIDLinked], CHAR(13), ''), '') AS [RaastIDLinked]
FROM stg.DimAccount AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'DimAccount.csv could not be converted into dbo.DimAccount. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.FactOnboardingEvents;
SET @sql = N'BULK INSERT stg.FactOnboardingEvents
    FROM ''' + @DataPath + N'FactOnboardingEvents.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.FactOnboardingEvents);
IF @actual <> 339338
BEGIN
    SET @msg = N'FactOnboardingEvents.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 339338.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.FactOnboardingEvents ([EventKey], [CustomerKey], [StepKey], [EventDateTime], [DateKey], [TimeKey], [Outcome], [FailureReasonKey], [RetryNumber], [ReferralSource])
SELECT
        TRY_CONVERT(bigint, NULLIF(REPLACE(s.[EventKey], CHAR(13), ''), '')) AS [EventKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[CustomerKey], CHAR(13), ''), '')) AS [CustomerKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[StepKey], CHAR(13), ''), '')) AS [StepKey],
        TRY_CONVERT(datetime2, NULLIF(REPLACE(s.[EventDateTime], CHAR(13), ''), ''), 120) AS [EventDateTime],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[DateKey], CHAR(13), ''), '')) AS [DateKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[TimeKey], CHAR(13), ''), '')) AS [TimeKey],
        NULLIF(REPLACE(s.[Outcome], CHAR(13), ''), '') AS [Outcome],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[FailureReasonKey], CHAR(13), ''), '')) AS [FailureReasonKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[RetryNumber], CHAR(13), ''), '')) AS [RetryNumber],
        NULLIF(REPLACE(s.[ReferralSource], CHAR(13), ''), '') AS [ReferralSource]
FROM stg.FactOnboardingEvents AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'FactOnboardingEvents.csv could not be converted into dbo.FactOnboardingEvents. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.FactApplication;
SET @sql = N'BULK INSERT stg.FactApplication
    FROM ''' + @DataPath + N'FactApplication.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.FactApplication);
IF @actual <> 50000
BEGIN
    SET @msg = N'FactApplication.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 50000.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.FactApplication ([ApplicationKey], [CustomerKey], [AccountKey], [StartDateTime], [StartDateKey], [StartTimeKey], [EndDateTime], [EndDateKey], [EndTimeKey], [FinalStatus], [MinutesToOpen], [TotalRetries], [FailedStepKey], [ActivationDateKey], [FirstPaymentDateKey], [FirstPaymentStatus], [ReferralSource])
SELECT
        TRY_CONVERT(int, NULLIF(REPLACE(s.[ApplicationKey], CHAR(13), ''), '')) AS [ApplicationKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[CustomerKey], CHAR(13), ''), '')) AS [CustomerKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[AccountKey], CHAR(13), ''), '')) AS [AccountKey],
        TRY_CONVERT(datetime2, NULLIF(REPLACE(s.[StartDateTime], CHAR(13), ''), ''), 120) AS [StartDateTime],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[StartDateKey], CHAR(13), ''), '')) AS [StartDateKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[StartTimeKey], CHAR(13), ''), '')) AS [StartTimeKey],
        TRY_CONVERT(datetime2, NULLIF(REPLACE(s.[EndDateTime], CHAR(13), ''), ''), 120) AS [EndDateTime],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[EndDateKey], CHAR(13), ''), '')) AS [EndDateKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[EndTimeKey], CHAR(13), ''), '')) AS [EndTimeKey],
        NULLIF(REPLACE(s.[FinalStatus], CHAR(13), ''), '') AS [FinalStatus],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[MinutesToOpen], CHAR(13), ''), '')) AS [MinutesToOpen],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[TotalRetries], CHAR(13), ''), '')) AS [TotalRetries],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[FailedStepKey], CHAR(13), ''), '')) AS [FailedStepKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[ActivationDateKey], CHAR(13), ''), '')) AS [ActivationDateKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[FirstPaymentDateKey], CHAR(13), ''), '')) AS [FirstPaymentDateKey],
        NULLIF(REPLACE(s.[FirstPaymentStatus], CHAR(13), ''), '') AS [FirstPaymentStatus],
        NULLIF(REPLACE(s.[ReferralSource], CHAR(13), ''), '') AS [ReferralSource]
FROM stg.FactApplication AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'FactApplication.csv could not be converted into dbo.FactApplication. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

TRUNCATE TABLE stg.FactPayments;
SET @sql = N'BULK INSERT stg.FactPayments
    FROM ''' + @DataPath + N'FactPayments.csv''
    WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', TABLOCK, KEEPNULLS);';
EXEC (@sql);
SET @actual = (SELECT COUNT(*) FROM stg.FactPayments);
IF @actual <> 100871
BEGIN
    SET @msg = N'FactPayments.csv loaded ' + CAST(@actual AS nvarchar(20)) + N' rows, expected 100871.';
    THROW 50002, @msg, 1;
END;
INSERT INTO dbo.FactPayments ([PaymentKey], [PaymentID], [AccountKey], [ChannelKey], [BankKey], [PaymentDateTime], [DateKey], [TimeKey], [AmountPKR], [Status], [FailureReasonKey], [LatencyMs], [IsRetry], [OriginalPaymentKey])
SELECT
        TRY_CONVERT(bigint, NULLIF(REPLACE(s.[PaymentKey], CHAR(13), ''), '')) AS [PaymentKey],
        NULLIF(REPLACE(s.[PaymentID], CHAR(13), ''), '') AS [PaymentID],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[AccountKey], CHAR(13), ''), '')) AS [AccountKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[ChannelKey], CHAR(13), ''), '')) AS [ChannelKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[BankKey], CHAR(13), ''), '')) AS [BankKey],
        TRY_CONVERT(datetime2, NULLIF(REPLACE(s.[PaymentDateTime], CHAR(13), ''), ''), 120) AS [PaymentDateTime],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[DateKey], CHAR(13), ''), '')) AS [DateKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[TimeKey], CHAR(13), ''), '')) AS [TimeKey],
        TRY_CONVERT(decimal(18,2), NULLIF(REPLACE(s.[AmountPKR], CHAR(13), ''), '')) AS [AmountPKR],
        NULLIF(REPLACE(s.[Status], CHAR(13), ''), '') AS [Status],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[FailureReasonKey], CHAR(13), ''), '')) AS [FailureReasonKey],
        TRY_CONVERT(int, NULLIF(REPLACE(s.[LatencyMs], CHAR(13), ''), '')) AS [LatencyMs],
        TRY_CONVERT(bit, NULLIF(REPLACE(s.[IsRetry], CHAR(13), ''), '')) AS [IsRetry],
        TRY_CONVERT(bigint, NULLIF(REPLACE(s.[OriginalPaymentKey], CHAR(13), ''), '')) AS [OriginalPaymentKey]
FROM stg.FactPayments AS s;
IF @@ROWCOUNT <> @actual
BEGIN
    SET @msg = N'FactPayments.csv could not be converted into dbo.FactPayments. A blank landed in a required column or a value was not a valid type.';
    THROW 50003, @msg, 1;
END;

SELECT 'DimCustomer' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimCustomer
UNION ALL
SELECT 'DimAccount' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimAccount
UNION ALL
SELECT 'DimChannel' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimChannel
UNION ALL
SELECT 'DimOnboardingStep' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimOnboardingStep
UNION ALL
SELECT 'DimFailureReason' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimFailureReason
UNION ALL
SELECT 'DimBank' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimBank
UNION ALL
SELECT 'DimDate' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimDate
UNION ALL
SELECT 'DimTime' AS TableName, COUNT(*) AS LoadedRows FROM dbo.DimTime
UNION ALL
SELECT 'FactOnboardingEvents' AS TableName, COUNT(*) AS LoadedRows FROM dbo.FactOnboardingEvents
UNION ALL
SELECT 'FactApplication' AS TableName, COUNT(*) AS LoadedRows FROM dbo.FactApplication
UNION ALL
SELECT 'FactPayments' AS TableName, COUNT(*) AS LoadedRows FROM dbo.FactPayments
ORDER BY TableName;

DROP TABLE IF EXISTS stg.FactPayments;
DROP TABLE IF EXISTS stg.FactApplication;
DROP TABLE IF EXISTS stg.FactOnboardingEvents;
DROP TABLE IF EXISTS stg.DimAccount;
DROP TABLE IF EXISTS stg.DimCustomer;
DROP TABLE IF EXISTS stg.DimChannel;
DROP TABLE IF EXISTS stg.DimOnboardingStep;
DROP TABLE IF EXISTS stg.DimFailureReason;
DROP TABLE IF EXISTS stg.DimBank;
DROP TABLE IF EXISTS stg.DimDate;
DROP TABLE IF EXISTS stg.DimTime;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET DATEFIRST 1;

IF NOT EXISTS (SELECT 1 FROM dbo.DimDate) OR NOT EXISTS (SELECT 1 FROM dbo.FactPayments)
    THROW 50011, N'The load did not finish. Fix the error above, then run this script again.', 1;

DROP TABLE IF EXISTS #Check;
CREATE TABLE #Check (
    CheckName nvarchar(200) NOT NULL,
    Status varchar(10) NOT NULL,
    Detail nvarchar(1000) NOT NULL
);

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Android-heavy device mix',
    CASE WHEN share BETWEEN 0.75 AND 0.82 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'Android share ', CAST(ROUND(share * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT 1.0 * SUM(CASE WHEN DeviceOS = N'Android' THEN 1 ELSE 0 END) / COUNT(*) AS share
    FROM dbo.DimCustomer
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'CNIC tokens',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' tokens are not 16-character synthetic hashes')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.DimCustomer
    WHERE LEN(CNICToken) <> 16
       OR CNICToken LIKE N'%[^0-9a-f]%'
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'City belongs to one province',
    CASE WHEN cities = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(cities, N' cities span provinces')
FROM (
    SELECT COUNT(*) AS cities
    FROM (
        SELECT City
        FROM dbo.DimCustomer
        GROUP BY City
        HAVING COUNT(DISTINCT Province) > 1
    ) AS city
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Calendar flags',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' dates break salary-week, Ramadan, Eid, weekend, or month-end rules')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.DimDate
    WHERE IsSalaryWeek <> CASE WHEN DAY(FullDate) = 1 OR DAY(FullDate) >= 25 THEN 1 ELSE 0 END
       OR IsWeekend <> CASE WHEN DATEPART(WEEKDAY, FullDate) IN (6, 7) THEN 1 ELSE 0 END
       OR IsMonthEnd <> CASE WHEN DAY(FullDate) >= 28 THEN 1 ELSE 0 END
       OR IsRamadan <> CASE WHEN FullDate BETWEEN '20260218' AND '20260319' THEN 1 ELSE 0 END
       OR IsEid <> CASE
            WHEN FullDate BETWEEN '20260320' AND '20260322' THEN 1
            WHEN FullDate BETWEEN '20260527' AND '20260529' THEN 1
            ELSE 0
          END
       OR ISNULL(EidName, N'') <> CASE
            WHEN FullDate BETWEEN '20260320' AND '20260322' THEN N'Eid ul Fitr'
            WHEN FullDate BETWEEN '20260527' AND '20260529' THEN N'Eid ul Adha'
            ELSE N''
          END
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Peak hours',
    CASE WHEN bad = 0 AND rows = 24 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'DimTime rows ', rows, N'; mismatches ', bad)
FROM (
    SELECT
        COUNT(*) AS rows,
        SUM(CASE
            WHEN (TimeKey IN (12, 13, 14, 19, 20, 21) AND IsPeakHour = 1)
              OR (TimeKey NOT IN (12, 13, 14, 19, 20, 21) AND IsPeakHour = 0)
            THEN 0 ELSE 1 END) AS bad
    FROM dbo.DimTime
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Every customer starts at download',
    CASE WHEN missing = 0 AND apps = customers THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'missing download ', missing, N'; applications ', apps, N'; customers ', customers)
FROM (
    SELECT
        (SELECT COUNT(*) FROM dbo.DimCustomer c
         WHERE NOT EXISTS (
            SELECT 1 FROM dbo.FactOnboardingEvents e
            WHERE e.CustomerKey = c.CustomerKey AND e.StepKey = 1
         )) AS missing,
        (SELECT COUNT(*) FROM dbo.FactApplication) AS apps,
        (SELECT COUNT(*) FROM dbo.DimCustomer) AS customers
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Funnel is sequential through account opening',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' steps are not exactly the prior step''s passes')
FROM (
    SELECT COUNT(*) AS bad
    FROM (
        SELECT s.StepOrder, COUNT(DISTINCT e.CustomerKey) AS Attempted
        FROM dbo.FactOnboardingEvents e
        JOIN dbo.DimOnboardingStep s ON s.StepKey = e.StepKey
        WHERE s.StepOrder BETWEEN 1 AND 6
        GROUP BY s.StepOrder
    ) AS attempted
    JOIN (
        SELECT s.StepOrder, COUNT(DISTINCT e.CustomerKey) AS Passed
        FROM dbo.FactOnboardingEvents e
        JOIN dbo.DimOnboardingStep s ON s.StepKey = e.StepKey
        WHERE s.StepOrder BETWEEN 1 AND 6 AND e.Outcome = N'Pass'
        GROUP BY s.StepOrder
    ) AS previous ON previous.StepOrder = attempted.StepOrder - 1
    WHERE attempted.StepOrder BETWEEN 2 AND 6
      AND attempted.Attempted <> previous.Passed
) AS s;

;WITH passed AS (
    SELECT s.StepOrder,
           COUNT(DISTINCT CASE WHEN e.Outcome = N'Pass' THEN e.CustomerKey END) AS PassedCustomers
    FROM dbo.DimOnboardingStep s
    LEFT JOIN dbo.FactOnboardingEvents e ON e.StepKey = s.StepKey
    WHERE s.StepOrder BETWEEN 1 AND 6
    GROUP BY s.StepOrder
),
drops AS (
    SELECT
        StepOrder,
        CASE
            WHEN StepOrder = 1 THEN (SELECT COUNT(*) FROM dbo.DimCustomer) - PassedCustomers
            ELSE LAG(PassedCustomers) OVER (ORDER BY StepOrder) - PassedCustomers
        END AS DropOff
    FROM passed
)
INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Heaviest drop is NADRA liveness',
    CASE WHEN (SELECT TOP (1) StepOrder FROM drops ORDER BY DropOff DESC, StepOrder) = 4 THEN N'PASS' ELSE N'FAIL' END,
    ISNULL((SELECT STRING_AGG(CONCAT(N'step ', StepOrder, N' drop ', DropOff), N'; ') WITHIN GROUP (ORDER BY StepOrder) FROM drops), N'no onboarding steps loaded');

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Older Android app builds fail NADRA more often',
    CASE WHEN current_rate >= legacy_rate + 0.08 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(
        N'legacy Android pass ', CAST(ROUND(legacy_rate * 100, 1) AS decimal(5, 1)), N'%; current app pass ',
        CAST(ROUND(current_rate * 100, 1) AS decimal(5, 1)), N'%'
    )
FROM (
    SELECT
        AVG(CASE WHEN c.DeviceOS = N'Android' AND c.AppVersion IN (N'3.2.0', N'3.8.1') THEN n.Passed * 1.0 END) AS legacy_rate,
        AVG(CASE WHEN c.AppVersion IN (N'4.4.2', N'4.6.0') THEN n.Passed * 1.0 END) AS current_rate
    FROM (
        SELECT e.CustomerKey, MAX(CASE WHEN e.Outcome = N'Pass' THEN 1 ELSE 0 END) AS Passed
        FROM dbo.FactOnboardingEvents e
        WHERE e.StepKey = 4
        GROUP BY e.CustomerKey
    ) AS n
    JOIN dbo.DimCustomer c ON c.CustomerKey = n.CustomerKey
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Application matches onboarding events',
    CASE WHEN mismatches = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(mismatches, N' applications disagree with FactOnboardingEvents')
FROM (
    SELECT COUNT(*) AS mismatches
    FROM dbo.FactApplication a
    JOIN (
        SELECT
            e.CustomerKey,
            MIN(e.EventDateTime) AS StartDateTime,
            MAX(e.EventDateTime) AS LastDateTime,
            MIN(CASE WHEN e.StepKey = 6 AND e.Outcome = N'Pass' THEN e.EventDateTime END) AS OpenedDateTime,
            SUM(CASE WHEN e.RetryNumber > 0 THEN 1 ELSE 0 END) AS TotalRetries
        FROM dbo.FactOnboardingEvents e
        GROUP BY e.CustomerKey
    ) AS ev ON ev.CustomerKey = a.CustomerKey
    JOIN (
        SELECT CustomerKey, StepKey, FailureReasonKey
        FROM (
            SELECT
                e.CustomerKey,
                e.StepKey,
                e.FailureReasonKey,
                ROW_NUMBER() OVER (PARTITION BY e.CustomerKey ORDER BY e.EventDateTime DESC, e.EventKey DESC) AS rn
            FROM dbo.FactOnboardingEvents e
        ) AS ordered
        WHERE rn = 1
    ) AS terminal ON terminal.CustomerKey = a.CustomerKey
    WHERE a.StartDateTime <> ev.StartDateTime
       OR a.TotalRetries <> ev.TotalRetries
       OR EXISTS (
            SELECT 1 FROM dbo.FactOnboardingEvents e
            WHERE e.CustomerKey = a.CustomerKey AND e.ReferralSource <> a.ReferralSource
       )
       OR (
            a.FinalStatus = N'Completed'
            AND (
                ev.OpenedDateTime IS NULL
                OR a.EndDateTime <> ev.OpenedDateTime
                OR a.MinutesToOpen <> DATEDIFF(MINUTE, ev.StartDateTime, ev.OpenedDateTime)
                OR a.FailedStepKey IS NOT NULL
                OR a.AccountKey IS NULL
            )
       )
       OR (
            a.FinalStatus <> N'Completed'
            AND (
                ev.OpenedDateTime IS NOT NULL
                OR a.EndDateTime <> ev.LastDateTime
                OR a.MinutesToOpen IS NOT NULL
                OR a.FailedStepKey <> terminal.StepKey
                OR a.AccountKey IS NOT NULL
                OR a.FinalStatus <> CASE WHEN terminal.FailureReasonKey IN (1, 5, 6) THEN N'Rejected' ELSE N'Abandoned' END
            )
       )
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Signup date matches journey start',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' mismatches')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactApplication a
    JOIN dbo.DimCustomer c ON c.CustomerKey = a.CustomerKey
    WHERE c.SignupDate <> CONVERT(date, a.StartDateTime)
       OR c.SignupDateKey <> a.StartDateKey
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Application payment summary matches FactPayments',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' mismatches')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactApplication a
    LEFT JOIN (
        SELECT AccountKey, Status, DateKey, FailureReasonKey, PaymentDateTime
        FROM (
            SELECT
                AccountKey, Status, DateKey, FailureReasonKey, PaymentDateTime,
                ROW_NUMBER() OVER (PARTITION BY AccountKey ORDER BY PaymentDateTime, PaymentKey) AS rn
            FROM dbo.FactPayments
        ) AS ranked
        WHERE rn = 1
    ) AS first_pay ON first_pay.AccountKey = a.AccountKey
    LEFT JOIN (
        SELECT AccountKey, MIN(DateKey) AS ActivationDateKey
        FROM dbo.FactPayments
        WHERE Status = N'Success'
        GROUP BY AccountKey
    ) AS act ON act.AccountKey = a.AccountKey
    WHERE (a.FinalStatus <> N'Completed' AND (a.FirstPaymentStatus <> N'Not attempted' OR a.FirstPaymentDateKey IS NOT NULL OR a.ActivationDateKey IS NOT NULL))
       OR (a.FinalStatus = N'Completed' AND first_pay.AccountKey IS NULL AND (a.FirstPaymentStatus <> N'Not attempted' OR a.ActivationDateKey IS NOT NULL OR a.FirstPaymentDateKey IS NOT NULL))
       OR (first_pay.AccountKey IS NOT NULL AND (
            a.FirstPaymentStatus <> first_pay.Status
            OR a.FirstPaymentDateKey <> first_pay.DateKey
            OR ISNULL(a.ActivationDateKey, -1) <> ISNULL(act.ActivationDateKey, -1)
       ))
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'First-payment step matches the first attempt',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' step mismatches')
FROM (
    SELECT COUNT(*) AS bad
    FROM (
        SELECT AccountKey, Status, FailureReasonKey, PaymentDateTime
        FROM (
            SELECT
                AccountKey, Status, FailureReasonKey, PaymentDateTime,
                ROW_NUMBER() OVER (PARTITION BY AccountKey ORDER BY PaymentDateTime, PaymentKey) AS rn
            FROM dbo.FactPayments
        ) AS ranked
        WHERE rn = 1
    ) AS first_pay
    JOIN dbo.DimAccount a ON a.AccountKey = first_pay.AccountKey
    FULL OUTER JOIN (
        SELECT CustomerKey, EventDateTime, Outcome, FailureReasonKey
        FROM dbo.FactOnboardingEvents
        WHERE StepKey = 8
    ) AS step8 ON step8.CustomerKey = a.CustomerKey
    WHERE step8.CustomerKey IS NULL
       OR first_pay.AccountKey IS NULL
       OR step8.EventDateTime <> first_pay.PaymentDateTime
       OR step8.Outcome <> CASE WHEN first_pay.Status = N'Success' THEN N'Pass' ELSE N'Fail' END
       OR ISNULL(step8.FailureReasonKey, -1) <> ISNULL(first_pay.FailureReasonKey, -1)
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Payments stay inside opened accounts',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' payments are missing an account or are dated before it opened')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactPayments p
    LEFT JOIN dbo.DimAccount a ON a.AccountKey = p.AccountKey
    WHERE a.AccountKey IS NULL OR p.PaymentDateTime < a.OpenDateTime
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Payment date and time keys match the timestamp',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' payments')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactPayments
    WHERE DateKey <> (YEAR(PaymentDateTime) * 10000 + MONTH(PaymentDateTime) * 100 + DAY(PaymentDateTime))
       OR TimeKey <> DATEPART(HOUR, PaymentDateTime)
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Onboarding date and time keys match the timestamp',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' events')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactOnboardingEvents
    WHERE DateKey <> (YEAR(EventDateTime) * 10000 + MONTH(EventDateTime) * 100 + DAY(EventDateTime))
       OR TimeKey <> DATEPART(HOUR, EventDateTime)
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Retries point at the original attempt',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' broken retry links')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactPayments r
    LEFT JOIN dbo.FactPayments o ON o.PaymentKey = r.OriginalPaymentKey
    WHERE (r.IsRetry = 1 AND (o.PaymentKey IS NULL OR o.IsRetry = 1 OR o.AccountKey <> r.AccountKey))
       OR (r.IsRetry = 0 AND r.OriginalPaymentKey IS NOT NULL)
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Account status matches payment activity',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' status mismatches')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.DimAccount a
    JOIN dbo.FactApplication app ON app.AccountKey = a.AccountKey
    WHERE (a.Status = N'active' AND NOT EXISTS (
            SELECT 1 FROM dbo.FactPayments p WHERE p.AccountKey = a.AccountKey AND p.Status = N'Success'))
       OR (a.Status = N'dormant' AND EXISTS (
            SELECT 1 FROM dbo.FactPayments p WHERE p.AccountKey = a.AccountKey AND p.Status = N'Success'))
       OR app.FinalStatus <> N'Completed'
       OR app.EndDateTime <> a.OpenDateTime
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Closed accounts were opened before 1 Apr 2026',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' closed too recently')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.DimAccount
    WHERE Status = N'closed' AND OpenDate >= '20260401'
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Raast ID is linked after a successful Raast payment',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' accounts')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.DimAccount a
    WHERE a.RaastIDLinked <> N'Y'
      AND EXISTS (
        SELECT 1
        FROM dbo.FactPayments p
        WHERE p.AccountKey = a.AccountKey
          AND p.Status = N'Success'
          AND p.ChannelKey IN (1, 2)
      )
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Dormancy is material',
    CASE WHEN rate BETWEEN 0.12 AND 0.40 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'dormant accounts ', CAST(ROUND(rate * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT 1.0 * SUM(CASE WHEN Status = N'dormant' THEN 1 ELSE 0 END) / COUNT(*) AS rate
    FROM dbo.DimAccount
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'IBFT fails more often than Raast P2P',
    CASE WHEN ibft >= raast + 0.03 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'IBFT ', CAST(ROUND(ibft * 100, 1) AS decimal(5, 1)), N'%; Raast P2P ', CAST(ROUND(raast * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        1.0 * SUM(CASE WHEN ChannelKey = 3 AND Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ChannelKey = 3 THEN 1 ELSE 0 END), 0) AS ibft,
        1.0 * SUM(CASE WHEN ChannelKey = 1 AND Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ChannelKey = 1 THEN 1 ELSE 0 END), 0) AS raast
    FROM dbo.FactPayments
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Bill pay fails more often than Raast P2P',
    CASE WHEN bill >= raast + 0.03 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'bill pay ', CAST(ROUND(bill * 100, 1) AS decimal(5, 1)), N'%; Raast P2P ', CAST(ROUND(raast * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        1.0 * SUM(CASE WHEN ChannelKey = 5 AND Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ChannelKey = 5 THEN 1 ELSE 0 END), 0) AS bill,
        1.0 * SUM(CASE WHEN ChannelKey = 1 AND Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN ChannelKey = 1 THEN 1 ELSE 0 END), 0) AS raast
    FROM dbo.FactPayments
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'First payment fails more often than later payments',
    CASE WHEN first_rate >= later_rate + 0.03 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'first ', CAST(ROUND(first_rate * 100, 1) AS decimal(5, 1)), N'%; later ', CAST(ROUND(later_rate * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        AVG(CASE WHEN rn = 1 THEN CASE WHEN Status = N'Failed' THEN 1.0 ELSE 0 END END) AS first_rate,
        AVG(CASE WHEN rn > 1 THEN CASE WHEN Status = N'Failed' THEN 1.0 ELSE 0 END END) AS later_rate
    FROM (
        SELECT Status, ROW_NUMBER() OVER (PARTITION BY AccountKey ORDER BY PaymentDateTime, PaymentKey) AS rn
        FROM dbo.FactPayments
    ) AS ranked
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Failures are higher at peak hours',
    CASE WHEN peak_rate >= off_rate * 1.12 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'peak ', CAST(ROUND(peak_rate * 100, 1) AS decimal(5, 1)), N'%; off-peak ', CAST(ROUND(off_rate * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        1.0 * SUM(CASE WHEN t.IsPeakHour = 1 AND p.Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN t.IsPeakHour = 1 THEN 1 ELSE 0 END), 0) AS peak_rate,
        1.0 * SUM(CASE WHEN t.IsPeakHour = 0 AND p.Status = N'Failed' THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN t.IsPeakHour = 0 THEN 1 ELSE 0 END), 0) AS off_rate
    FROM dbo.FactPayments p
    JOIN dbo.DimTime t ON t.TimeKey = p.TimeKey
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Some retries recover and some do not',
    CASE WHEN recovery BETWEEN 0.55 AND 0.85 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'retry success ', CAST(ROUND(recovery * 100, 1) AS decimal(5, 1)), N'% of ', retries)
FROM (
    SELECT
        1.0 * SUM(CASE WHEN Status = N'Success' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS recovery,
        COUNT(*) AS retries
    FROM dbo.FactPayments
    WHERE IsRetry = 1
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Bank timeouts concentrate in a few beneficiary banks',
    CASE WHEN timeouts > 0 AND volume_share < 0.15 AND timeout_share >= 0.50 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(
        N'Allied/JS/BOP are ', CAST(ROUND(volume_share * 100, 1) AS decimal(5, 1)),
        N'% of payments and ', CAST(ROUND(timeout_share * 100, 1) AS decimal(5, 1)),
        N'% of bank timeouts (', timeouts, N')'
    )
FROM (
    SELECT
        1.0 * SUM(CASE WHEN b.BankName IN (N'Allied Bank', N'JS Bank', N'Bank of Punjab') THEN 1 ELSE 0 END) / COUNT(*) AS volume_share,
        1.0 * SUM(CASE WHEN p.FailureReasonKey = 12 AND b.BankName IN (N'Allied Bank', N'JS Bank', N'Bank of Punjab') THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN p.FailureReasonKey = 12 THEN 1 ELSE 0 END), 0) AS timeout_share,
        SUM(CASE WHEN p.FailureReasonKey = 12 THEN 1 ELSE 0 END) AS timeouts
    FROM dbo.FactPayments p
    JOIN dbo.DimBank b ON b.BankKey = p.BankKey
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Small P2P and bill payments dominate the count',
    CASE WHEN top_channel = 1 AND share >= 0.45 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'top channel key ', top_channel, N'; P2P+bill ', CAST(ROUND(share * 100, 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        (SELECT TOP (1) ChannelKey FROM dbo.FactPayments GROUP BY ChannelKey ORDER BY COUNT(*) DESC) AS top_channel,
        1.0 * SUM(CASE WHEN ChannelKey IN (1, 5) THEN 1 ELSE 0 END) / COUNT(*) AS share
    FROM dbo.FactPayments
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Amounts are skewed, with a long tail',
    CASE WHEN median_amount * 2 < mean_amount THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'median ', CAST(ROUND(median_amount, 0) AS bigint), N' PKR; mean ', CAST(ROUND(mean_amount, 0) AS bigint), N' PKR')
FROM (
    SELECT AVG(AmountPKR * 1.0) AS mean_amount
    FROM dbo.FactPayments
) AS means
CROSS JOIN (
    SELECT TOP (1) PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY AmountPKR) OVER () AS median_amount
    FROM dbo.FactPayments
) AS medians;

;WITH daily AS (
    SELECT d.IsSalaryWeek, d.IsEid, COUNT(p.PaymentKey) AS Cnt
    FROM dbo.DimDate d
    LEFT JOIN dbo.FactPayments p ON p.DateKey = d.DateKey
    WHERE d.FullDate >= '20251001' AND d.FullDate <= '20260930'
    GROUP BY d.FullDate, d.IsSalaryWeek, d.IsEid
)
INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Salary week has more payments per day',
    CASE WHEN salary_avg >= normal_avg * 1.50 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'salary-week ', CAST(ROUND(salary_avg, 0) AS bigint), N'/day; other days ', CAST(ROUND(normal_avg, 0) AS bigint), N'/day')
FROM (
    SELECT
        AVG(CASE WHEN IsSalaryWeek = 1 AND IsEid = 0 THEN Cnt * 1.0 END) AS salary_avg,
        AVG(CASE WHEN IsSalaryWeek = 0 AND IsEid = 0 THEN Cnt * 1.0 END) AS normal_avg
    FROM daily
) AS s;

;WITH daily AS (
    SELECT d.IsSalaryWeek, d.IsEid, COUNT(p.PaymentKey) AS Cnt
    FROM dbo.DimDate d
    LEFT JOIN dbo.FactPayments p ON p.DateKey = d.DateKey
    WHERE d.FullDate >= '20251001' AND d.FullDate <= '20260930'
    GROUP BY d.FullDate, d.IsSalaryWeek, d.IsEid
)
INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Eid has more payments per day',
    CASE WHEN eid_avg >= normal_avg * 2.0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(N'Eid ', CAST(ROUND(eid_avg, 0) AS bigint), N'/day; other days ', CAST(ROUND(normal_avg, 0) AS bigint), N'/day')
FROM (
    SELECT
        AVG(CASE WHEN IsEid = 1 THEN Cnt * 1.0 END) AS eid_avg,
        AVG(CASE WHEN IsSalaryWeek = 0 AND IsEid = 0 THEN Cnt * 1.0 END) AS normal_avg
    FROM daily
) AS s;

IF (SELECT COUNT(*) FROM dbo.DimCustomer) >= 40000
INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Scale is about 50,000 applications and 100,000 payments',
    CASE WHEN customers = 50000 AND payments BETWEEN 90000 AND 110000 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(customers, N' applications; ', payments, N' payments')
FROM (
    SELECT
        (SELECT COUNT(*) FROM dbo.DimCustomer) AS customers,
        (SELECT COUNT(*) FROM dbo.FactPayments) AS payments
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Conversion %',
    N'INFO',
    CONCAT(CAST(ROUND(100.0 * completed / NULLIF(started, 0), 1) AS decimal(5, 1)), N'% completed (', completed, N' of ', started, N')')
FROM (
    SELECT
        COUNT(*) AS started,
        SUM(CASE WHEN FinalStatus = N'Completed' THEN 1 ELSE 0 END) AS completed
    FROM dbo.FactApplication
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT TOP (1)
    N'Median minutes to open',
    N'INFO',
    CONCAT(CAST(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MinutesToOpen) OVER (), 0) AS int), N'')
FROM dbo.FactApplication
WHERE FinalStatus = N'Completed';

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Activation rate within 30 days',
    N'INFO',
    CONCAT(CAST(ROUND(100.0 * activated / NULLIF(completed, 0), 1) AS decimal(5, 1)), N'% of completed applications')
FROM (
    SELECT
        COUNT(*) AS completed,
        SUM(CASE
            WHEN a.ActivationDateKey IS NOT NULL AND DATEDIFF(DAY, ac.OpenDate, d.FullDate) <= 30 THEN 1
            ELSE 0
        END) AS activated
    FROM dbo.FactApplication a
    LEFT JOIN dbo.DimAccount ac ON ac.AccountKey = a.AccountKey
    LEFT JOIN dbo.DimDate d ON d.DateKey = a.ActivationDateKey
    WHERE a.FinalStatus = N'Completed'
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'First-payment success rate',
    N'INFO',
    CONCAT(CAST(ROUND(100.0 * successes / NULLIF(attempted, 0), 1) AS decimal(5, 1)), N'%')
FROM (
    SELECT
        SUM(CASE WHEN FirstPaymentStatus = N'Success' THEN 1 ELSE 0 END) AS successes,
        SUM(CASE WHEN FirstPaymentStatus IN (N'Success', N'Failed') THEN 1 ELSE 0 END) AS attempted
    FROM dbo.FactApplication
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Failed payment value',
    N'INFO',
    CONCAT(CAST(ROUND(SUM(AmountPKR), 0) AS bigint), N' PKR')
FROM dbo.FactPayments
WHERE Status = N'Failed';

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Average latency',
    N'INFO',
    CONCAT(CAST(ROUND(AVG(LatencyMs * 1.0), 0) AS bigint), N' ms')
FROM dbo.FactPayments;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Dormancy rate',
    N'INFO',
    CONCAT(CAST(ROUND(100.0 * SUM(CASE WHEN Status = N'dormant' THEN 1 ELSE 0 END) / COUNT(*), 1) AS decimal(5, 1)), N'% of opened accounts')
FROM dbo.DimAccount;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    CONCAT(N'Failure rate ', c.ChannelName),
    N'INFO',
    CONCAT(
        CAST(ROUND(100.0 * SUM(CASE WHEN p.Status = N'Failed' THEN 1 ELSE 0 END) / COUNT(*), 1) AS decimal(5, 1)),
        N'% of ', COUNT(*)
    )
FROM dbo.FactPayments p
JOIN dbo.DimChannel c ON c.ChannelKey = p.ChannelKey
GROUP BY c.ChannelName;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Onboarding failure reasons match the step',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' events')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactOnboardingEvents e
    LEFT JOIN dbo.DimFailureReason r ON r.FailureReasonKey = e.FailureReasonKey
    WHERE (e.Outcome = N'Pass' AND e.FailureReasonKey IS NOT NULL)
       OR (e.Outcome = N'Fail' AND (e.FailureReasonKey IS NULL OR r.FailureReasonKey IS NULL))
       OR (e.Outcome = N'Fail' AND e.StepKey <= 7 AND r.AppliesTo NOT IN (N'Onboarding', N'Both'))
       OR (e.Outcome = N'Fail' AND e.StepKey = 8 AND r.AppliesTo NOT IN (N'Payment', N'Both'))
) AS s;

INSERT INTO #Check (CheckName, Status, Detail)
SELECT
    N'Failure reasons match payment status',
    CASE WHEN bad = 0 THEN N'PASS' ELSE N'FAIL' END,
    CONCAT(bad, N' payments')
FROM (
    SELECT COUNT(*) AS bad
    FROM dbo.FactPayments p
    LEFT JOIN dbo.DimFailureReason r ON r.FailureReasonKey = p.FailureReasonKey
    WHERE (p.Status = N'Success' AND p.FailureReasonKey IS NOT NULL)
       OR (p.Status = N'Failed' AND (p.FailureReasonKey IS NULL OR r.AppliesTo NOT IN (N'Payment', N'Both')))
) AS s;

SELECT CheckName, Status, Detail
FROM #Check
ORDER BY CASE Status WHEN N'FAIL' THEN 0 WHEN N'PASS' THEN 1 ELSE 2 END, CheckName;

IF EXISTS (SELECT 1 FROM #Check WHERE Status = N'FAIL')
    THROW 50010, N'Validation failed. Review the result grid for FAIL rows.', 1;
GO
