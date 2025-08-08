> [!TIP]
> # **Guía Completa de Comandos JSON para tu Juego**
> 
> Esta guía documenta todos los comandos que puedes usar en tus archivos de diálogo `.json` para controlar:
> - **Narrativa**  
> - **Elementos visuales**  
> - **Lógica del juego**  
> - **Flujo de las escenas**
> 
> ---
> 
> ## 1. Comandos de **Diálogo y Personajes** <a id="seccion-dialogo"></a>
> Estos comandos controlan el texto en pantalla y los personajes que aparecen.
> 
> ---
> 
> ### [`text`](#glosario-text) <a id="comando-text"></a>
> **Propósito:** Muestra una línea de diálogo o una descripción.  
> **Sintaxis:**
> ```json
> "text": "Tu texto aquí."
> ```
> **Ejemplo:**
> ```json
> {"text": "En alguna parte del espacio..."}
> ```
> **Notas:** Si no se especifica un `speaker`, el texto se considera narrado.
> 
> ---
> 
> ### [`speaker`](#glosario-speaker) <a id="comando-speaker"></a>
> **Propósito:** Asigna el texto a un personaje, mostrando su nombre en la interfaz.  
> **Sintaxis:**
> ```json
> "speaker": "NombreDelPersonaje"
> ```
> **Ejemplo:**
> ```json
> {"speaker": "Astro", "text": "¿Qué pasó? mi cabeza..."}
> ```
> **Notas:** El nombre debe coincidir con los definidos en tu sistema (`Character.Name`).
> 
> ---
> 
> ### [`show_character`](#glosario-show_character) <a id="comando-show_character"></a>
> **Propósito:** Muestra o cambia el sprite del personaje visible.  
> **Sintaxis:**
> ```json
> "show_character": "NombreDelPersonaje"
> ```
> **Ejemplo:**
> ```json
> {"speaker": "IA", "text": "Sistema de comunicación desconectado.", "show_character": "Astro_EVA"}
> ```
> **Notas:** Para ocultar a todos los personajes:  
> ```json
> "show_character": "NARRATOR"
> ```
> 
> ---
> 
> ### [`expression`](#glosario-expression) <a id="comando-expression"></a>
> **Propósito:** Cambia la expresión facial o el estado del sprite.  
> **Sintaxis:**
> ```json
> "expression": "nombre_expresion"
> ```
> **Ejemplo:**
> ```json
> {"speaker": "Astro", "text": "Orii. estas. ey...", "expression": "scare"}
> ```
> **Notas:** El script `text_blip_sound.gd` buscará un sonido asociado a esta expresión.
> 
> ---
> 
> ## 2. Comandos de **Flujo de Escena y Navegación** <a id="seccion-flujo"></a>
> Controlan el orden de lectura del diálogo y transiciones.
> 
> ---
> 
> ### [`goto`](#glosario-goto) <a id="comando-goto"></a>
> **Propósito:** Salta la ejecución a un `anchor`.  
> **Ejemplo:**
> ```json
> {"goto": "end"}
> ```
> 
> ---
> 
> ### [`anchor`](#glosario-anchor) <a id="comando-anchor"></a>
> **Propósito:** Marca un punto de destino para `goto` o `action`.  
> **Ejemplo:**
> ```json
> {"anchor": "comunication_problems"}
> ```
> 
> ---
> 
> ### [`action`](#glosario-action) <a id="comando-action"></a>
> **Propósito:** Ejecuta acciones complejas.
> ```json
> "action": {"type": "nombre_accion", "parametro1": "valor1"}
> ```
> **Tipo `load_scene`:**
> ```json
> {
>   "text": "Ir al corredor central",
>   "action": {
>     "type": "load_scene",
>     "scene_file": "spaceship_interior",
>     "anchor": "ori__stuned"
>   }
> }
> ```
> **Tipo `goto_internal`:**
> ```json
> {
>   "text": "Revisar los sistemas de nuevo",
>   "action": {
>     "type": "goto_internal",
>     "anchor": "comunication_problems"
>   }
> }
> ```
> 
> ---
> 
> ### [`next_scene`](#glosario-next_scene) <a id="comando-next_scene"></a>
> **Propósito:** Define la escena a cargar al terminar el archivo.  
> ```json
> {"next_scene": "first_scene", "transition": "fade"}
> ```
> 
> ---
> 
> ## 3. Comandos de **Ambiente y Visuales** <a id="seccion-ambiente"></a>
> 
> ---
> 
> ### [`location`](#glosario-location) <a id="comando-location"></a>
> **Propósito:** Cambia el fondo.  
> ```json
> {"location": "scene0_spaceship", "music": "track01"}
> ```
> 
> ---
> 
> ### [`music`](#glosario-music) <a id="comando-music"></a>
> **Propósito:** Cambia la música de fondo.  
> ```json
> {"location": "scene0_spaceship", "music": "track01"}
> ```
> 
> ---
> 
> ## 4. Comandos de **Lógica de Juego e Inventario** <a id="seccion-logica"></a>
> 
> ---
> 
> ### [`item_given`](#glosario-item_given) <a id="comando-item_given"></a>
> **Propósito:** Añade objetos al inventario.  
> ```json
> {
>   "item_given": [
>     {"id": "llave_antigua", "name": "Llave Antigua", "quantity": 1}
>   ]
> }
> ```
> 
> ---
> 
> ### [`set_flag`](#glosario-set_flag) <a id="comando-set_flag"></a>
> **Propósito:** Establece o modifica una bandera.  
> ```json
> {"text": "...", "set_flag": {"id": "mision_anomalia", "value": true}}
> ```
> 
> ---
> 
> ## 5. Comandos de **Elecciones del Jugador** <a id="seccion-choices"></a>
> 
> ---
> 
> ### [`choices`](#glosario-choices) <a id="comando-choices"></a>
> **Propósito:** Presenta opciones al jugador.  
> ```json
> {
>   "anchor": "return_to_choices",
>   "choices": [
>     {
>       "text": "Volver a la Nave de Origen",
>       "action": {
>         "type": "load_scene",
>         "scene_file": "spaceship_interior",
>         "anchor": "return_point_from_space"
>       }
>     },
>     {
>       "text": "Explorar el Planeta",
>       "goto": "planet_explorer",
>       "requires_flag": "mision_anomalia",
>       "flag_value": true
>     },
>     {
>       "text": "Consultar el Mapa",
>       "goto": "map_dialog_options",
>       "requires_item": "map_rasgado"
>     }
>   ]
> }
> ```
> 
> ---
> 
> ## 6. Comandos de **Gestión del Tiempo** <a id="seccion-tiempo"></a>
> 
> ---
> 
> ### [`set_time_absolute`](#glosario-set_time_absolute) <a id="comando-set_time_absolute"></a>
> **Ejemplo:**
> ```json
> {"set_time_absolute": "00:45", "show_time_ui": true}
> ```
> 
> ---
> 
> ### [`modify_time`](#glosario-modify_time) <a id="comando-modify_time"></a>
> **Ejemplo (resta 5 minutos):**
> ```json
> {"speaker": "Astro", "text": "¡Reinicia rápido!", "modify_time": -300}
> ```
> 
> ---
> 
> ### [`show_time_ui`](#glosario-show_time_ui) <a id="comando-show_time_ui"></a>
> **Ejemplo:**
> ```json
> {"speaker": "Astro", "text": "¡Vamos!", "show_time_ui": false}
> ```
> 
> ---
> 
> ## **Glosario Rápido** <a id="glosario"></a>
> 
> **Diálogo y Personajes:** [`text`](#comando-text) · [`speaker`](#comando-speaker) · [`show_character`](#comando-show_character) · [`expression`](#comando-expression)  
> **Flujo y Navegación:** [`goto`](#comando-goto) · [`anchor`](#comando-anchor) · [`action`](#comando-action) · [`next_scene`](#comando-next_scene)  
> **Ambiente y Visuales:** [`location`](#comando-location) · [`music`](#comando-music)  
> **Lógica e Inventario:** [`item_given`](#comando-item_given) · [`set_flag`](#comando-set_flag)  
> **Elecciones:** [`choices`](#comando-choices)  
> **Tiempo:** [`set_time_absolute`](#comando-set_time_absolute) · [`modify_time`](#comando-modify_time) · [`show_time_ui`](#comando-show_time_ui)
