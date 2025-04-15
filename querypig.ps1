param(
    [Parameter(Mandatory=$true)]
    [string]$Server,
    
    [Parameter(Mandatory=$true)]
    [string]$Database,
    
    [Parameter(Mandatory=$true)]
    [string]$ProcedureName,

    [Parameter(Mandatory=$false)]
    [string]$Flags
)

function MSSQLquery([string] $connstr, [string]$sql)
  {
  $sqlConn = New-Object System.Data.SqlClient.SqlConnection
  $sqlConn.ConnectionString = $connstr
  $sqlConn.Open()
  $sqlcmd = New-Object System.Data.SqlClient.SqlCommand
  $sqlcmd.Connection = $sqlConn
  $query = $sql
  $sqlcmd.CommandText = $query
  $adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
  $data = New-Object System.Data.DataSet
  $adp.Fill($data) | Out-Null
  return $data.Tables[0]
}

function MSSQLscalar([string] $connstr, [string]$sql)
  {
  $sqlConn = New-Object System.Data.SqlClient.SqlConnection
  $sqlConn.ConnectionString = $connstr
  $sqlConn.Open()
  $sqlcmd = New-Object System.Data.SqlClient.SqlCommand
  $sqlcmd.Connection = $sqlConn
  $query = $sql
  $sqlcmd.CommandText = $query
  $adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
  $data = New-Object System.Data.DataSet
  $adp.Fill($data) | Out-Null
  $firstrow = $data.Tables[0][0]
  return $firstrow.res
}

$keywords = @('PROCEDURE', 'ALL', 'FETCH', 'PUBLIC', 'ALTER', 'FILE', 'RAISERROR', 'AND', 'FILLFACTOR', 'READ', 'ANY', 'FOR', 'READTEXT', `
  'AS', 'FOREIGN', 'RECONFIGURE', 'ASC', 'FREETEXT', 'REFERENCES', 'AUTHORIZATION', 'FREETEXTTABLE', 'REPLICATION', 'BACKUP', 'FROM', `
  'RESTORE', 'BEGIN', 'FULL', 'RESTRICT', 'BETWEEN', 'FUNCTION', 'RETURN', 'BREAK', 'GOTO', 'REVERT', 'BROWSE', 'GRANT', 'REVOKE', 'BULK', `
  'GROUP', 'RIGHT', 'BY', 'HAVING', 'ROLLBACK', 'CASCADE', 'HOLDLOCK', 'ROWCOUNT', 'CASE', 'IDENTITY', 'ROWGUIDCOL', 'CHECK', 'IDENTITY_INSERT', `
  'RULE', 'CHECKPOINT', 'IDENTITYCOL', 'SAVE', 'CLOSE', 'IF', 'SCHEMA', 'CLUSTERED', 'IN', 'SECURITYAUDIT', 'COALESCE', 'INDEX', 'SELECT', `
  'COLLATE', 'INNER', 'COLUMN', 'INSERT', 'COMMIT', 'INTERSECT', 'COMPUTE', 'INTO', 'SESSION_USER', 'CONSTRAINT', 'IS', 'SET', 'CONTAINS', `
  'JOIN', 'SETUSER', 'CONTAINSTABLE', 'KEY', 'SHUTDOWN', 'CONTINUE', 'KILL', 'SOME', 'CONVERT', 'LEFT', 'STATISTICS', 'CREATE', 'LIKE', 'SYSTEM_USER', `
  'CROSS', 'TABLE', 'CURRENT', 'LOAD', 'CURRENT_DATE', 'MERGE', 'TEXTSIZE', 'CURRENT_TIME', 'NATIONAL', 'THEN', 'CURRENT_TIMESTAMP', 'NOCHECK', `
  'TO', 'CURRENT_USER', 'NONCLUSTERED', 'TOP', 'CURSOR', 'NOT', 'TRAN', 'DATABASE', 'NULL', 'TRANSACTION', 'DBCC', 'NULLIF', 'TRIGGER', 'DEALLOCATE', `
  'OF', 'TRUNCATE', 'DECLARE', 'OFF', 'TRY_CONVERT', 'DEFAULT', 'OFFSETS', 'TSEQUAL', 'DELETE', 'ON', 'UNION', 'DENY', 'OPEN', 'UNIQUE', 'DESC', `
  'OPENDATASOURCE', 'UNPIVOT', 'DISK', 'OPENQUERY', 'UPDATE', 'DISTINCT', 'OPENROWSET', 'UPDATETEXT', 'DISTRIBUTED', 'OPENXML', 'USE', 'DOUBLE', `
  'OPTION', 'USER', 'DROP', 'OR', 'VALUES', 'DUMP', 'ORDER', 'VARYING', 'ELSE', 'OUTER', 'VIEW', 'END', 'OVER', 'WAITFOR', 'ERRLVL', 'PERCENT', `
  'WHEN', 'ESCAPE', 'PIVOT', 'WHERE', 'EXCEPT', 'PLAN', 'WHILE', 'EXEC', 'PRECISION', 'WITH', 'EXECUTE', 'PRIMARY', 'WITHIN', 'EXISTS', 'PRINT', `
  'WRITETEXT', 'EXIT', 'PROC', 'NOCOUNT')

$htmlheader = @"
<html><head>
<style>
  body {
    font-family: monospace;
  }

        .tooltip {
            position: relative;
            cursor: pointer;
            background: #fff000;
            border-radius: 4px;
        }
        
        /* Tooltip text - positioned absolutely */
        .tooltip .tooltiptext {
            /* Positioning */
            position: absolute;
            transform: translateX(-50%);
            margin-bottom: 15px;
            
            /* Styling */
            width: auto;
            min-width: 200px;
            max-width: 500px;
            background-color: #333;
            color: #f8f8f8;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            line-height: 1.4;
            white-space: pre;
            text-align: left;
            border-radius: 4px;
            padding: 12px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            
            /* Hidden by default */
            visibility: hidden;
            opacity: 0;
            transition: opacity 0.2s;
            
            /* Ensure tooltip stays on screen */
            max-height: 300px;
            overflow-y: auto;
        }
        
        .tooltip .tooltiptext::after {
            content: "";
            position: absolute;
            top: 100%;
            left: 50%;
            margin-left: -6px;
            border-width: 6px;
            border-style: solid;
            border-color: #333 transparent transparent transparent;
        }
        
        .tooltip:hover .tooltiptext {
            visibility: visible;
            opacity: 1;
        }
        
        .tooltip.right .tooltiptext {
            left: 100%;
            bottom: auto;
            top: 50%;
            transform: translateY(-50%);
            margin-left: 15px;
            margin-bottom: 0;
        }
        
        .tooltip.right .tooltiptext::after {
            top: 50%;
            left: -12px;
            margin-top: -6px;
            border-color: transparent #333 transparent transparent;
        }
        
        .tooltip.left .tooltiptext {
            right: 100%;
            left: auto;
            bottom: auto;
            top: 50%;
            transform: translateY(-50%);
            margin-right: 15px;
            margin-bottom: 0;
        }
        
        .tooltip.left .tooltiptext::after {
            top: 50%;
            right: -12px;
            left: auto;
            margin-top: -6px;
            border-color: transparent transparent transparent #333;
        }

</style>
<body>
"@

$htmltail = @"
</body>
</html>
"@

$querystore = @"
declare @id int
select @id=OBJECT_ID('$ProcedureName')
declare @sql nvarchar(max)

select * into #p1 from (
  SELECT P.plan_id,P.query_id,Qry.query_text_id,query_plan,s.last_execution_time
   ,last_compile_batch_offset_start,last_compile_batch_offset_end
   ,row_number() over (partition by P.query_id order by s.last_execution_time desc) as rnk
     ,count_executions,avg_duration,last_duration,min_duration,max_duration,stdev_duration
     ,avg_cpu_time,last_cpu_time,min_cpu_time,max_cpu_time,stdev_cpu_time
     ,avg_logical_io_reads,last_logical_io_reads,min_logical_io_reads,max_logical_io_reads,stdev_logical_io_reads
     ,avg_logical_io_writes,last_logical_io_writes,min_logical_io_writes,max_logical_io_writes,stdev_logical_io_writes
     ,avg_physical_io_reads,last_physical_io_reads,min_physical_io_reads,max_physical_io_reads,stdev_physical_io_reads
	 ,avg_query_max_used_memory,last_query_max_used_memory,min_query_max_used_memory,max_query_max_used_memory,stdev_query_max_used_memory
     ,avg_rowcount,last_rowcount,min_rowcount,max_rowcount,stdev_rowcount
     ,avg_num_physical_io_reads,last_num_physical_io_reads,min_num_physical_io_reads,max_num_physical_io_reads,stdev_num_physical_io_reads
     ,avg_tempdb_space_used,last_tempdb_space_used,min_tempdb_space_used,max_tempdb_space_used,stdev_tempdb_space_used
 FROM sys.query_store_plan p 
 INNER JOIN sys.query_store_runtime_stats s ON p.plan_id = s.plan_id
 INNER JOIN sys.query_store_query AS Qry  ON p.query_id = Qry.query_id
WHERE s.count_executions > 1 -- used to make the query faster
   and s.last_execution_time>dateadd(hh,-12,getdate())
   and Qry.object_id=@id) Q where rnk=1 -- last

--select query_sql_text,#p1.* into #p2 from #p1
--  INNER JOIN sys.query_store_query_text AS Txt ON #p1.query_text_id = Txt.query_text_id

select @sql=[definition] from sys.sql_modules where object_id=@id
declare @ln varchar(10)='
'
select (len(beg)-len(replace(beg,@ln,'')))/2 as line,
  query_plan,last_execution_time
     ,count_executions,avg_duration,last_duration,min_duration,max_duration,stdev_duration
     ,avg_cpu_time,last_cpu_time,min_cpu_time,max_cpu_time,stdev_cpu_time
     ,avg_logical_io_reads,last_logical_io_reads,min_logical_io_reads,max_logical_io_reads,stdev_logical_io_reads
     ,avg_logical_io_writes,last_logical_io_writes,min_logical_io_writes,max_logical_io_writes,stdev_logical_io_writes
     ,avg_physical_io_reads,last_physical_io_reads,min_physical_io_reads,max_physical_io_reads,stdev_physical_io_reads
	 ,avg_query_max_used_memory,last_query_max_used_memory,min_query_max_used_memory,max_query_max_used_memory,stdev_query_max_used_memory
     ,avg_rowcount,last_rowcount,min_rowcount,max_rowcount,stdev_rowcount
     ,avg_num_physical_io_reads,last_num_physical_io_reads,min_num_physical_io_reads,max_num_physical_io_reads,stdev_num_physical_io_reads
     ,avg_tempdb_space_used,last_tempdb_space_used,min_tempdb_space_used,max_tempdb_space_used,stdev_tempdb_space_used
  from (
  select 
    --substring(@sql,last_compile_batch_offset_start/2,(last_compile_batch_offset_end-last_compile_batch_offset_start)/2) as txt,
    substring(@sql,1,last_compile_batch_offset_start/2) as beg,
    * from #p1) Q
	order by last_compile_batch_offset_start
"@

$tabs = "    " # default, tab = 4 spaces
if ($Flags.Contains('1')) { $tabs = ' ' }
if ($Flags.Contains('2')) { $tabs = '  ' }
if ($Flags.Contains('3')) { $tabs = '   ' }


#try {
    $query =  "SELECT definition as res FROM sys.sql_modules WHERE object_id = OBJECT_ID('$ProcedureName')"
    $conn =   "Server=$Server;Database=$Database;Integrated Security=True"
    $result = MSSQLscalar $conn $query
    if ($result -eq $null) {
        Write-Error "Stored procedure '$ProcedureName' not found in database '$Database'"
        exit 1
    }
    
    $qsdata = MSSQLquery $conn $querystore
    if ($qsdata.length -eq 0) { 
        Write-Error "No data for stored procedure '$ProcedureName' is query store of database '$Database' or query store is off"
        exit 1
    }
    $point = 0

    if ($Flags.contains('P')) {
      New-Item -ItemType Directory -Path $ProcedureName -Force
      Remove-Item -Path "$ProcedureName\*.sqlplan" -Force
      }

    $alllines = $result -split "\r\n"
    $code = ''
    [System.Collections.ArrayList] $ecomment = @()
    [System.Collections.ArrayList] $mcomment = @()
    [System.Collections.ArrayList] $textlines = @()
    $multiline = 0 # flag that we eat multiline comment
    foreach ($ln in $alllines) {
      $ln = $ln.replace("`n","").replace("`r","").replace("`t",$tabs)
      if (($multiline -gt 0) -and $ln.Contains("*/")) { # end multiline comment */
        $ln = "{xleft}" + $ln.replace("/*", "{cright}")
        $multiline = 0
        }
      elseif ($multiline -gt 0)
        {
        $ln = '#' + $ln # first char indicates comment, yes, that is ugly
        }
      elseif ($ln.Contains('--'))
        {
        $arr = $ln -split '--'
        $ln = $arr[0] + "{cfin}" + $arr[1]
        }
      elseif ($ln.Contains("/*") -and $ln.Contains("*/")) { # /* same line */
        $ln = $ln.replace("/*", "{cleft}").replace("*/","{cright}")
        }
      elseif ($ln.Contains("/*") -and -not $ln.Contains("*/")) { # /* start multiline comment
        $ln = $ln.replace("/*", "{cleft}")
        $multiline++
        }
      $textlines += $ln
      }

    $lineNumber = 1
    $out = @($htmlheader)
    foreach ($ln in $textlines) {
      $strlinenumber = '</font><font color="black">' + ("{0,4}: " -f $lineNumber)
      $strtooltip = $strlinenumber
      $planstr = ''
      if ($ln[0] -eq '#') { # multiline comment line 
        $ln = $ln.replace(" ","&nbsp;").replace(">", "&gt;").replace("<","&lt;")
        $ln = '</font><font color="gray">' + $ln.substring(1)
        }
      else
        {
        foreach ($k in $keywords) {
          $ln = $ln -iReplace "(\W)($k)(\W)", '$1{blue}$2{black}$3'
          $ln = $ln -iReplace "^($k)(\W)", '{blue}$1{black}$2'
          $ln = $ln -iReplace "(\W)($k)$", '$1{blue}$2{black}'
          $ln = $ln -iReplace "^($k)$", '{blue}$1{black}'
          }
        $ln = $ln -Replace "'(.*?)'", "{green}$&{black}"
        $ln = $ln.replace(" ","&nbsp;").replace(">", "&gt;").replace("<","&lt;")
        $ln = $ln.replace("{blue}", '</font><font color="blue">')
        $ln = $ln.replace("{black}", '</font><font color="black">')
        $ln = $ln.replace("{green}", '</font><font color="green">')
        $ln = $ln.replace("{cfin}", '</font><font color="gray">--')
        $ln = $ln.replace("{cleft}", '</font><font color="gray">/*')
        $ln = $ln.replace("{xleft}", '</font><font color="gray">')
        $ln = $ln.replace("{cright}", '*/</font><font color="black">')
        if ($point -lt $qsdata.length) {
          if ($qsdata[$point].line -eq $linenumber) {
            $planstr = $strlinenumber
            if ($Flags.contains('P')) {
              $planfile = $ProcedureName+"\plan" + "$linenumber.sqlplan"
              $qsdata[$point].query_plan | Out-File -FilePath $planfile -Encoding utf8 -force
              #$planstr = '<a href="file:///' + (get-Location) + '/' + $planfile+ '" download>' + $strlinenumber +'</a>'
              }
            $stats = @"
$(($qsdata[$point].last_execution_time).ToString("HH:mm:ss"))
executions: $($qsdata[$point].count_executions)
duration: avg $([int]$qsdata[$point].avg_duration) last $($qsdata[$point].last_duration) min $($qsdata[$point].min_duration) max $($qsdata[$point].max_duration) 
cpu_time: avg $([int]$qsdata[$point].avg_cpu_time) last $($qsdata[$point].last_cpu_time) min $($qsdata[$point].min_cpu_time) max $($qsdata[$point].max_cpu_time) 
log read: avg $([int]$qsdata[$point].avg_logical_io_reads) last $($qsdata[$point].last_logical_io_reads) min $($qsdata[$point].min_logical_io_reads) max $($qsdata[$point].max_logical_io_reads) 
ph reads: avg $([int]$qsdata[$point].avg_physical_io_reads) last $($qsdata[$point].last_physical_io_reads) min $($qsdata[$point].min_physical_io_reads) max $($qsdata[$point].max_physical_io_reads) 
writes  : avg $([int]$qsdata[$point].avg_logical_io_writes) last $($qsdata[$point].last_logical_io_writes) min $($qsdata[$point].min_logical_io_writes) max $($qsdata[$point].max_logical_io_writes) 
rowcount: avg $([int]$qsdata[$point].avg_rowcount) last $($qsdata[$point].last_rowcount) min $($qsdata[$point].min_rowcount) max $($qsdata[$point].max_rowcount) 
used mem: avg $([int]$qsdata[$point].avg_query_max_used_memory) last $($qsdata[$point].last_query_max_used_memory) min $($qsdata[$point].min_query_max_used_memory) max $($qsdata[$point].max_query_max_used_memory) 
tempdb  : avg $([int]$qsdata[$point].avg_tempdb_space_used) last $($qsdata[$point].last_tempdb_space_used) min $($qsdata[$point].min_tempdb_space_used) max $($qsdata[$point].max_tempdb_space_used) 
"@
            $strtooltip = @"
<div class="tooltip right" style="float: left; margin-right: 200px;">$planstr
<span class="tooltiptext">$stats</span></div>
"@
            $point++
          }
        }
      }

      $out += ($strtooltip + $ln + '<br>')
      $lineNumber++
      }
    $out += $htmltail
    $out | Out-File -FilePath ($ProcedureName+".html") -Encoding utf8 -force

#}
#catch {
#    Write-Error "Error retrieving procedure text: $_"
#    exit 1
#}
