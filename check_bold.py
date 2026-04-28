import json
import zipfile
import xml.etree.ElementTree as ET

namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

def get_headwords(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        current_sublist = None
        sublist_headwords = {}
        
        for elem in body:
            if elem.tag.endswith('p'):
                text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text)
                if 'Sublist' in text and 'of the Academic Word List' in text:
                    current_sublist = text.strip()
                    sublist_headwords[current_sublist] = []
            elif elem.tag.endswith('tbl') and current_sublist is not None:
                # The word list tables are typically 3 columns. 
                # Headwords are the bold/un-indented/first items of each word family block.
                # However, without clear parsing inside the table, a solid approach is to find all paragraphs inside cells.
                # In typical AWL docs, headwords belong to a specific style OR are simply the first word starting a word family.
                # Let's count total words in this table... oh wait, analyzing the table structure: 
                # The document provides word families. "analyse", "economy", "legislate" are definitely headwords. "approach", "disestablish" etc.
                pass
        
        # ACTUALLY, a simpler approach:
        # What if we just rip all headwords by analyzing the original docx text? Wait, in standard AWL docx files (like the one from Victoria Uni), headwords are the base form. 
        # Alternatively, since we can't reliably parse the docx because its exact XML structure of headwords is unclear,
        # what if we just extract EVERY SINGLE "headword" from the docx based on bold text?
        # Let's check if headwords are bold!
        pass

def get_bold_words(docx_path):
    with zipfile.ZipFile(docx_path, 'r') as docx_zip:
        xml_content = docx_zip.read('word/document.xml')
        tree = ET.fromstring(xml_content)
        body = tree.find('.//w:body', namespaces)
        
        current_sublist = None
        sublists = {}
        
        for elem in body.iter():
            if elem.tag.endswith('p'):
                p_text = ''.join(t.text for t in elem.findall('.//w:t', namespaces) if t.text).strip()
                if 'Sublist' in p_text and 'of the Academic Word List' in p_text:
                    current_sublist = p_text
                    sublists[current_sublist] = []
            
            # If it's a run <w:r>
            if elem.tag.endswith('r'):
                # check if bold
                rPr = elem.find('w:rPr', namespaces)
                is_bold = False
                if rPr is not None:
                    # In docx, <w:b/> or <w:b w:val="true"/> or <w:b w:val="1"/> means bold.
                    b = rPr.find('w:b', namespaces)
                    if b is not None:
                        val = b.get('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}val')
                        if val is None or val in ['true', '1', 'on']:
                            is_bold = True
                
                if is_bold and current_sublist is not None:
                    t = elem.find('w:t', namespaces)
                    if t is not None and t.text and t.text.strip().isalpha():
                        # We might get fragments, so we'll need to join them if they are in the same paragraph? 
                        # This is a bit complex. 
                        pass

        return sublists
        
