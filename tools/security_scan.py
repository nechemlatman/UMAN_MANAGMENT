"""Scan tracked current files and all reachable Git blobs; never print matches.

This detects common credential formats, not every possible password. Reports
only object IDs and categories. Review non-pattern secrets manually as well.
"""
import json
import re
import subprocess
from pathlib import Path

PATTERNS = {
    'supabase_secret': rb'sb_secret_[A-Za-z0-9_-]{12,}',
    'supabase_access_token': rb'sbp_[a-fA-F0-9]{30,}',
    'private_key': rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'database_uri_password': rb'postgres(?:ql)?://[^\s:/]+:([^\s@]+)@',
}

def git(*args):
    return subprocess.check_output(['git', *args])

def categories(data):
    found=[]
    for kind, pattern in PATTERNS.items():
        for match in re.finditer(pattern,data):
            if kind == 'database_uri_password':
                value=match.group(1).lower()
                if any(x in value for x in [b'password',b'placeholder',b'example',b'${',b'<']):
                    continue
            found.append(kind)
            break
    # Legacy service_role JWTs: decode only payload, never emit token contents.
    import base64
    for token in re.findall(rb'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',data):
        try:
            payload=token.split(b'.')[1]
            decoded=json.loads(base64.urlsafe_b64decode(payload+b'='*((-len(payload))%4)))
            if decoded.get('role')=='service_role':found.append('legacy_service_role')
        except (ValueError, TypeError):pass
    return sorted(set(found))

hits=[]
tracked=git('ls-files','-z').split(b'\0')
for name in filter(None,tracked):
    path=Path(name.decode('utf-8'))
    if path.is_file():
        kinds=categories(path.read_bytes())
        if kinds:hits.append({'current_path':str(path),'categories':kinds})
objects=git('rev-list','--objects','--all').splitlines()
count=0
for entry in objects:
    oid=entry.split(b' ',1)[0].decode()
    if git('cat-file','-t',oid).strip()!=b'blob':continue
    count+=1
    kinds=categories(git('cat-file','blob',oid))
    if kinds:hits.append({'history_blob':oid,'categories':kinds})
print(json.dumps({'tracked_files':len(list(filter(None,tracked))),
                  'history_blobs':count,'findings':hits},indent=2))
raise SystemExit(1 if hits else 0)
