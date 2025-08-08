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
> Se usan en secuencias narrativas para contar la historia, mostrar conversaciones y expresar emociones.
> 
> ---
> 
> ### [`text`](#glosario-text) <a id="comando-text"></a>
> **Propósito:** Muestra una línea de diálogo o una descripción. Es el comando principal para que el jugador lea lo que ocurre.  
> **Sintaxis:**
> ```json
> "text": "Tu texto aquí."
> ```
> **Ejemplo:**
> ```json
> {"text": "En alguna parte del espacio..."}
> ```
> **Notas y uso avanzado:**  
> - Puede ser narrativo (sin personaje) o parte de un diálogo.  
> - Útil para descripciones del entorno, pensamientos internos o mensajes del narrador.  
> - Evita textos demasiado largos en una sola línea para mejorar la legibilidad.
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
> **Notas y uso avanzado:**  
> - El nombre debe coincidir con el que está definido en tu sistema (`Character.Name`).  
> - Permite diferenciar diálogos de distintos personajes incluso si usan el mismo sprite.  
> - Se puede combinar con `expression` para dar más vida a la conversación.
> 
> ---
> 
> ### [`show_character`](#glosario-show_character) <a id="comando-show_character"></a>
> **Propósito:** Muestra o cambia el sprite del personaje visible en pantalla.  
> **Sintaxis:**
> ```json
> "show_character": "NombreDelPersonaje"
> ```
> **Ejemplo:**
> ```json
> {"speaker": "IA", "text": "Sistema de comunicación desconectado.", "show_character": "Astro_EVA"}
> ```
> **Notas y uso avanzado:**  
> - Se usa para mostrar al personaje hablando o reaccionando.  
> - Para ocultar a todos los personajes:  
>   ```json
>   "show_character": "NARRATOR"
>   ```  
> - Puede cambiar la imagen del personaje a otra variante (por ejemplo: traje diferente).
> 
> ---
> 
> ### [`expression`](#glosario-expression) <a id="comando-expression"></a>
> **Propósito:** Cambia la expresión facial o el estado del sprite para reflejar emociones o reacciones.  
> **Sintaxis:**
> ```json
> "expression": "nombre_expresion"
> ```
> **Ejemplo:**
> ```json
> {"speaker": "Astro", "text": "Orii. estas. ey...", "expression": "scare"}
> ```
> **Notas y uso avanzado:**  
> - Útil para dar dinamismo a las escenas.  
> - El script `text_blip_sound.gd` buscará un sonido asociado a esta expresión.  
> - Ideal para transmitir tensión, felicidad, sorpresa o enojo en diálogos.
> 
> ---
> 
> ## 2. Comandos de **Flujo de Escena y Navegación** <a id="seccion-flujo"></a>
> Controlan el orden de lectura del diálogo y las transiciones de una parte del guion a otra.
> 
> ---
> 
> ### [`goto`](#glosario-goto) <a id="comando-goto"></a>
> **Propósito:** Salta la ejecución a un `anchor` dentro del mismo archivo JSON.  
> **Ejemplo:**
> ```json
> {"goto": "end"}
> ```
> **Notas:** Útil para ramificar diálogos según elecciones o condiciones previas.
> 
> ---
> 
> ### [`anchor`](#glosario-anchor) <a id="comando-anchor"></a>
> **Propósito:** Marca un punto de destino para `goto` o `action`.  
> **Ejemplo:**
> ```json
> {"anchor": "comunication_problems"}
> ```
> **Notas:** Piensa en los `anchor` como "marcadores" o "checkpoints" dentro de tu guion.
> 
> ---
> 
> ### [`action`](#glosario-action) <a id="comando-action"></a>
> **Propósito:** Ejecuta acciones complejas o transiciones.  
> **Sintaxis general:**
> ```json
> "action": {"type": "nombre_accion", "parametro1": "valor1"}
> ```
> **Ejemplo tipo `load_scene`:**
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
> **Ejemplo tipo `goto_internal`:**
> ```json
> {
>   "text": "Revisar los sistemas de nuevo",
>   "action": {
>     "type": "goto_internal",
>     "anchor": "comunication_problems"
>   }
> }
> ```
> **Notas:**  
> - `load_scene` carga una escena diferente.  
> - `goto_internal` salta dentro de la misma escena.  
> - Se pueden crear otros tipos personalizados según la lógica del juego.
> 
> ---
> 
> ### [`next_scene`](#glosario-next_scene) <a id="comando-next_scene"></a>
> **Propósito:** Define la siguiente escena a cargar cuando termina el archivo.  
> ```json
> {"next_scene": "first_scene", "transition": "fade"}
> ```
> **Notas:** Ideal para una narrativa lineal, evitando el uso repetitivo de `load_scene`.
> 
> ---
> 
> ## 3. Comandos de **Ambiente y Visuales** <a id="seccion-ambiente"></a>
> Estos comandos afectan el fondo, la música y el ambiente de la escena.
> 
> ---
> 
> ### [`location`](#glosario-location) <a id="comando-location"></a>
> **Propósito:** Cambia el fondo de la escena.  
> ```json
> {"location": "scene0_spaceship", "music": "track01"}
> ```
> **Notas:** Puede acompañarse de `music` para sincronizar audio y visual.
> 
> ---
> 
> ### [`music`](#glosario-music) <a id="comando-music"></a>
> **Propósito:** Cambia la música de fondo.  
> ```json
> {"location": "scene0_spaceship", "music": "track01"}
> ```
> **Notas:** Asegúrate de que el nombre de pista exista en tu sistema de audio.
> 
> ---
> 
> ## 4. Comandos de **Lógica de Juego e Inventario** <a id="seccion-logica"></a>
> 
> ---
> 
> ### [`item_given`](#glosario-item_given) <a id="comando-item_given"></a>
> **Propósito:** Añade objetos al inventario del jugador.  
> ```json
> {
>   "item_given": [
>     {"id": "llave_antigua", "name": "Llave Antigua", "quantity": 1}
>   ]
> }
> ```
> **Notas:**  
> - `id` debe coincidir con un ítem válido en tu base de datos.  
> - Se puede usar para recompensas o progresión de la historia.
> 
> ---
> 
> ### [`set_flag`](#glosario-set_flag) <a id="comando-set_flag"></a>
> **Propósito:** Activa o modifica una bandera lógica que puede condicionar eventos futuros.  
> ```json
> {"text": "...", "set_flag": {"id": "mision_anomalia", "value": true}}
> ```
> **Notas:** Ideal para controlar elecciones persistentes o desbloquear contenido.
> 
> ---
> 
> ## 5. Comandos de **Elecciones del Jugador** <a id="seccion-choices"></a>
> Permiten al jugador decidir y ramificar la historia.
> 
> ---
> 
> ### [`choices`](#glosario-choices) <a id="comando-choices"></a>
> **Propósito:** Presenta opciones interactivas.  
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
> **Notas:**  
> - Puedes condicionar opciones según ítems (`requires_item`) o banderas (`requires_flag`).  
> - Útil para crear decisiones con consecuencias reales.
> 
> ---
> 
> ## 6. Comandos de **Gestión del Tiempo** <a id="seccion-tiempo"></a>
> Controlan el reloj interno del juego y su visibilidad.
> 
> ---
> 
> ### [`set_time_absolute`](#glosario-set_time_absolute) <a id="comando-set_time_absolute"></a>
> **Propósito:** Fija la hora del reloj del juego.  
> **Ejemplo:**
> ```json
> {"set_time_absolute": "00:45", "show_time_ui": true}
> ```
> **Notas:** Ideal para escenas que ocurren en momentos clave.
> 
> ---
> 
> ### [`modify_time`](#glosario-modify_time) <a id="comando-modify_time"></a>
> **Propósito:** Suma o resta segundos al reloj interno.  
> **Ejemplo (resta 5 minutos):**
> ```json
> {"speaker": "Astro", "text": "¡Reinicia rápido!", "modify_time": -300}
> ```
> **Notas:** Útil para mecánicas de cuenta regresiva o eventos cronometrados.
> 
> ---
> 
> ### [`show_time_ui`](#glosario-show_time_ui) <a id="comando-show_time_ui"></a>
> **Propósito:** Muestra u oculta el reloj en pantalla.  
> **Ejemplo:**
> ```json
> {"speaker": "Astro", "text": "¡Vamos!", "show_time_ui": false}
> ```
> **Notas:** Perfecto para ocultar el tiempo en escenas narrativas y mostrarlo en desafíos.
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
