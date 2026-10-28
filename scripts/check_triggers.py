import re

with open('supabase/COMPLETE_SUPABASE_SETUP.sql', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.finditer(r'CREATE\s+TRIGGER\s+([a-zA-Z0-9_]+)\s+.*?ON\s+([^\s;]+)', text, re.IGNORECASE | re.DOTALL)
found = []
for m in matches:
    trg = m.group(1)
    tbl = m.group(2)
    has_drop = f"DROP TRIGGER IF EXISTS {trg}" in text
    found.append((trg, tbl, has_drop))

print(f"Total triggers: {len(found)}")
for trg, tbl, has_drop in found:
    print(f"Trigger {trg} on {tbl} -> Has DROP? {has_drop}")
