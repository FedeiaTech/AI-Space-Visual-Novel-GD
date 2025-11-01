import os
import re

# Ruta real al directorio del proyecto Godot (cambia esto según tu estructura)
project_path = "./"  # O algo como "C:/Users/TuUsuario/Godot/MyProject"

for root, dirs, files in os.walk(project_path):
    for file in files:
        if file.endswith(".gd"):
            full_path = os.path.join(root, file)
            print(f"\n== {os.path.relpath(full_path, project_path)} ==")
            with open(full_path, encoding="utf-8") as f:
                for line in f:
                    match = re.match(r'\s*func\s+(\w+)', line)
                    if match:
                        print("   -", match.group(1))
