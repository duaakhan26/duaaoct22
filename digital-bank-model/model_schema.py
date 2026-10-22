"""Shared definitions for the digital-bank onboarding and payments star schema.

The shape follows the flattened model from the Claude working session:
seven dimension groups (DimDate and DimTime counted together) and three facts.
Facts use integer surrogate keys. Date keys are yyyymmdd.
"""

from __future__ import annotations

from datetime import date, datetime

CALENDAR_START = date(2025, 10, 1)
AS_OF = date(2026, 9, 30)
CALENDAR_END = date(2026, 10, 3)

RAMADAN_START = date(2026, 2, 18)
RAMADAN_END = date(2026, 3, 19)
EID_FITR = (date(2026, 3, 20), date(2026, 3, 22))
EID_ADHA = (date(2026, 5, 27), date(2026, 5, 29))
CLOSED_BEFORE = date(2026, 4, 1)

PEAK_HOURS = (12, 13, 14, 19, 20, 21)
LEGACY_APPS = ("3.2.0", "3.8.1")
CURRENT_APPS = ("4.4.2", "4.6.0")
OLDER_ANDROID_BRANDS = ("Infinix", "Tecno", "Huawei")
HIGH_RISK_BANKS = ("Allied Bank", "JS Bank", "Bank of Punjab")

# FailureReasonKey values. Names match the working session.
NADRA_MISMATCH = 1
LIVENESS_FAILED = 2
DOCUMENT_UNCLEAR = 3
ABANDONED = 4
SANCTIONS = 5
DUPLICATE = 6
INSUFFICIENT_FUNDS = 7
WRONG_ACCOUNT = 8
LIMIT_EXCEEDED = 9
OTP_EXPIRED = 10
RAIL_TIMEOUT = 11
BANK_TIMEOUT = 12
FRAUD_BLOCK = 13
BILLER_DOWNTIME = 14

REJECT_REASONS = (NADRA_MISMATCH, SANCTIONS, DUPLICATE)
RETRYABLE_REASONS = {
    LIVENESS_FAILED,
    DOCUMENT_UNCLEAR,
    INSUFFICIENT_FUNDS,
    WRONG_ACCOUNT,
    OTP_EXPIRED,
    RAIL_TIMEOUT,
    BANK_TIMEOUT,
    BILLER_DOWNTIME,
}

FAILURE_REASONS = [
    # key, reason, category, is_retryable, applies_to
    (NADRA_MISMATCH, "NADRA mismatch", "fraud/compliance", 0, "Onboarding"),
    (LIVENESS_FAILED, "Liveness failed", "customer", 1, "Onboarding"),
    (DOCUMENT_UNCLEAR, "Document unclear", "customer", 1, "Onboarding"),
    (ABANDONED, "Abandoned", "customer", 0, "Onboarding"),
    (SANCTIONS, "Sanctions/AML screening hit", "fraud/compliance", 0, "Onboarding"),
    (DUPLICATE, "Duplicate account", "fraud/compliance", 0, "Onboarding"),
    (INSUFFICIENT_FUNDS, "Insufficient funds", "customer", 1, "Payment"),
    (WRONG_ACCOUNT, "Wrong account or IBAN", "customer", 1, "Payment"),
    (LIMIT_EXCEEDED, "Limit exceeded", "customer", 0, "Payment"),
    (OTP_EXPIRED, "OTP expired", "customer", 1, "Both"),
    (RAIL_TIMEOUT, "Rail timeout", "network/rail", 1, "Payment"),
    (BANK_TIMEOUT, "Beneficiary bank timeout", "network/rail", 1, "Payment"),
    (FRAUD_BLOCK, "Fraud-rule block", "fraud/compliance", 0, "Payment"),
    (BILLER_DOWNTIME, "Biller downtime", "bank-side", 1, "Payment"),
]

ONBOARDING_STEPS = [
    # key, name, order, stage
    (1, "Download app", 1, "Acquisition"),
    (2, "Mobile OTP", 2, "Verification"),
    (3, "CNIC capture", 3, "Verification"),
    (4, "NADRA biometric and selfie liveness", 4, "Verification"),
    (5, "Address and profile", 5, "Opening"),
    (6, "Account opened", 6, "Opening"),
    (7, "First login", 7, "Activation"),
    (8, "First payment", 8, "Activation"),
]

CHANNELS = [
    # key, name, group, volume weight, base failure probability
    (1, "Raast P2P", "Raast", 0.34, 0.035),
    (2, "Raast QR", "Raast", 0.12, 0.045),
    (3, "1LINK IBFT", "IBFT", 0.11, 0.150),
    (4, "Intra-bank transfer", "Internal", 0.08, 0.020),
    (5, "Bill pay", "Bills", 0.18, 0.125),
    (6, "Mobile top-up", "Top-up", 0.12, 0.055),
    (7, "Card", "Card", 0.05, 0.050),
]

BANKS = [
    # key, name, type, beneficiary weight (0 = not a P2P/IBFT beneficiary)
    (1, "Own Digital Bank", "Internal", 0),
    (2, "HBL", "Bank", 16),
    (3, "UBL", "Bank", 13),
    (4, "MCB", "Bank", 12),
    (5, "Meezan Bank", "Bank", 12),
    (6, "Allied Bank", "Bank", 3),
    (7, "Bank Alfalah", "Bank", 10),
    (8, "Habib Metro", "Bank", 5),
    (9, "Bank Al Habib", "Bank", 7),
    (10, "Faysal Bank", "Bank", 5),
    (11, "Askari Bank", "Bank", 4),
    (12, "JS Bank", "Bank", 2),
    (13, "Soneri Bank", "Bank", 2),
    (14, "Standard Chartered", "Bank", 3),
    (15, "NBP", "Bank", 5),
    (16, "Bank of Punjab", "Bank", 2),
    (17, "Sindh Bank", "Bank", 2),
    (18, "K-Electric", "Biller", 0),
    (19, "LESCO", "Biller", 0),
    (20, "IESCO", "Biller", 0),
    (21, "SNGPL", "Biller", 0),
    (22, "SSGC", "Biller", 0),
    (23, "PTCL", "Biller", 0),
    (24, "Nayatel", "Biller", 0),
    (25, "1Bill", "Biller", 0),
    (26, "Jazz", "Biller", 0),
    (27, "Telenor", "Biller", 0),
    (28, "Zong", "Biller", 0),
    (29, "Ufone", "Biller", 0),
    (30, "Food and grocery QR", "Merchant", 0),
    (31, "Retail QR", "Merchant", 0),
    (32, "Transport QR", "Merchant", 0),
    (33, "E-commerce", "Merchant", 0),
    (34, "Card acceptance", "Merchant", 0),
]

# city, province, urban/rural, weight
CITIES = [
    ("Karachi", "Sindh", "Urban", 18),
    ("Lahore", "Punjab", "Urban", 16),
    ("Islamabad", "Islamabad", "Urban", 8),
    ("Rawalpindi", "Punjab", "Urban", 7),
    ("Faisalabad", "Punjab", "Urban", 5),
    ("Peshawar", "Khyber Pakhtunkhwa", "Urban", 4),
    ("Multan", "Punjab", "Urban", 4),
    ("Hyderabad", "Sindh", "Urban", 3),
    ("Gujranwala", "Punjab", "Urban", 3),
    ("Quetta", "Balochistan", "Urban", 2),
    ("Sialkot", "Punjab", "Urban", 2),
    ("Bahawalpur", "Punjab", "Urban", 2),
    ("Sargodha", "Punjab", "Urban", 1.5),
    ("Sukkur", "Sindh", "Urban", 1.5),
    ("Larkana", "Sindh", "Urban", 1),
    ("Abbottabad", "Khyber Pakhtunkhwa", "Urban", 1.2),
    ("Mardan", "Khyber Pakhtunkhwa", "Urban", 1.2),
    ("Mingora", "Khyber Pakhtunkhwa", "Urban", 0.8),
    ("Gujrat", "Punjab", "Urban", 1),
    ("Sahiwal", "Punjab", "Urban", 1),
    ("Muzaffarabad", "Azad Kashmir", "Urban", 0.8),
    ("Mirpur", "Azad Kashmir", "Urban", 0.7),
    ("Gilgit", "Gilgit-Baltistan", "Urban", 0.5),
    ("Gwadar", "Balochistan", "Urban", 0.4),
    ("Kasur", "Punjab", "Rural", 2),
    ("Okara", "Punjab", "Rural", 1.5),
    ("Sheikhupura", "Punjab", "Rural", 1.5),
    ("Jhang", "Punjab", "Rural", 1.2),
    ("Rahim Yar Khan", "Punjab", "Rural", 1.5),
    ("Dadu", "Sindh", "Rural", 1),
    ("Thatta", "Sindh", "Rural", 0.8),
    ("Charsadda", "Khyber Pakhtunkhwa", "Rural", 0.8),
    ("Swabi", "Khyber Pakhtunkhwa", "Rural", 0.7),
    ("Khuzdar", "Balochistan", "Rural", 0.5),
    ("Turbat", "Balochistan", "Rural", 0.4),
    ("Kotli", "Azad Kashmir", "Rural", 0.4),
    ("Skardu", "Gilgit-Baltistan", "Rural", 0.3),
]

# Column order is the CSV header order and the CREATE TABLE order.
TABLES: dict[str, list[tuple[str, str]]] = {
    "DimCustomer": [
        ("CustomerKey", "int"),
        ("CustomerID", "varchar(20)"),
        ("CNICToken", "char(16)"),
        ("AgeBand", "varchar(10)"),
        ("Gender", "varchar(10)"),
        ("Occupation", "varchar(20)"),
        ("Province", "varchar(40)"),
        ("City", "varchar(40)"),
        ("UrbanRural", "varchar(10)"),
        ("MobileNetwork", "varchar(20)"),
        ("DeviceOS", "varchar(10)"),
        ("DeviceBrand", "varchar(20)"),
        ("AppVersion", "varchar(10)"),
        ("SignupDate", "date"),
        ("SignupDateKey", "int"),
    ],
    "DimAccount": [
        ("AccountKey", "int"),
        ("AccountID", "varchar(20)"),
        ("CustomerKey", "int"),
        ("Product", "varchar(40)"),
        ("Tier", "varchar(20)"),
        ("Status", "varchar(20)"),
        ("OpenDateTime", "datetime2"),
        ("OpenDate", "date"),
        ("OpenDateKey", "int"),
        ("RaastIDLinked", "char(1)"),
    ],
    "DimChannel": [
        ("ChannelKey", "int"),
        ("ChannelName", "varchar(40)"),
        ("ChannelGroup", "varchar(20)"),
    ],
    "DimOnboardingStep": [
        ("StepKey", "int"),
        ("StepName", "varchar(80)"),
        ("StepOrder", "int"),
        ("FunnelStage", "varchar(20)"),
    ],
    "DimFailureReason": [
        ("FailureReasonKey", "int"),
        ("Reason", "varchar(80)"),
        ("Category", "varchar(30)"),
        ("IsRetryable", "bit"),
        ("AppliesTo", "varchar(20)"),
    ],
    "DimBank": [
        ("BankKey", "int"),
        ("BankName", "varchar(40)"),
        ("BankType", "varchar(20)"),
    ],
    "DimDate": [
        ("DateKey", "int"),
        ("FullDate", "date"),
        ("CalendarYear", "int"),
        ("Quarter", "int"),
        ("MonthNumber", "int"),
        ("MonthName", "varchar(10)"),
        ("YearMonth", "int"),
        ("DayOfMonth", "int"),
        ("DayOfWeek", "int"),
        ("DayName", "varchar(10)"),
        ("IsWeekend", "bit"),
        ("IsSalaryWeek", "bit"),
        ("IsRamadan", "bit"),
        ("IsEid", "bit"),
        ("EidName", "varchar(20)"),
        ("IsMonthEnd", "bit"),
    ],
    "DimTime": [
        ("TimeKey", "int"),
        ("HourOfDay", "int"),
        ("HourLabel", "char(5)"),
        ("TimeBand", "varchar(20)"),
        ("IsPeakHour", "bit"),
    ],
    "FactOnboardingEvents": [
        ("EventKey", "bigint"),
        ("CustomerKey", "int"),
        ("StepKey", "int"),
        ("EventDateTime", "datetime2"),
        ("DateKey", "int"),
        ("TimeKey", "int"),
        ("Outcome", "varchar(10)"),
        ("FailureReasonKey", "int"),
        ("RetryNumber", "int"),
        ("ReferralSource", "varchar(30)"),
    ],
    "FactApplication": [
        ("ApplicationKey", "int"),
        ("CustomerKey", "int"),
        ("AccountKey", "int"),
        ("StartDateTime", "datetime2"),
        ("StartDateKey", "int"),
        ("StartTimeKey", "int"),
        ("EndDateTime", "datetime2"),
        ("EndDateKey", "int"),
        ("EndTimeKey", "int"),
        ("FinalStatus", "varchar(20)"),
        ("MinutesToOpen", "int"),
        ("TotalRetries", "int"),
        ("FailedStepKey", "int"),
        ("ActivationDateKey", "int"),
        ("FirstPaymentDateKey", "int"),
        ("FirstPaymentStatus", "varchar(20)"),
        ("ReferralSource", "varchar(30)"),
    ],
    "FactPayments": [
        ("PaymentKey", "bigint"),
        ("PaymentID", "varchar(20)"),
        ("AccountKey", "int"),
        ("ChannelKey", "int"),
        ("BankKey", "int"),
        ("PaymentDateTime", "datetime2"),
        ("DateKey", "int"),
        ("TimeKey", "int"),
        ("AmountPKR", "decimal(18,2)"),
        ("Status", "varchar(10)"),
        ("FailureReasonKey", "int"),
        ("LatencyMs", "int"),
        ("IsRetry", "bit"),
        ("OriginalPaymentKey", "bigint"),
    ],
}

# Nullable columns. Everything else is required.
NULLABLE = {
    "FactOnboardingEvents": {"FailureReasonKey"},
    "FactApplication": {
        "AccountKey",
        "MinutesToOpen",
        "FailedStepKey",
        "ActivationDateKey",
        "FirstPaymentDateKey",
    },
    "FactPayments": {"FailureReasonKey", "OriginalPaymentKey"},
    "DimDate": {"EidName"},
}


def headers(table: str) -> list[str]:
    return [name for name, _ in TABLES[table]]


def datediff_minutes(start: datetime, end: datetime) -> int:
    """Match SQL Server DATEDIFF(MINUTE): minute boundaries crossed, seconds ignored."""
    start = start.replace(second=0, microsecond=0)
    end = end.replace(second=0, microsecond=0)
    return int((end - start).total_seconds() // 60)


def date_key(value: date) -> int:
    return value.year * 10000 + value.month * 100 + value.day


def in_range(value: date, bounds: tuple[date, date]) -> bool:
    return bounds[0] <= value <= bounds[1]
