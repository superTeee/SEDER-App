#!/usr/bin/env python3
"""inject-sql-057.command — Injiserer Fermin Perez SQL direkte i Chrome via JavaScript"""
import subprocess, os, base64, sys

script_dir = os.path.dirname(os.path.abspath(__file__))
sql_file = os.path.join(script_dir, 'supabase/migrations/057_fermin_perez_seed.sql')

print(f"Leser SQL fra: {sql_file}")
with open(sql_file, 'r', encoding='utf-8') as f:
    sql = f.read()
print(f"SQL lest: {len(sql)} tegn")

# Base64-enkod SQL for trygg embedding i JavaScript
sql_b64 = base64.b64encode(sql.encode('utf-8')).decode('ascii')

# JavaScript som dekoder base64 og setter innhold i CodeMirror 6
js_code = """(function(){
  try {
    var b64='""" + sql_b64 + """';
    var sql=atob(b64);
    var e=document.querySelector('.cm-editor');
    if(!e) return 'FEIL: ingen .cm-editor funnet';
    var v=null;
    var keys=Object.getOwnPropertyNames(e);
    for(var i=0;i<keys.length;i++){
      var val=e[keys[i]];
      if(val&&typeof val==='object'&&val.state&&val.dispatch){v=val;break;}
    }
    if(!v) return 'FEIL: ingen CodeMirror view';
    v.dispatch({changes:{from:0,to:v.state.doc.length,insert:sql}});
    v.focus();
    setTimeout(function(){
      var btns=document.querySelectorAll('button');
      for(var i=0;i<btns.length;i++){
        if(btns[i].textContent.trim()==='Run'||btns[i].textContent.trim().startsWith('Run ')){
          btns[i].click();
          return;
        }
      }
    },800);
    return 'OK: SQL satt inn (' + sql.length + ' tegn), Run planlagt';
  } catch(err) {
    return 'FEIL: '+err.toString();
  }
})()"""

# Escaping for AppleScript
js_escaped = js_code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ').replace('\r', '')

applescript = '''
tell application "Google Chrome"
    activate
end tell
delay 0.5
tell application "Google Chrome"
    set jsResult to execute front window's active tab javascript "''' + js_escaped + '''"
    display dialog "Migrasjon 057 — Fermin Perez:" & return & jsResult buttons {"OK"} default button "OK"
end tell
'''

print("Kjører AppleScript via Google Chrome JavaScript-injeksjon...")
result = subprocess.run(['osascript', '-e', applescript], capture_output=True, text=True, timeout=30)
print("stdout:", result.stdout.strip())
print("stderr:", result.stderr.strip())
print("returncode:", result.returncode)

if result.returncode != 0:
    print("\nFEIL — se stderr over")
else:
    print("\nFerdig! Sjekk Supabase for resultater.")

input("\nTrykk Enter for å lukke dette vinduet...")
