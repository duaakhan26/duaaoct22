-- 01_create_schema.sql
-- Creates DigitalBankDW and the onboarding / payments star schema.
-- SQL Server 2017 or newer. Run this before 02_load_and_validate.sql.
-- Running it again drops the tables and recreates them empty.

IF DB_ID(N'DigitalBankDW') IS NULL
    CREATE DATABASE DigitalBankDW;
GO

USE DigitalBankDW;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DROP TABLE IF EXISTS dbo.FactPayments;
DROP TABLE IF EXISTS dbo.FactApplication;
DROP TABLE IF EXISTS dbo.FactOnboardingEvents;
DROP TABLE IF EXISTS dbo.DimAccount;
DROP TABLE IF EXISTS dbo.DimCustomer;
DROP TABLE IF EXISTS dbo.DimChannel;
DROP TABLE IF EXISTS dbo.DimOnboardingStep;
DROP TABLE IF EXISTS dbo.DimFailureReason;
DROP TABLE IF EXISTS dbo.DimBank;
DROP TABLE IF EXISTS dbo.DimDate;
DROP TABLE IF EXISTS dbo.DimTime;
GO

CREATE TABLE dbo.DimCustomer (
    [CustomerKey] int NOT NULL,
    [CustomerID] varchar(20) NOT NULL,
    [CNICToken] char(16) NOT NULL,
    [AgeBand] varchar(10) NOT NULL,
    [Gender] varchar(10) NOT NULL,
    [Occupation] varchar(20) NOT NULL,
    [Province] varchar(40) NOT NULL,
    [City] varchar(40) NOT NULL,
    [UrbanRural] varchar(10) NOT NULL,
    [MobileNetwork] varchar(20) NOT NULL,
    [DeviceOS] varchar(10) NOT NULL,
    [DeviceBrand] varchar(20) NOT NULL,
    [AppVersion] varchar(10) NOT NULL,
    [SignupDate] date NOT NULL,
    [SignupDateKey] int NOT NULL
);

CREATE TABLE dbo.DimAccount (
    [AccountKey] int NOT NULL,
    [AccountID] varchar(20) NOT NULL,
    [CustomerKey] int NOT NULL,
    [Product] varchar(40) NOT NULL,
    [Tier] varchar(20) NOT NULL,
    [Status] varchar(20) NOT NULL,
    [OpenDateTime] datetime2 NOT NULL,
    [OpenDate] date NOT NULL,
    [OpenDateKey] int NOT NULL,
    [RaastIDLinked] char(1) NOT NULL
);

CREATE TABLE dbo.DimChannel (
    [ChannelKey] int NOT NULL,
    [ChannelName] varchar(40) NOT NULL,
    [ChannelGroup] varchar(20) NOT NULL
);

CREATE TABLE dbo.DimOnboardingStep (
    [StepKey] int NOT NULL,
    [StepName] varchar(80) NOT NULL,
    [StepOrder] int NOT NULL,
    [FunnelStage] varchar(20) NOT NULL
);

CREATE TABLE dbo.DimFailureReason (
    [FailureReasonKey] int NOT NULL,
    [Reason] varchar(80) NOT NULL,
    [Category] varchar(30) NOT NULL,
    [IsRetryable] bit NOT NULL,
    [AppliesTo] varchar(20) NOT NULL
);

CREATE TABLE dbo.DimBank (
    [BankKey] int NOT NULL,
    [BankName] varchar(40) NOT NULL,
    [BankType] varchar(20) NOT NULL
);

CREATE TABLE dbo.DimDate (
    [DateKey] int NOT NULL,
    [FullDate] date NOT NULL,
    [CalendarYear] int NOT NULL,
    [Quarter] int NOT NULL,
    [MonthNumber] int NOT NULL,
    [MonthName] varchar(10) NOT NULL,
    [YearMonth] int NOT NULL,
    [DayOfMonth] int NOT NULL,
    [DayOfWeek] int NOT NULL,
    [DayName] varchar(10) NOT NULL,
    [IsWeekend] bit NOT NULL,
    [IsSalaryWeek] bit NOT NULL,
    [IsRamadan] bit NOT NULL,
    [IsEid] bit NOT NULL,
    [EidName] varchar(20) NULL,
    [IsMonthEnd] bit NOT NULL
);

CREATE TABLE dbo.DimTime (
    [TimeKey] int NOT NULL,
    [HourOfDay] int NOT NULL,
    [HourLabel] char(5) NOT NULL,
    [TimeBand] varchar(20) NOT NULL,
    [IsPeakHour] bit NOT NULL
);

CREATE TABLE dbo.FactOnboardingEvents (
    [EventKey] bigint NOT NULL,
    [CustomerKey] int NOT NULL,
    [StepKey] int NOT NULL,
    [EventDateTime] datetime2 NOT NULL,
    [DateKey] int NOT NULL,
    [TimeKey] int NOT NULL,
    [Outcome] varchar(10) NOT NULL,
    [FailureReasonKey] int NULL,
    [RetryNumber] int NOT NULL,
    [ReferralSource] varchar(30) NOT NULL
);

CREATE TABLE dbo.FactApplication (
    [ApplicationKey] int NOT NULL,
    [CustomerKey] int NOT NULL,
    [AccountKey] int NULL,
    [StartDateTime] datetime2 NOT NULL,
    [StartDateKey] int NOT NULL,
    [StartTimeKey] int NOT NULL,
    [EndDateTime] datetime2 NOT NULL,
    [EndDateKey] int NOT NULL,
    [EndTimeKey] int NOT NULL,
    [FinalStatus] varchar(20) NOT NULL,
    [MinutesToOpen] int NULL,
    [TotalRetries] int NOT NULL,
    [FailedStepKey] int NULL,
    [ActivationDateKey] int NULL,
    [FirstPaymentDateKey] int NULL,
    [FirstPaymentStatus] varchar(20) NOT NULL,
    [ReferralSource] varchar(30) NOT NULL
);

CREATE TABLE dbo.FactPayments (
    [PaymentKey] bigint NOT NULL,
    [PaymentID] varchar(20) NOT NULL,
    [AccountKey] int NOT NULL,
    [ChannelKey] int NOT NULL,
    [BankKey] int NOT NULL,
    [PaymentDateTime] datetime2 NOT NULL,
    [DateKey] int NOT NULL,
    [TimeKey] int NOT NULL,
    [AmountPKR] decimal(18,2) NOT NULL,
    [Status] varchar(10) NOT NULL,
    [FailureReasonKey] int NULL,
    [LatencyMs] int NOT NULL,
    [IsRetry] bit NOT NULL,
    [OriginalPaymentKey] bigint NULL
);

GO

ALTER TABLE dbo.DimCustomer ADD CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerKey);
ALTER TABLE dbo.DimAccount ADD CONSTRAINT PK_DimAccount PRIMARY KEY CLUSTERED (AccountKey);
ALTER TABLE dbo.DimChannel ADD CONSTRAINT PK_DimChannel PRIMARY KEY CLUSTERED (ChannelKey);
ALTER TABLE dbo.DimOnboardingStep ADD CONSTRAINT PK_DimOnboardingStep PRIMARY KEY CLUSTERED (StepKey);
ALTER TABLE dbo.DimFailureReason ADD CONSTRAINT PK_DimFailureReason PRIMARY KEY CLUSTERED (FailureReasonKey);
ALTER TABLE dbo.DimBank ADD CONSTRAINT PK_DimBank PRIMARY KEY CLUSTERED (BankKey);
ALTER TABLE dbo.DimDate ADD CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey);
ALTER TABLE dbo.DimTime ADD CONSTRAINT PK_DimTime PRIMARY KEY CLUSTERED (TimeKey);
ALTER TABLE dbo.FactOnboardingEvents ADD CONSTRAINT PK_FactOnboardingEvents PRIMARY KEY CLUSTERED (EventKey);
ALTER TABLE dbo.FactApplication ADD CONSTRAINT PK_FactApplication PRIMARY KEY CLUSTERED (ApplicationKey);
ALTER TABLE dbo.FactPayments ADD CONSTRAINT PK_FactPayments PRIMARY KEY CLUSTERED (PaymentKey);
GO

ALTER TABLE dbo.DimCustomer ADD CONSTRAINT UX_DimCustomer_CustomerID UNIQUE (CustomerID);
ALTER TABLE dbo.DimAccount ADD CONSTRAINT UX_DimAccount_AccountID UNIQUE (AccountID);
ALTER TABLE dbo.DimAccount ADD CONSTRAINT UX_DimAccount_CustomerKey UNIQUE (CustomerKey);
ALTER TABLE dbo.FactApplication ADD CONSTRAINT UX_FactApplication_CustomerKey UNIQUE (CustomerKey);
ALTER TABLE dbo.FactPayments ADD CONSTRAINT UX_FactPayments_PaymentID UNIQUE (PaymentID);

CREATE UNIQUE INDEX UX_FactApplication_AccountKey
    ON dbo.FactApplication (AccountKey)
    WHERE AccountKey IS NOT NULL;

CREATE INDEX IX_FactPayments_AccountKey ON dbo.FactPayments (AccountKey) INCLUDE (Status, DateKey, ChannelKey);
CREATE INDEX IX_FactPayments_DateKey ON dbo.FactPayments (DateKey) INCLUDE (Status, AmountPKR);
CREATE INDEX IX_FactPayments_ChannelKey ON dbo.FactPayments (ChannelKey) INCLUDE (Status);
CREATE INDEX IX_FactOnboardingEvents_CustomerStep ON dbo.FactOnboardingEvents (CustomerKey, StepKey) INCLUDE (Outcome, EventDateTime);
GO

ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Gender CHECK (Gender IN ('Male', 'Female'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Device CHECK (DeviceOS IN ('Android', 'iOS'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Urban CHECK (UrbanRural IN ('Urban', 'Rural'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Occupation CHECK (Occupation IN ('Salaried', 'Self-employed', 'Student', 'Housewife', 'Freelancer'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Network CHECK (MobileNetwork IN ('Jazz', 'Telenor', 'Zong', 'Ufone'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Age CHECK (AgeBand IN ('18-24', '25-34', '35-44', '45-54', '55+'));
ALTER TABLE dbo.DimCustomer ADD CONSTRAINT CK_DimCustomer_Token CHECK (LEN(CNICToken) = 16 AND CNICToken NOT LIKE '%[^0-9a-f]%');

ALTER TABLE dbo.DimAccount ADD CONSTRAINT CK_DimAccount_Status CHECK (Status IN ('active', 'dormant', 'closed'));
ALTER TABLE dbo.DimAccount ADD CONSTRAINT CK_DimAccount_Tier CHECK (Tier IN ('basic', 'standard'));
ALTER TABLE dbo.DimAccount ADD CONSTRAINT CK_DimAccount_Raast CHECK (RaastIDLinked IN ('Y', 'N'));
ALTER TABLE dbo.DimAccount ADD CONSTRAINT CK_DimAccount_Product CHECK (Product IN ('Current account', 'Savings', 'Virtual debit card', 'Term deposit', 'Micro-loan'));

ALTER TABLE dbo.FactOnboardingEvents ADD CONSTRAINT CK_FactEvents_Outcome CHECK (
    (Outcome = 'Pass' AND FailureReasonKey IS NULL)
    OR (Outcome = 'Fail' AND FailureReasonKey IS NOT NULL)
);
ALTER TABLE dbo.FactOnboardingEvents ADD CONSTRAINT CK_FactEvents_Retry CHECK (RetryNumber >= 0);

ALTER TABLE dbo.FactApplication ADD CONSTRAINT CK_FactApplication_Status CHECK (FinalStatus IN ('Completed', 'Abandoned', 'Rejected'));
ALTER TABLE dbo.FactApplication ADD CONSTRAINT CK_FactApplication_Completion CHECK (
    (
        FinalStatus = 'Completed'
        AND AccountKey IS NOT NULL
        AND MinutesToOpen IS NOT NULL
        AND FailedStepKey IS NULL
    )
    OR (
        FinalStatus IN ('Abandoned', 'Rejected')
        AND AccountKey IS NULL
        AND MinutesToOpen IS NULL
        AND FailedStepKey IS NOT NULL
    )
);
ALTER TABLE dbo.FactApplication ADD CONSTRAINT CK_FactApplication_FirstPayment CHECK (
    (FirstPaymentStatus = 'Not attempted' AND FirstPaymentDateKey IS NULL AND ActivationDateKey IS NULL)
    OR (FirstPaymentStatus = 'Success' AND FirstPaymentDateKey IS NOT NULL AND ActivationDateKey = FirstPaymentDateKey)
    OR (FirstPaymentStatus = 'Failed' AND FirstPaymentDateKey IS NOT NULL)
);
ALTER TABLE dbo.FactApplication ADD CONSTRAINT CK_FactApplication_Incomplete CHECK (
    FinalStatus = 'Completed'
    OR (FirstPaymentStatus = 'Not attempted' AND ActivationDateKey IS NULL AND FirstPaymentDateKey IS NULL)
);

ALTER TABLE dbo.FactPayments ADD CONSTRAINT CK_FactPayments_Status CHECK (Status IN ('Success', 'Failed'));
ALTER TABLE dbo.FactPayments ADD CONSTRAINT CK_FactPayments_Reason CHECK (
    (Status = 'Success' AND FailureReasonKey IS NULL)
    OR (Status = 'Failed' AND FailureReasonKey IS NOT NULL)
);
ALTER TABLE dbo.FactPayments ADD CONSTRAINT CK_FactPayments_Retry CHECK (
    (IsRetry = 0 AND OriginalPaymentKey IS NULL)
    OR (IsRetry = 1 AND OriginalPaymentKey IS NOT NULL)
);
ALTER TABLE dbo.FactPayments ADD CONSTRAINT CK_FactPayments_Amount CHECK (AmountPKR BETWEEN 50 AND 1000000);
ALTER TABLE dbo.FactPayments ADD CONSTRAINT CK_FactPayments_Latency CHECK (LatencyMs > 0);
GO

ALTER TABLE dbo.DimCustomer WITH CHECK ADD CONSTRAINT FK_DimCustomer_SignupDate FOREIGN KEY (SignupDateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.DimAccount WITH CHECK ADD CONSTRAINT FK_DimAccount_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer (CustomerKey);
ALTER TABLE dbo.DimAccount WITH CHECK ADD CONSTRAINT FK_DimAccount_OpenDate FOREIGN KEY (OpenDateKey) REFERENCES dbo.DimDate (DateKey);

ALTER TABLE dbo.FactOnboardingEvents WITH CHECK ADD CONSTRAINT FK_Events_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer (CustomerKey);
ALTER TABLE dbo.FactOnboardingEvents WITH CHECK ADD CONSTRAINT FK_Events_Step FOREIGN KEY (StepKey) REFERENCES dbo.DimOnboardingStep (StepKey);
ALTER TABLE dbo.FactOnboardingEvents WITH CHECK ADD CONSTRAINT FK_Events_Date FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactOnboardingEvents WITH CHECK ADD CONSTRAINT FK_Events_Time FOREIGN KEY (TimeKey) REFERENCES dbo.DimTime (TimeKey);
ALTER TABLE dbo.FactOnboardingEvents WITH CHECK ADD CONSTRAINT FK_Events_Reason FOREIGN KEY (FailureReasonKey) REFERENCES dbo.DimFailureReason (FailureReasonKey);

ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_Customer FOREIGN KEY (CustomerKey) REFERENCES dbo.DimCustomer (CustomerKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_Account FOREIGN KEY (AccountKey) REFERENCES dbo.DimAccount (AccountKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_StartDate FOREIGN KEY (StartDateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_EndDate FOREIGN KEY (EndDateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_StartTime FOREIGN KEY (StartTimeKey) REFERENCES dbo.DimTime (TimeKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_EndTime FOREIGN KEY (EndTimeKey) REFERENCES dbo.DimTime (TimeKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_FailedStep FOREIGN KEY (FailedStepKey) REFERENCES dbo.DimOnboardingStep (StepKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_ActivationDate FOREIGN KEY (ActivationDateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactApplication WITH CHECK ADD CONSTRAINT FK_Application_FirstPaymentDate FOREIGN KEY (FirstPaymentDateKey) REFERENCES dbo.DimDate (DateKey);

ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Account FOREIGN KEY (AccountKey) REFERENCES dbo.DimAccount (AccountKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Channel FOREIGN KEY (ChannelKey) REFERENCES dbo.DimChannel (ChannelKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Bank FOREIGN KEY (BankKey) REFERENCES dbo.DimBank (BankKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Date FOREIGN KEY (DateKey) REFERENCES dbo.DimDate (DateKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Time FOREIGN KEY (TimeKey) REFERENCES dbo.DimTime (TimeKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Reason FOREIGN KEY (FailureReasonKey) REFERENCES dbo.DimFailureReason (FailureReasonKey);
ALTER TABLE dbo.FactPayments WITH CHECK ADD CONSTRAINT FK_Payments_Original FOREIGN KEY (OriginalPaymentKey) REFERENCES dbo.FactPayments (PaymentKey);
GO
