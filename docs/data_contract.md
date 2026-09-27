# Data Contract

## Required columns

| Column | SQL type | Rule |
|---|---|---|
| `RecordId` | `nvarchar(100)` | Required and unique within the curated table. |
| `RecordTimestamp` | `datetime2` | Required and must be a valid timestamp. |
| `Category` | `nvarchar(100)` | Required nonblank label. |
| `NumericValue` | `decimal(18,4)` | Optional numeric measurement. |

## Input format

- CSV format with a single header row.
- UTF-8 encoding is recommended.
- Commas inside text values must be wrapped in double quotes.
- Blank strings are treated as missing values.

## Validation behavior

Rows missing `RecordId`, `RecordTimestamp`, or `Category` are recorded as rejected. Valid rows are inserted or updated in the curated table using `RecordId` as the business key.
