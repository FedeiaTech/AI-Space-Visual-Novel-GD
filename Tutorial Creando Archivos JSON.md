# Tutorial: Creando Historias y Diálogos con Archivos JSON

Este tutorial te guiará a través de la estructura de los archivos JSON. Cada elemento en el JSON representa una "línea" en tu historia, que el juego procesará en secuencia.

---

### **Conceptos Clave de una Línea de Diálogo (Objeto JSON)**

Cada objeto dentro del array principal `[]` del archivo JSON representa una acción, un diálogo, un cambio de escena o un punto de control en la historia.

1.  ### **`{"location": "nombre_escena", "music": "nombre_musica"}`**

    * **Propósito:** Define el **fondo visual** de la escena y la **música de fondo** que sonará.
    * **`"location"`:** (Obligatorio) El nombre del archivo de imagen de fondo (sin la extensión y sin la ruta `res://Assets/Scenes_images/`). Por ejemplo, `"spaceship_room"` buscará `res://Assets/Scenes_images/spaceship_room.png`.
    * **`"music"`:** (Opcional) El nombre del archivo de audio de la música (sin la extensión y sin la ruta `res://Assets/Sounds/BGM/`). Por ejemplo, `"track01"` buscará `res://Assets/Sounds/BGM/track01.mp3`.
    * **Cuándo Usarlo:** Típicamente, al **inicio de una nueva escena** o cuando el fondo o la música cambian drásticamente durante un mismo diálogo. Idealmente, la primera línea de cada nuevo archivo JSON de diálogo debería definir la ubicación y música iniciales.

    * **Ejemplo de Uso:**
        ```json
        {"location": "scene0_spaceship", "music": "track01"}
        ```

2.  ### **`{"text": "Tu texto de diálogo o narración aquí"}`**

    * **Propósito:** Muestra un mensaje de **narración** o un pensamiento.
    * **`"text"`:** (Obligatorio) El texto que aparecerá en la caja de diálogo.
    * **Características:** No requiere un orador. La "caja del orador" se ocultará automáticamente, ideal para descripciones inmersivas o momentos introspectivos.
    * **Ejemplo de Uso:**
        ```json
        {"text": "En alguna parte del espacio..."}
        ```

3.  ### **`{"speaker": "NombrePersonaje", "text": "Diálogo del personaje", "show_character": "SpritePersonaje", "expression": "expresion_personaje"}`**

    * **Propósito:** Muestra un **diálogo de un personaje específico**.
    * **`"speaker"`:** (Obligatorio) El nombre del personaje que habla. Puede ser el nombre de un personaje (`"Astro"`, `"Milka"`) o el valor especial `"IA"` para el narrador.
    * **`"text"`:** (Obligatorio) El texto que dirá el personaje.
    * **`"show_character"`:** (Opcional) El nombre del sprite del personaje a mostrar. Esto es útil para cambiar la representación visual del personaje (ej. de Astro normal a Astro con traje EVA). Si no se usa, el juego intentará mostrar el sprite predeterminado asociado con el `speaker`.
    * **`"expression"`:** (Opcional) La expresión facial o pose del personaje (ej. `"happy"`, `"excited"`). Solo funciona si el sprite del personaje tiene animaciones o texturas de expresión definidas.
    * **Ejemplo de Uso:**
        ```json
        {"speaker": "Astro", "text": "¿Qué paso? mi cabeza...", "show_character": "Astro_EVA"}
        {"speaker": "IA", "text": "Sistema de comunicación desconectado. Se sugiere reiniciar."}
        {"speaker": "Astro", "text": "Ahora tengo expresiones nuevas", "expression": "happy"}
        {"speaker": "Milka", "text": "Hey. No sos el único", "show_character": "Astro", "expression":"happy"}
        ```

4.  ### **`{"anchor": "nombre_ancla"}`**

    * **Propósito:** Define un **punto de referencia** en tu diálogo al que puedes saltar desde otras partes de la historia.
    * **`"anchor"`:** (Obligatorio) Un identificador único para este punto.
    * **Características:** Una línea con `anchor` no es visible para el jugador. Simplemente marca una posición en el archivo JSON.
    * **Ejemplo de Uso:**
        ```json
        {"anchor": "comunication_problems"}
        ```

5.  ### **`{"choices": [ ... ]}`**

    * **Propósito:** Presenta al jugador una serie de **opciones** que influirán en el flujo de la historia.
    * **`"choices"`:** (Obligatorio) Un array de objetos, donde cada objeto representa una opción.
    * **Estructura de una Opción:**
        * **`{"text": "Texto de la opción", "goto": "nombre_ancla"}`:** Una opción que, al seleccionarse, hace que el diálogo **salte a un `anchor` dentro del *mismo* archivo JSON**.
        * **`{"text": "Texto de la opción", "action": { ... }}`:** Una opción que, al seleccionarse, ejecuta una **acción más compleja** (como cargar una nueva escena de diálogo).
        * **`"item_given"`:** (Opcional, dentro de una opción) Permite dar ítems al jugador al seleccionar esa opción. La estructura es la misma que la de `item_given` a nivel de línea (ver punto 7).
    * **Ejemplo de Uso:**
        ```json
        {"choices":
            [
                {"text": "Reiniciar IA", "goto": "first_choice"},
                {"text": "Seguir intentando comunicarse", "goto": "second_choice"}
            ]
        }
        ```
        ```json
        {"choices": [
            {"text": "Volver a la Nave de Origen", "action": {"type": "load_scene", "scene_file": "first_scene", "anchor": "return_point_from_space"}},
            {"text": "Explorar el Planeta", "action": {"type": "load_scene", "scene_file": "planet_surface", "anchor": "landing_site"}},
            {"text": "Consultar el Mapa", "goto": "map_dialog_options"}
            ]
        }
        ```

6.  ### **`{"goto": "nombre_ancla"}`**

    * **Propósito:** Hace que el flujo del diálogo **salte a un `anchor` específico** dentro del *mismo* archivo JSON.
    * **`"goto"`:** (Obligatorio) El nombre del `anchor` al que se debe saltar.
    * **Cuándo Usarlo:** Para bifurcaciones que no requieren una elección del jugador, bucles en el diálogo, o para consolidar caminos hacia un punto común.
    * **Ejemplo de Uso:**
        ```json
        {"goto": "end"}
        {"goto": "comunication_problems"}
        ```

7.  ### **`{"item_given": { ... }}` o `{"item_given": [ { ... }, { ... } ]}`**

    * **Propósito:** Otorga uno o varios ítems al inventario del jugador.
    * **`"item_given"`:** (Obligatorio) Puede ser un **objeto único** para un solo ítem o un **array de objetos** para múltiples ítems.
    * **Estructura de un Ítem:**
        * **`"id"`:** (Obligatorio) Un identificador único del ítem (ej. `"llave_antigua"`).
        * **`"name"`:** (Obligatorio) El nombre legible del ítem (ej. `"Llave Antigua"`).
        * **`"description"`:** (Opcional) Una breve descripción del ítem.
        * **`"quantity"`:** (Opcional, por defecto 1) La cantidad de este ítem a añadir.
        * **`"icon_path"`:** (Opcional) La ruta al icono del ítem (ej. `"res://Assets/Inventory_icons/old_key.png"`).
    * **Cuándo Usarlo:** En cualquier línea donde quieras que el jugador reciba un ítem, ya sea como parte de una elección o simplemente al avanzar el diálogo.
    * **Ejemplo de Uso:**
        ```json
        {"anchor": "third_choice", "item_given":
            {"id": "llave_antigua",
            "name": "Llave Antigua",
            "quantity": 3,
            "icon_path": "res://Assets/Inventory_icons/old_key.png"}
        }
        ```
        ```json
        {"speaker": "Milka", "text": "Ahora hablo yo. Me llamo Milka.", "item_given": [
            { "id": "ia_chip_alpha", "name": "Chip de IA (Alpha)", "quantity": 2, "icon_path": "res://Assets/Inventory_icons/chip.png" },
            { "id": "lalala", "name": "lalala", "quantity": 3 }
            ]
        }
        ```

8.  ### **`{"action": { "type": "tipo_accion", ... }}`**

    * **Propósito:** Ejecuta una acción programática más compleja, como cargar una nueva escena de diálogo.
    * **`"action"`:** (Obligatorio) Un objeto que define el tipo de acción y sus parámetros.
    * **`"type"`:** (Obligatorio, dentro de `action`) El tipo de acción a ejecutar.
        * **`"load_scene"`:**
            * **`"scene_file"`:** (Obligatorio) El nombre del archivo JSON de la nueva escena de diálogo a cargar (ej. `"first_scene"` cargará `res://Resources/Story/first_scene.json`).
            * **`"anchor"`:** (Opcional) Un `anchor` dentro del `scene_file` de destino al que saltar directamente.
            * **`"transition"`:** (Opcional, por defecto `"fade"`) El tipo de transición visual (ej. `"fade"`).
    * **Cuándo Usarlo:** Cuando una elección o un punto de la historia debe llevar a un archivo de diálogo completamente diferente, activando una transición completa de escena.
    * **Ejemplo de Uso:**
        ```json
        {"action": {"type": "load_scene", "scene_file": "first_scene", "anchor": "return_point_from_space"}}
        ```

---

### **¿Por qué `next_scene` ya no es necesario (y por qué `action` es mejor)?**

En versiones anteriores, podías usar `{"next_scene": "nombre_escena", "transition": "fade"}` para cargar una nueva escena. Si bien esto sigue siendo técnicamente posible, **ya no es la forma preferida ni recomendada** de cambiar de escena en tu juego.

**La razón es la introducción del concepto `"action"`:**

* **Mayor Flexibilidad:** La estructura `"action"` es mucho más versátil. No solo te permite cargar una nueva escena (`"type": "load_scene"`), sino que está diseñada para expandirse fácilmente. En el futuro, podrías añadir otros tipos de acciones como `"open_map"`, `"trigger_event"`, `"start_minigame"`, etc., todo bajo la misma estructura. `next_scene` era demasiado específico.
* **Centralización y Claridad:** Al usar `action` para todas las operaciones "programáticas" de cambio de flujo (ya sea una nueva escena o un evento), tu JSON se vuelve más consistente y fácil de entender. Todo lo que el juego "hace" (más allá de mostrar texto o tomar decisiones `goto`) está encapsulado en una `action`.
* **Preparación para el Futuro:** Adoptar `"action"` desde ahora te ahorrará refactorizaciones si decides añadir más tipos de interactividad que requieran ejecutar código.

**En resumen:** Aunque `next_scene` podría seguir funcionando en tu código base, te recomendamos **siempre usar la estructura `{"action": {"type": "load_scene", ...}}`** cuando quieras cambiar a un nuevo archivo de diálogo/escena. Esto alinea tu creación de historias con las capacidades más robustas y escalables del juego.
