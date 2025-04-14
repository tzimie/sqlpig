import plotly.express as px
import numpy as np
import pandas as pd
# also requires kaleido
import math
import sys

if len(sys.argv) != 3:
  print("Usage: python heatmap.py file(.csv assumed) seeks|scans|updates")
  exit(0)

filename = sys.argv[1]
metric = sys.argv[2]

data = []
with open(f"{filename}.csv") as f:
  for line in f:
    db, schema, table, index, size, rows, seeks, scans, updates = line.strip().split(",")
    data.append( [db, schema, table, index, int(size), f'{int(rows):_}', 
      math.log10(int(seeks)+1.0), math.log10(int(scans)+1.0), math.log10(int(updates)+1.0), 
      f'{int(seeks):_}', f'{int(scans):_}', f'{int(updates):_}' ] )

df = pd.DataFrame(np.array(data), columns=['db', 'schema', 'table', 'index', 'sizeMb', 'rows', 
                  'log10_seeks', 'log10_scans', 'log10_updates', 'seeks', 'scans', 'updates'])
df[['log10_seeks']] = df[['log10_seeks']].apply(pd.to_numeric)
df[['log10_scans']] = df[['log10_scans']].apply(pd.to_numeric)
df[['log10_updates']] = df[['log10_updates']].apply(pd.to_numeric)
fig = px.treemap(df, path=[px.Constant('server'), 'db', 'schema', 'table', 'index' ], 
                     values='sizeMb', 
                     hover_data=['db','schema','table','index','sizeMb','rows','seeks','scans','updates'],
                     color='log10_'+metric,
                     color_continuous_scale='thermal')
fig.update_layout(margin = dict(t=50, l=25, r=25, b=25))
fig.data[0].hovertemplate = '%{customdata[0]}.%{customdata[1]}.%{customdata[2]}<br>index %{customdata[3]}<br>size=%{customdata[4]}Mb rows=%{customdata[5]}<br>seeks=%{customdata[6]}<br>scans=%{customdata[7]}<br>updates=%{customdata[8]}<br><extra></extra>'
fig.show()

