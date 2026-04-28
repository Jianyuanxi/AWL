import zipfile
import xml.etree.ElementTree as ET
import json

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def extract_tables(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        
        body = tree.find('.//w:body', namespaces)
        
        results = []
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text)
                if text.strip():
                    results.append({'type': 'p', 'text': text})
            elif elem.tag.endswith('tbl'):
                table_data = []
                for row in elem.findall('.//w:tr', namespaces):
                    row_data = []
                    for cell in row.findall('.//w:tc', namespaces):
                        cell_text = []
                        for p in cell.findall('.//w:p', namespaces):
                            p_text = ''.join(t.text for t in p.findall('.//w:t', namespaces) if t.text)
                            if p_text.strip():
                                cell_text.append(p_text.strip())
                        if cell_text:
                            row_data.append(cell_text)
                    if row_data:
                        table_data.append(row_data)
                if table_data:
                    results.append({'type': 'table', 'data': table_data})
        return results

data = extract_tables('Academic Word List.docx')
with open('debug_tables.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('Saved structured data to debug_tables.json')
