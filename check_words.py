import json
import re

def check_words():
    try:
        with open('assets/words.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
    except UnicodeDecodeError:
        print("File is not UTF-8 encoded. Trying GBK...")
        with open('assets/words.json', 'r', encoding='gbk') as f:
            data = json.load(f)
    
    issues = []
    for sub in data:
        for w in sub['words']:
            # 查找包含两个或以上连续问号，或者拼写音标中有问号的
            if '?' in w.get('phonetic', '') or '?' in w.get('chinese', ''):
                 issues.append({
                     'id': w['id'],
                     'english': w['english'],
                     'phonetic': w['phonetic'],
                     'chinese': w['chinese']
                 })
    
    print(json.dumps(issues, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    check_words()
