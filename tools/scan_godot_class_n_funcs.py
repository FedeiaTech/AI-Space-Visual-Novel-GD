import os
import re

project_path = "./"  # Ruta real a tu proyecto de Godot

for root, dirs, files in os.walk(project_path):
    for file in files:
        if file.endswith(".gd"):
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, project_path)
            with open(full_path, encoding="utf-8") as f:
                lines = f.readlines()

            class_name = None
            extends = None
            functions = []

            for line in lines:
                if not class_name:
                    match_class = re.match(r'\s*class_name\s+(\w+)', line)
                    if match_class:
                        class_name = match_class.group(1)
                if not extends:
                    match_extends = re.match(r'\s*extends\s+(\w+)', line)
                    if match_extends:
                        extends = match_extends.group(1)
                match_func = re.match(r'\s*func\s+(\w+)', line)
                if match_func:
                    functions.append(match_func.group(1))

            print(f"\n📂 Archivo: {rel_path}")
            if class_name:
                print(f"🔹 class_name: {class_name}")
            if extends:
                print(f"🔸 Nodo Godot (extends): {extends}")
            if functions:
                print("🔧 Funciones:")
                for func in functions:
                    print("   -", func)
