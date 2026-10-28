import re

with open('supabase/COMPLETE_SUPABASE_SETUP.sql', 'r', encoding='utf-8') as f:
    text = f.read()

inserts = re.findall(r'INSERT\s+INTO\s+([^\s(]+)', text, re.IGNORECASE)
print("Insert targets:", set(inserts))
