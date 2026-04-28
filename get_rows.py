import json
import zipfile
import xml.etree.ElementTree as ET

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def scan_cells(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        current_sublist = None
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text).strip()
                if 'Sublist' in text and 'of the Academic Word List' in text:
                    current_sublist = text
            if current_sublist and elem.tag.endswith('tbl'):
                # Read all rows into a 2D grid
                grid = []
                for row in elem.findall('.//w:tr', namespaces):
                    row_data = []
                    for cell in row.findall('.//w:tc', namespaces):
                        # Some cells are merged horizontally or vertically, but let's just get the text
                        cell_text = ' '.join(
                            ''.join(t.text for t in p.findall('.//w:t', namespaces) if t.text).strip()
                            for p in cell.findall('.//w:p', namespaces)
                        )
                        row_data.append(cell_text.strip())
                    grid.append(row_data)
                
                # Check for empty cells or structure indicating headwords
                print(current_sublist, 'Top 5 rows:')
                for r in grid[:5]:
                    print(r)
                current_sublist = None
        
scan_cells('Academic Word List.docx')
