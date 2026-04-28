import zipfile
import xml.etree.ElementTree as ET
import json

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def extract_headwords(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        results = []
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text)
                if text.strip() and 'Sublist' in text:
                    results.append({'type': 'sublist', 'title': text.strip()})
            elif elem.tag.endswith('tbl'):
                words = []
                for row in elem.findall('.//w:tr', namespaces):
                    for cell in row.findall('.//w:tc', namespaces):
                        for p in cell.findall('.//w:p', namespaces):
                            p_text = ''
                            is_headword = False
                            # We can also check if the whole paragraph is styled differently, or just look at runs
                            for r in p.findall('.//w:r', namespaces):
                                t = r.find('w:t', namespaces)
                                if t is not None and t.text:
                                    p_text += t.text
                                # sometimes headwords are italic. The instructions said: "其中斜体字，analysis，在学术英语中最常见" but wait, that might mean just the headword is italic? Or just that 'analysis' is the headword and italic?
                                # Let's see if italics is the distinguishing factor for headwords
                                rPr = r.find('w:rPr', namespaces)
                                if rPr is not None:
                                    # in Word, an empty <w:i/> means italic is true
                                    if rPr.find('w:i', namespaces) is not None:
                                        is_headword = True
                            if p_text.strip():
                                words.append({'text': p_text.strip(), 'italic': is_headword})
                if words:
                    results.append({'type': 'table', 'words': words})
        return results

data = extract_headwords('Academic Word List.docx')
with open('debug_styles.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('Done!')
