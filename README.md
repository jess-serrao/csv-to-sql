# CSV-to-SQL Ingestion Template

A generic SQL Server template for loading a CSV file into a landing table, validating rows, and promoting valid records to a curated table. It contains no source data or organization-specific schema.

## What this template demonstrates

- CSV ingestion with PowerShell and `sqlcmd`
- Separation of landing and curated data layers
- Batch-level audit logging
- Row-level validation and reject tracking
- Post-load data-quality checks

## Repository layout

```text
.
├── docs/
│   └── data_contract.md
├── sql/
│   ├── 01_create_objects.sql
│   ├── 02_process_batch.sql
│   └── 03_quality_checks.sql
├── Import-CsvToSql.ps1
└── README.md
```

## Expected CSV contract

The generic input file must have these columns, in this order:

```text
RecordId,RecordTimestamp,Category,NumericValue
```

See [docs/data_contract.md](docs/data_contract.md) for the rules. No example CSV is included.

## Setup

1. Create an empty SQL Server database.
2. Run `sql/01_create_objects.sql` against that database.
3. Prepare a CSV that follows the data contract.
4. Run the PowerShell loader:

```powershell
.\Import-CsvToSql.ps1 `
  -ServerInstance "localhost\\SQLEXPRESS" `
  -Database "CsvIngestionDemo" `
  -CsvPath "C:\path\to\records.csv"
```

5. Review results with `sql/03_quality_checks.sql`.

## Notes

This is a reusable technical template, not a production deployment. Authentication, data retention, schema governance, error handling, and security requirements should be adapted for the target environment.
