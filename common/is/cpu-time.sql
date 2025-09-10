SELECT Txt.query_sql_text, Qry.avg_optimize_cpu_time
FROM sys.query_store_plan AS Pl
INNER JOIN sys.query_store_query AS Qry
    ON Pl.query_id = Qry.query_id
INNER JOIN sys.query_store_query_text AS Txt
    ON Qry.query_text_id = Txt.query_text_id
    WHERE Pl.last_execution_time > DATEADD(minute, -15, GETUTCDATE())
ORDER BY Qry.avg_optimize_cpu_time DESC;
