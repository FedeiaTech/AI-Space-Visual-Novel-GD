# Tutorial de Scripting de Diálogos

Este documento detalla todas las instrucciones en formato JSON utilizadas para controlar los diálogos, personajes y eventos del juego.

## 1. Estructura de Diálogo y Personajes

### 1.1. Texto de Narrador

Esta es la forma más simple de mostrar texto. Oculta a todos los personajes en pantalla y resetea sus estados (posición, expresión, etc.). Es ideal para iniciar una escena o describir una situación.

```json
{
    "text": "En alguna parte del espacio, la Nave Spark N3 flotaba en silencio."
}
```

### 1.2. Declaración Completa de Personajes

Este comando se usa para hacer aparecer a los personajes en escena. Define qué personajes están presentes, dónde se ubican, su expresión, su orientación y quién habla. **Es la única instrucción que puede hacer aparecer personajes.**

- **`characters`**: Define qué personaje (`"Milka"`, `"Astro"`, etc.) ocupa cada posición (`"left"`, `"center"`, `"right"`, `"far_right"`).
- **`expressions`**: Asigna una expresión a cada personaje en escena. Si no se especifica para una posición, se usará `"idle"` por defecto.
- **`facing`**: Define hacia dónde mira cada personaje (`"left"`, `"right"`, `"center"`). Si no se especifica, se mantendrá la orientación anterior para esa posición. Si es la primera vez que aparecen, se asigna una por defecto (los de la derecha miran a la izquierda y viceversa).
- **`speaker`**: El personaje que está hablando en esta línea. Su nombre debe coincidir con uno de los definidos en `characters`.
- **`text`**: El diálogo que dice el `speaker`.

```json
{
    "characters": {
        "left": "Milka",
        "center": "Ori",
        "right": "Astro"
    },
    "expressions": {
        "left": "sad",
        "center": "idle",
        "right": "smile"
    },
    "facing": {
        "left": "right",
        "center": "right",
        "right": "left"
    },
    "speaker": "Astro",
    "text": "¡Es genial que estén todos aquí!"
}
```

### 1.3. Diálogo Simplificado (Continuación)

Una vez que los personajes están en escena, no necesitas volver a declararlos. Simplemente usa `speaker` y `text` para continuar la conversación. El sistema recordará quiénes están en pantalla, sus posiciones y su orientación.

```json
{
    "speaker": "Ori",
    "text": "Desde luego. ¿Cuál es el plan?"
}
```

### 1.4. Diálogo Simplificado con Cambio de Expresión

Puedes cambiar las expresiones de los personajes en una línea de diálogo simplificada añadiendo el campo `expressions`. Las posiciones y orientaciones se mantendrán como estaban.

```json
{
    "expressions": {
        "left": "happy",
        "right": "thoughtful"
    },
    "speaker": "Milka",
    "text": "¡Tengo una idea!"
}
```

## 2. Movimiento y Animación

### 2.1. Mover un Personaje (`move_character`)

Permite deslizar un personaje que ya está en pantalla a una nueva posición horizontal.

- **`position`**: La posición del personaje que se va a mover (`"left"`, `"center"`, etc.).
- **`offset`**: Cantidad de píxeles a desplazar (positivo para la derecha, negativo para la izquierda).
- **`duration`**: El tiempo en segundos que tardará el movimiento.

```json
{
    "move_character": {
        "position": "center",
        "offset": -150,
        "duration": 1.0
    }
}
```

## 3. Control de Escena y Entorno

### 3.1. Cargar una Localización y Música

Cambia el fondo del escenario y la música ambiental.

- **`location`**: El ID de la escena de fondo a cargar.
- **`music`**: El nombre del archivo de música (sin extensión) a reproducir.

```json
{
    "location": "decompression_chamber",
    "music": "track01"
}
```

### 3.2. Mostrar y Ocultar CGs (Imágenes de Evento)

Muestra una imagen a pantalla completa o como fondo.

- **`show_cg`**: Muestra la imagen con el ID especificado.
  - `instant`: Si es `true`, aparece de golpe. Si es `false`, usa una transición.
  - `full_screen`: Si es `true`, ocupa toda la pantalla. Por defecto es `false`.
- **`hide_cg`**: Oculta la CG actual.
  - `instant`: Si es `true`, desaparece de golpe.

*Nota: Si una escena comienza con una CG, es recomendable poner una línea de texto vacía (`{"text": "..."}`) después para asegurar que se muestre correctamente.*

```json
{"show_cg": "astro_entering", "instant": false, "full_screen": true}
```
```json
{"hide_cg": true, "instant": false}
```

### 3.3. Controlar Objetos Clickeables (`object`)

Permite mostrar u ocultar objetos interactivos en la escena.

- **`id`**: El identificador único del objeto.
- **`visible`**: `true` para mostrarlo, `false` para ocultarlo.

```json
{ "object": { "id": "chip", "visible": false } }
```

## 4. Flujo de Juego y Lógica

### 4.1. Anclas y Saltos (`anchor` y `goto`)

- **`anchor`**: Marca una línea específica en el diálogo con un nombre único. No hace nada visible, solo sirve como un punto de referencia.
- **`goto`**: Salta la ejecución del diálogo directamente a la línea marcada con el `anchor` correspondiente.

```json
{
    "anchor": "inicio_conversacion"
}
```
```json
{
    "goto": "inicio_conversacion"
}
```

### 4.2. Elecciones del Jugador (`choices`)

Presenta al jugador una lista de opciones. El diálogo se detiene hasta que se elige una.

- **`text`**: El texto que verá el jugador.
- **`goto`**: El `anchor` al que saltará el diálogo si se elige esta opción.
- **`requires_flag`**: (Opcional) La opción solo aparece si una bandera (`flag`) del juego tiene un valor específico.
- **`flag_value`**: (Opcional) El valor (`true` o `false`) que debe tener la `requires_flag`.
- **`requires_item`**: (Opcional) La opción solo aparece si el jugador tiene un objeto específico en su inventario.

```json
{
    "choices": [
        {"text": "Volver a la Nave", "goto": "first_enter_spark"},
        {"text": "Contemplar el espacio", "goto": "planet_explorer", "requires_flag": "mision_anomalia", "flag_value": true},
        {"text": "Consultar el Mapa", "goto": "map_dialog_options", "requires_item": "mapa_estelar"}
    ]
}
```

### 4.3. Modificar Banderas (`set_flag`)

Cambia el valor de una variable booleana (`true`/`false`) en el sistema de juego. Útil para registrar decisiones o eventos.

- **`id`**: El nombre de la bandera a modificar.
- **`value`**: El nuevo valor (`true` o `false`).

```json
{
    "text": "Ahora tienes acceso a los registros de la nave.",
    "set_flag": {
        "id": "mision_anomalia",
        "value": true
    }
}
```

### 4.4. Otorgar Ítems (`item_given`)

Añade uno o más ítems al inventario del jugador.

- **`id`**: Identificador único del ítem.
- **`name`**: Nombre visible del ítem.
- **`description`**: Descripción del ítem.
- **`quantity`**: Cantidad a otorgar.
- **`icon_path`**: Ruta al ícono del inventario.

```json
{
    "item_given": [
        {
            "id": "llave_antigua",
            "name": "Llave Antigua",
            "description": "Una llave oxidada que parece abrir algo muy viejo.",
            "quantity": 1,
            "icon_path": "res://Assets/Inventory_icons/old_key.png"
        }
    ]
}
```

### 4.5. Acciones Complejas (`action`)

Ejecuta acciones de juego más complejas, como cambiar de escena por completo.

- **`type`: "load_scene"**: Carga una escena de Godot completamente nueva.
  - `scene_file`: El nombre del archivo de escena (`.tscn`) a cargar.
  - `anchor`: Un `anchor` en el archivo de diálogo de la nueva escena al que saltar directamente.

```json
{
    "action": {
        "type": "load_scene",
        "scene_file": "entering_ship",
        "anchor": "first_entering"
    }
}
```

### 4.6. Cambiar Modo de Juego (`flow`)

Permite cambiar entre el modo diálogo y otros modos, como la exploración del escenario.

- **`flow`: "explore"**: Detiene el diálogo y activa la interfaz de interacción con el escenario, permitiendo al jugador hacer clic en objetos.

```json
{
    "text": "Ahora puedes examinar la habitación.",
    "flow": "explore"
}
```

## 5. Control del Tiempo

### 5.1. Establecer y Mostrar el Temporizador

Inicia o modifica el valor de un temporizador y controla su visibilidad en la interfaz.

- **`set_time_absolute`**: Establece el tiempo a un valor exacto en formato "MM:SS".
- **`show_time_ui`**: `true` para mostrar el temporizador, `false` para ocultarlo.

```json
{"set_time_absolute": "15:00", "show_time_ui": true}
```
```json
{"show_time_ui": false}
```

### 5.2. Modificar el Tiempo

Suma o resta segundos al temporizador actual.

- **`modify_time`**: El número de segundos a añadir (positivo) o quitar (negativo).

```json
{
    "text": "¡Has ganado algo de tiempo extra!",
    "modify_time": 300
}
```