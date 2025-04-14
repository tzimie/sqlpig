SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[HeatMap]
  @dbscope varchar(128)=NULL
as
create table #tr (db_id int, dbname sysname, schemaname sysname, tablename sysname, indexname sysname, 
  rowcnt bigint, table_id int, index_id int, totalspacemb int)
declare @db nvarchar(256), @sql varchar(8000)
set @db=db_name()
set @sql='use [?];
insert into #tr 
select DB_ID() as db_id, DB_NAME() as DbName, 
  SchemaName, TableName, IndexName, 
  sum(rows) as rows, object_id, index_id, sum(a.total_pages / 128)  AS TotalSpaceMB
  from (
    SELECT t.object_id, i.index_id,
    s.Name AS SchemaName,
    t.NAME AS TableName,
	isnull(i.name,''Heap'') AS IndexName,
	rows,
	p.partition_number, p.partition_id
  FROM sys.tables t
  INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
  INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
  LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
  WHERE t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 and db_id()>4
  ) Q
  INNER JOIN sys.allocation_units a ON Q.partition_id = a.container_id
  GROUP BY SchemaName, TableName, IndexName, object_id, index_id'
if @dbscope is NULL
  EXECUTE master.sys.sp_MSforeachdb @sql
else  
  begin
  set @sql=replace(@sql, '[?]', '['+@dbscope+']')
  exec(@sql)
  end
select dbname,schemaname,tablename,indexname,totalspacemb,rowcnt
    ,isnull(user_seeks+user_lookups,0) as seeks, isnull(user_scans,0) as scans, isnull(user_updates,0) as updates
  from #tr T
  left outer join sys.dm_db_index_usage_stats ST on ST.database_id=T.db_id and ST.object_id=T.table_id and ST.index_id=T.index_id
  where totalspacemb>0
GO
