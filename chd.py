import json
import zipfile
import xml.etree.ElementTree as ET

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def extract_headwords(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text).strip()
                if 'Sublist 10' in text:
                    print(text)
            if elem.tag.endswith('tbl'):
                # print all words in the table for Sublist 10 to see what the 30 words are
                pass
