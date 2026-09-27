[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ServerInstance,

    [Parameter(Mandatory)]
    [string] $Database,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'

$sqlcmd = Get-Command sqlcmd.exe -ErrorAction SilentlyContinue
if (-not $sqlcmd) {
    throw 'sqlcmd.exe was not found. Install Microsoft Sqlcmd, then run this script again.'
}

$header = Get-Content -LiteralPath $CsvPath -TotalCount 1
$expectedHeader = 'RecordId,RecordTimestamp,Category,NumericValue'
if ($header -ne $expectedHeader) {
    throw "Unexpected CSV header. Expected: $expectedHeader"
}

$escapedPath = $CsvPath.Replace("'", "''")
$escapedName = [System.IO.Path]::GetFileName($CsvPath).Replace("'", "''")

$sql = @"
DECLARE @BatchId int;

INSERT INTO core.ImportBatch (SourceFile)
VALUES (N'$escapedName');

SET @BatchId = SCOPE_IDENTITY();

BULK INSERT landing.RawRecord
FROM '$escapedPath'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

UPDATE landing.RawRecord
SET BatchId = @BatchId
WHERE BatchId = 0;

EXEC core.ProcessImportBatch @BatchId = @BatchId;

SELECT BatchId, LoadedRows, AcceptedRows, RejectedRows
FROM core.ImportBatch
WHERE BatchId = @BatchId;
"@

$temporarySql = Join-Path $env:TEMP "run_csv_import_$([guid]::NewGuid().ToString('N')).sql"
try {
    Set-Content -LiteralPath $temporarySql -Value $sql -Encoding utf8
    & $sqlcmd.Source -S $ServerInstance -d $Database -E -b -i $temporarySql
    if ($LASTEXITCODE -ne 0) {
        throw "SQL import failed with exit code $LASTEXITCODE."
    }
}
finally {
    Remove-Item -LiteralPath $temporarySql -ErrorAction SilentlyContinue
}
