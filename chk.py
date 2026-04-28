import json
import zipfile
import xml.etree.ElementTree as ET

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def check_format(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        current_sublist = None
        count = 0
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text)
                if 'Sublist 1' in text and 'of the Academic Word List' in text:
                    current_sublist = 1
            if current_sublist == 1 and elem.tag.endswith('tbl'):
                # iterate over rows and cells to see what makes a headword stand out
                for r_idx, row in enumerate(elem.findall('.//w:tr', namespaces)):
                    for c_idx, cell in enumerate(row.findall('.//w:tc', namespaces)):
                        # Look at the first paragraph of each cell. Usually the first word in a cell is the headword, 
                        # and the subsequent ones in the same cell are family members separated by line breaks or new paragraphs.
                        for p_idx, p in enumerate(cell.findall('.//w:p', namespaces)):
                            text = ''.join(t.text for t in p.findall('.//w:t', namespaces) if t.text)
                            if text.strip():
                                print(f"Cell ({r_idx}, {c_idx}) P{p_idx}: {text.strip()}")
                                count += 1
                                if count > 20: return
check_format('Academic Word List.docx')
