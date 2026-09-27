SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'landing')
    EXEC('CREATE SCHEMA landing');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
    EXEC('CREATE SCHEMA core');
GO

CREATE TABLE core.ImportBatch (
    BatchId int IDENTITY(1,1) PRIMARY KEY,
    SourceFile nvarchar(260) NOT NULL,
    StartedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CompletedAt datetime2 NULL,
    LoadedRows int NULL,
    AcceptedRows int NULL,
    RejectedRows int NULL
);
GO

CREATE TABLE landing.RawRecord (
    RowId bigint IDENTITY(1,1) PRIMARY KEY,
    BatchId int NOT NULL DEFAULT 0,
    RecordIdText nvarchar(100) NULL,
    RecordTimestampText nvarchar(100) NULL,
    CategoryText nvarchar(100) NULL,
    NumericValueText nvarchar(100) NULL
);
GO

CREATE TABLE core.Record (
    RecordId nvarchar(100) NOT NULL PRIMARY KEY,
    RecordTimestamp datetime2 NOT NULL,
    Category nvarchar(100) NOT NULL,
    NumericValue decimal(18,4) NULL,
    LastBatchId int NOT NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE core.ImportIssue (
    IssueId bigint IDENTITY(1,1) PRIMARY KEY,
    BatchId int NOT NULL,
    RowId bigint NOT NULL,
    IssueReason nvarchar(500) NOT NULL,
    CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
