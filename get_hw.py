import json
import zipfile
import xml.etree.ElementTree as ET

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def extract_headwords(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        all_sublists = []
        current_sublist = None
        current_title = None
        
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text).strip()
                if 'Sublist' in text and 'of the Academic Word List' in text:
                    if current_sublist is not None:
                        all_sublists.append({'title': current_title, 'words': current_sublist})
                    current_title = text.replace(' of the Academic Word List', '')
                    current_sublist = []
            if current_title and elem.tag.endswith('tbl'):
                for paragraph in elem.findall('.//w:p', namespaces):
                    text = ''.join(t.text for t in paragraph.findall('.//w:t', namespaces) if t.text).strip()
                    # How to know if it's a headword? In standard AWL lists from Victoria University,
                    # Headwords are the *first* word in each word family group, and are often formatted with italics, OR
                    # maybe the headwords are just a known list?
                    pass
        
        if current_sublist is not None:
            all_sublists.append({'title': current_title, 'words': current_sublist})
            
        return all_sublists
