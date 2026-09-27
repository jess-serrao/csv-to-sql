CREATE OR ALTER PROCEDURE core.ProcessImportBatch
    @BatchId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DELETE FROM core.ImportIssue
    WHERE BatchId = @BatchId;

    INSERT INTO core.ImportIssue (BatchId, RowId, IssueReason)
    SELECT
        @BatchId,
        RowId,
        CASE
            WHEN NULLIF(LTRIM(RTRIM(RecordIdText)), '') IS NULL THEN 'RecordId is required.'
            WHEN TRY_CONVERT(datetime2, RecordTimestampText) IS NULL THEN 'RecordTimestamp is invalid or missing.'
            WHEN NULLIF(LTRIM(RTRIM(CategoryText)), '') IS NULL THEN 'Category is required.'
        END
    FROM landing.RawRecord
    WHERE BatchId = @BatchId
      AND (
          NULLIF(LTRIM(RTRIM(RecordIdText)), '') IS NULL
          OR TRY_CONVERT(datetime2, RecordTimestampText) IS NULL
          OR NULLIF(LTRIM(RTRIM(CategoryText)), '') IS NULL
      );

    MERGE core.Record AS target
    USING (
        SELECT
            LTRIM(RTRIM(raw.RecordIdText)) AS RecordId,
            TRY_CONVERT(datetime2, raw.RecordTimestampText) AS RecordTimestamp,
            LTRIM(RTRIM(raw.CategoryText)) AS Category,
            TRY_CONVERT(decimal(18,4), NULLIF(LTRIM(RTRIM(raw.NumericValueText)), '')) AS NumericValue
        FROM landing.RawRecord AS raw
        WHERE raw.BatchId = @BatchId
          AND NOT EXISTS (
              SELECT 1
              FROM core.ImportIssue AS issue
              WHERE issue.BatchId = raw.BatchId
                AND issue.RowId = raw.RowId
          )
    ) AS source
    ON target.RecordId = source.RecordId
    WHEN MATCHED THEN
        UPDATE SET
            RecordTimestamp = source.RecordTimestamp,
            Category = source.Category,
            NumericValue = source.NumericValue,
            LastBatchId = @BatchId,
            UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (RecordId, RecordTimestamp, Category, NumericValue, LastBatchId)
        VALUES (source.RecordId, source.RecordTimestamp, source.Category, source.NumericValue, @BatchId);

    UPDATE core.ImportBatch
    SET
        CompletedAt = SYSUTCDATETIME(),
        LoadedRows = (SELECT COUNT(*) FROM landing.RawRecord WHERE BatchId = @BatchId),
        AcceptedRows = (SELECT COUNT(*) FROM landing.RawRecord AS raw WHERE raw.BatchId = @BatchId AND NOT EXISTS (SELECT 1 FROM core.ImportIssue AS issue WHERE issue.BatchId = raw.BatchId AND issue.RowId = raw.RowId)),
        RejectedRows = (SELECT COUNT(*) FROM core.ImportIssue WHERE BatchId = @BatchId)
    WHERE BatchId = @BatchId;

    COMMIT TRANSACTION;
END;
GO
