import json
with open('debug_tables.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

for item in d:
    if item['type'] == 'table':
        print('Row 0:', item['data'][0])
        print('Row 1:', item['data'][1])
        print('Row 16:', item['data'][16])
        print('Rows total:', len(item['data']), 'Cols in row 0:', len(item['data'][0]))
        break
