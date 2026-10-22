-- Creates the lab database used by the rest of the scripts.
-- SQL Server 2017 or newer. Safe to run more than once.

IF DB_ID(N'DigitalBankDW') IS NULL
    CREATE DATABASE DigitalBankDW;
GO
