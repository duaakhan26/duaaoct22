-- Browsing views for SSMS. Run after 03_add_keys.sql.
-- vw_Application.ActivatedWithin30Days is the activation flag used by the self-service measures.

USE DigitalBankDW;
GO

CREATE OR ALTER VIEW dbo.vw_OnboardingFunnel
AS
SELECT
    s.StepOrder,
    s.StepName,
    s.FunnelStage,
    COUNT(DISTINCT e.CustomerKey) AS CustomersAttempted,
    COUNT(DISTINCT CASE WHEN e.Outcome = N'Pass' THEN e.CustomerKey END) AS CustomersPassed
FROM dbo.DimOnboardingStep AS s
LEFT JOIN dbo.FactOnboardingEvents AS e
    ON e.StepKey = s.StepKey
GROUP BY s.StepOrder, s.StepName, s.FunnelStage;
GO

CREATE OR ALTER VIEW dbo.vw_Application
AS
SELECT
    a.ApplicationKey,
    a.CustomerKey,
    a.AccountKey,
    a.StartDateTime,
    a.EndDateTime,
    a.FinalStatus,
    a.MinutesToOpen,
    a.TotalRetries,
    a.FailedStepKey,
    s.StepName AS FailedStep,
    a.ActivationDateKey,
    a.FirstPaymentDateKey,
    a.FirstPaymentStatus,
    a.ReferralSource,
    cu.AgeBand,
    cu.Gender,
    cu.Occupation,
    cu.Province,
    cu.City,
    cu.UrbanRural,
    cu.MobileNetwork,
    cu.DeviceOS,
    cu.DeviceBrand,
    cu.AppVersion,
    ac.Product,
    ac.Tier,
    ac.Status AS AccountStatus,
    ac.OpenDate,
    ac.RaastIDLinked,
    CASE
        WHEN a.FinalStatus = N'Completed'
         AND a.ActivationDateKey IS NOT NULL
         AND DATEDIFF(DAY, ac.OpenDate, act.FullDate) <= 30 THEN 1
        WHEN a.FinalStatus = N'Completed' THEN 0
    END AS ActivatedWithin30Days
FROM dbo.FactApplication AS a
JOIN dbo.DimCustomer AS cu
    ON cu.CustomerKey = a.CustomerKey
LEFT JOIN dbo.DimAccount AS ac
    ON ac.AccountKey = a.AccountKey
LEFT JOIN dbo.DimOnboardingStep AS s
    ON s.StepKey = a.FailedStepKey
LEFT JOIN dbo.DimDate AS act
    ON act.DateKey = a.ActivationDateKey;
GO

CREATE OR ALTER VIEW dbo.vw_Payments
AS
SELECT
    p.PaymentKey,
    p.PaymentID,
    p.PaymentDateTime,
    p.AmountPKR,
    p.Status,
    p.LatencyMs,
    p.IsRetry,
    p.OriginalPaymentKey,
    c.ChannelName,
    c.ChannelGroup,
    b.BankName,
    b.BankType,
    r.Reason AS FailureReason,
    r.Category AS FailureCategory,
    r.IsRetryable,
    d.FullDate,
    d.CalendarYear,
    d.MonthName,
    d.IsSalaryWeek,
    d.IsEid,
    d.EidName,
    d.IsRamadan,
    t.HourLabel,
    t.TimeBand,
    t.IsPeakHour,
    a.Product,
    a.Tier,
    a.Status AS AccountStatus,
    a.RaastIDLinked,
    cu.Province,
    cu.City,
    cu.UrbanRural,
    cu.AgeBand,
    cu.Occupation,
    cu.DeviceOS,
    cu.DeviceBrand,
    cu.AppVersion,
    cu.MobileNetwork
FROM dbo.FactPayments AS p
JOIN dbo.DimAccount AS a
    ON a.AccountKey = p.AccountKey
JOIN dbo.DimCustomer AS cu
    ON cu.CustomerKey = a.CustomerKey
JOIN dbo.DimChannel AS c
    ON c.ChannelKey = p.ChannelKey
JOIN dbo.DimBank AS b
    ON b.BankKey = p.BankKey
JOIN dbo.DimDate AS d
    ON d.DateKey = p.DateKey
JOIN dbo.DimTime AS t
    ON t.TimeKey = p.TimeKey
LEFT JOIN dbo.DimFailureReason AS r
    ON r.FailureReasonKey = p.FailureReasonKey;
GO
