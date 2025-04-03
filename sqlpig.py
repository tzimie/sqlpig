"""
select ObjectName+'.sql:'+convert(varchar,LineNumber)+':'+
  convert(varchar,cnt)+':'+
  convert(varchar,CPU)+':'+
  convert(varchar,Duration)+':'+
  convert(varchar,Reads)+':'+
  convert(varchar,Writes)+':'+
  convert(varchar,isnull(RowCounts,0))
from (
  select ObjectName,LineNumber, count(*) as cnt, sum(CPU) as CPU,sum(Duration) as Duration,
    sum(Reads) as Reads, sum(Writes) as Writes, sum(RowCounts) as RowCounts
  from {MyTrace} where EventClass=45 and ObjectName is not null
  group by ObjectName,LineNumber) Q 
"""

import subprocess
import sys

def pct(val, base): # format as 99.99% (6 chars always), but 100% is formatted as 100.0% (again 6 chars, not 7)
  if base == 0:
    return '  n/a '
  res = '%5.2f' % (val * 100.0 / base)
  if res == '100.00': 
    res = '100.0'
  return res + '%'

metrics = "xcd"
legend = "x-eXecutions, c-CPU, d-Duration, r-Reads, w-Writes, n-RowCounts"
if len(sys.argv) < 2:
  print("Usage: python sqlpig.py procname [metrics [altdatafile]]")
  print(f"Metrics: {legend}")
  print(f"Default metrics: {metrics}")
  print('by default data file = procedure name with .log')
  exit(0)
if len(sys.argv) > 2:
  metrics = sys.argv[2]
storedproc = sys.argv[1]
datafile = storedproc
if len(sys.argv) > 3:
  datafile = sys.argv[3]
print(f"Data file used: {datafile}.log")

shift = 1 # edit this value to readjust position if needed

output = subprocess.check_output(f'pygmentize -f html -O "full,style=monokai,linenos=1" -l tsql -o tmp.html {storedproc}.sql', shell=True)
if len(output)>0: 
  print(output)
  exit(0)

xruns = {}
xcpu = {}
xduration = {}
xreads = {}
xwrites = {}
xrows = {}
maxruns = maxcpu = maxduration = maxreads = maxwrites = maxrows = 0
sumruns = sumcpu = sumduration = sumreads = sumwrites = sumrows = 0
lineruns = linecpu = lineduration = linereads = linewrites = linerows = 0
with open(datafile+".log") as f:
  for line in f:
    file, line_no, runs, cpu, duration, reads, writes, rows = line.strip().split(":")
    xruns[int(line_no)] = int(runs)
    xcpu[int(line_no)] = int(cpu)
    xduration[int(line_no)] = int(duration)
    xreads[int(line_no)] = int(reads)
    xwrites[int(line_no)] = int(writes)
    xrows[int(line_no)] = int(rows)
    if maxruns < int(runs):
      maxruns = int(runs)
      lineruns = int(line_no)
    if maxcpu < int(cpu):
      maxcpu = int(cpu)
      linecpu = int(line_no)
    if maxduration < int(duration):
      maxduration = int(duration)
      lineduration = int(line_no)
    if maxreads < int(reads):
      maxreads = int(reads)
      linereads = int(line_no)
    if maxwrites < int(writes):
      maxwrites = int(writes)
      linewrites = int(line_no)
    if maxrows < int(rows):
      maxrows = int(rows)
      linerows = int(line_no)
    sumruns += int(runs)
    sumcpu += int(cpu)
    sumduration += int(duration)
    sumreads += int(reads)
    sumwrites += int(writes)
    sumrows += int(rows)
print(f'Reminder: legend: {legend}')
print('Upper case XCDRWN are used to show relative percentage to total sum of particular metric')
print('Max values: ')
print(f'  {maxruns}x in line {lineruns}')
print(f'  {maxcpu}c in line {linecpu}')
print(f'  {maxduration}d in line {lineduration}')
print(f'  {maxreads}r in line {linereads}')
print(f'  {maxwrites}w in line {linewrites}')
print(f'  {maxrows}n in line {linerows}')
print(f'Totals: {sumruns}x, {sumcpu}c, {sumduration}d, {sumreads}r, {sumwrites}w, {sumrows}n')
width = 0
if 'x' in metrics: width += len(str(maxruns)) + 2
if 'c' in metrics: width += len(str(maxcpu)) + 2
if 'd' in metrics: width += len(str(maxduration)) + 2
if 'r' in metrics: width += len(str(maxreads)) + 2
if 'w' in metrics: width += len(str(maxwrites)) + 2
if 'n' in metrics: width += len(str(maxrows)) + 2
if 'X' in metrics: width += 8 # 8 is length of 99.99%X<space>
if 'C' in metrics: width += 8
if 'D' in metrics: width += 8
if 'R' in metrics: width += 8
if 'W' in metrics: width += 8
if 'N' in metrics: width += 8
print('Metrics: ', metrics)
print('Extra data width:', width)

with open("tmp.html",'r') as file:
  i = -1
  data = file.readlines()
  for ln in data:
    i += 1
    line = ln.strip()
    if line.startswith('<span class="normal">') and line.endswith('</span>'):
      rem = line.split('<span class="normal">')[1]
      rest = rem.split('</span>')
      if rest[1] == '':
        padlen = len(rest[0])
        lnumber = int(rest[0]) 
        try:
          runs = xruns[lnumber+shift]
          cpu = xcpu[lnumber+shift]
          duration = xduration[lnumber+shift]
          reads = xreads[lnumber+shift]
          writes = xwrites[lnumber+shift]
          rows = xrows[lnumber+shift]
          adder = rest[0]
          if 'x' in metrics: adder += ' ' + str(runs).rjust(len(str(maxruns))) + 'x'
          if 'c' in metrics: adder += ' ' + str(cpu).rjust(len(str(maxcpu))) + 'c'
          if 'd' in metrics: adder += ' ' + str(duration).rjust(len(str(maxduration))) + 'd'
          if 'r' in metrics: adder += ' ' + str(reads).rjust(len(str(maxreads))) + 'r'
          if 'w' in metrics: adder += ' ' + str(writes).rjust(len(str(maxwrites))) + 'w'
          if 'n' in metrics: adder += ' ' + str(rows).rjust(len(str(maxrows))) + 'n'
          if 'X' in metrics: adder += ' ' + pct(runs,maxruns) + 'X'
          if 'C' in metrics: adder += ' ' + pct(cpu,sumcpu) + 'C'
          if 'D' in metrics: adder += ' ' + pct(duration,sumduration) + 'D'
          if 'R' in metrics: adder += ' ' + pct(reads,sumreads) + 'R'
          if 'W' in metrics: adder += ' ' + pct(writes,sumwrites) + 'W'
          if 'N' in metrics: adder += ' ' + pct(rows,sumrows) + 'N'
          data[i] = '<span class="normal">' + adder + '</span>' + '\n'
        except:
          pass

print('Writing file '+datafile+".html")
out = open(datafile+".html", "w")
out.write('<meta http-equiv="Content-Type" content="text/html; charset=cp1251">')
out.writelines(data)
out.close()  