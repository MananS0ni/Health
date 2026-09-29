"""Inventory first-party files; never export secret values or patient databases."""
from pathlib import Path
import ast
import collections
import csv
import hashlib
import json
import os
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audit'
SKIP = {'.git','venv','__pycache__','build','.dart_tool','.gradle','.idea','.pub-cache','ephemeral','audit'}
rows, summaries, errors, excluded = [], [], [], []
text_types = {'.py','.dart','.jsx','.js','.ps1','.md','.txt','.yaml','.yml','.json','.lock','.xml','.plist','.kts','.properties','.html','.cmake','.cc','.cpp','.h','.swift','.xcconfig','.entitlements','.pbxproj','.xcscheme','.xib','.storyboard','.xcsettings','.xcworkspacedata','.iml','.csv','.gitignore','.metadata'}
for base, dirs, files in os.walk(ROOT):
    for d in list(dirs):
        if d in SKIP:
            excluded.append(str((Path(base)/d).relative_to(ROOT)))
            dirs.remove(d)
    for filename in sorted(files):
        path = Path(base)/filename
        rel = path.relative_to(ROOT).as_posix()
        content = path.read_bytes()
        row = {'path':rel,'bytes':len(content),'sha256':hashlib.sha256(content).hexdigest(),'category':'binary asset','lines':'','review':'inventory only'}
        if filename == '.env' or path.suffix in {'.sqlite3','.db','.jks','.keystore'}:
            row['category']='private local data'
            row['review']='not exported; content excluded'
            # Do not put secret content or a guessable secret-file hash in the report.
            row['sha256']='redacted'
        elif rel.startswith('backend/media/'):
            row['category']='local uploaded media'
            row['review']='metadata only; clinical contents not exported'
        elif path.suffix == '.pdf':
            row['category']='PDF documentation'
            try:
                from pypdf import PdfReader
                reader = PdfReader(path)
                pages = [p.extract_text() or '' for p in reader.pages]
                dest = OUT / 'pdf_text' / (rel.replace('/','__')+'.txt')
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text('\n\n'.join(f'PAGE {i+1}\n{p}' for i,p in enumerate(pages)),encoding='utf-8')
                row['review']=f'text extracted: {len(pages)} pages; no visual/layout audit'
                summaries.append({'file':rel,'pages':len(pages),'excerpt':pages[0][:300],'claims':[line for p in pages for line in p.splitlines() if re.search(r'100%|all.*pass|production|secure|zero.*fail|critical|encrypt',line,re.I)][:12]})
            except Exception as e:
                row['review']='extraction failed: '+str(e)
        elif path.suffix.lower() in text_types or filename in {'.gitignore','.metadata','CMakeLists.txt','gradlew','gradlew.bat'}:
            text = content.decode('utf-8',errors='replace')
            row['category']='first-party text / config'
            row['lines']=len(text.splitlines())
            row['review']='automated full-file read; targeted manual review (see report)'
            if path.suffix == '.py':
                try:
                    ast.parse(text.lstrip('\ufeff'),filename=rel)
                except SyntaxError as e:
                    errors.append({'file':rel,'line':e.lineno,'error':e.msg})
        rows.append(row)
with (OUT/'file_inventory.csv').open('w',newline='',encoding='utf-8') as f:
    writer=csv.DictWriter(f,fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(sorted(rows,key=lambda x:x['path']))
summary={'files':len(rows),'categories':dict(collections.Counter(r['category'] for r in rows)), 'text_lines':sum(r['lines'] for r in rows if isinstance(r['lines'],int)), 'excluded_directories':excluded,'python_syntax_errors':errors,'pdf_summaries':summaries}
(OUT/'inventory_summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
