import re

def make_sql_idempotent(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to match:
    # CREATE POLICY "Policy Name"
    #     ON table.name
    # Replace with:
    # DROP POLICY IF EXISTS "Policy Name" ON table.name;
    # CREATE POLICY "Policy Name"
    #     ON table.name

    pattern = re.compile(r'(CREATE\s+POLICY\s+\"([^\"]+)\"\s*\n\s*ON\s+([^\s\n]+))', re.MULTILINE)

    def replacer(match):
        full_match = match.group(1)
        policy_name = match.group(2)
        table_name = match.group(3)
        return f'DROP POLICY IF EXISTS "{policy_name}" ON {table_name};\n{full_match}'

    # First clean up any already-present DROP POLICY IF EXISTS right before
    # to avoid duplication if run multiple times
    content_clean = re.sub(r'DROP\s+POLICY\s+IF\s+EXISTS\s+\"[^\"]+\"\s+ON\s+[^\s;]+;\s*\n', '', content)
    
    new_content = pattern.sub(replacer, content_clean)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Updated {filepath} with idempotent DROP POLICY IF EXISTS statements.")

make_sql_idempotent('supabase/COMPLETE_SUPABASE_SETUP.sql')
make_sql_idempotent('supabase/migrations/002_security_rls.sql')
