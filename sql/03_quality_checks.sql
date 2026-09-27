-- Batch-level load summary
SELECT
    BatchId,
    SourceFile,
    StartedAt,
    CompletedAt,
    LoadedRows,
    AcceptedRows,
    RejectedRows
FROM core.ImportBatch
ORDER BY BatchId DESC;

-- Reasons for rejected records
SELECT
    IssueReason,
    COUNT(*) AS IssueCount
FROM core.ImportIssue
GROUP BY IssueReason
ORDER BY IssueCount DESC;

-- Curated-table checks
SELECT
    COUNT(*) AS CuratedRecordCount,
    COUNT(DISTINCT RecordId) AS DistinctRecordIdCount,
    SUM(CASE WHEN NumericValue IS NULL THEN 1 ELSE 0 END) AS MissingNumericValueCount
FROM core.Record;
