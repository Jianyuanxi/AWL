import zipfile
import xml.etree.ElementTree as ET
import json
import re

def extract_text_from_docx(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        
        # Namespaces
        namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        text_nodes = tree.findall('.//w:t', namespaces)
        
        full_text = ''.join([node.text for node in text_nodes if node.text])
        # A safer way to split lines if paragraphs are used
        paragraphs = tree.findall('.//w:p', namespaces)
        lines = []
        for p in paragraphs:
            texts = p.findall('.//w:t', namespaces)
            if texts:
                line_text = ''.join([t.text for t in texts if t.text])
                lines.append(line_text)
        return lines

lines = extract_text_from_docx('Academic Word List.docx')
with open('debug_docx.txt', 'w', encoding='utf-8') as f:
    for line in lines:
        f.write(line + '\n')
print('Extracted', len(lines), 'lines of text.')
