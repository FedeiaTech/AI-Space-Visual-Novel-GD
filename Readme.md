# AI Space Visual Novel - Versión 0.0.5 Alpha

¡Bienvenido al repositorio de **AI Space Visual Novel**! Este proyecto es un juego de novela visual en desarrollo, creado con Godot Engine, que te sumergirá en una narrativa interactiva con elementos de ciencia ficción.

## Links
* [Mejoras Técnicas](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Novedades%20tecnicas.md)
* [Tutorial de archivos JSON](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Tutorial%20Archivos%20JSON.md)

---

## ✨ Nuevas Características y Mejoras (v0.0.5) - 08-07-2025

Esta versión se centra en la **implementación de sistemas narrativos dinámicos** que aumentan la rejugabilidad y la profundidad de la historia, junto con una **significativa optimización de las transiciones de escena y la gestión de personajes** para una experiencia más fluida y sin errores.

### Sistema de Diálogos Condicionales y Lógica Narrativa

Se ha ampliado el sistema de diálogo para que la narrativa responda de manera inteligente a las acciones del jugador, permitiendo múltiples caminos en la historia.

* **Diálogos Condicionales Basados en Ítems**: Las opciones de diálogo ahora pueden requerir la posesión de un ítem específico en el inventario del jugador. El `CommandProcessor.gd` filtra automáticamente las opciones, mostrando solo las disponibles, lo que evita "callejones sin salida" en la trama y añade una capa de interacción con el entorno.
* **Sistema de Banderas de Misión (Quest Flags)**: `GameManager.gd` ahora gestiona un sistema de banderas de misión para rastrear el progreso del jugador. Se han añadido nuevos comandos al JSON de diálogo (como **`set_flag`**) para que la historia pueda activar o desactivar estas banderas dinámicamente. Esto permite que las opciones de diálogo y los eventos de la historia cambien según el estado de las misiones.
* **Optimización de la Ejecución de Comandos**: Se ha corregido el orden de ejecución en `CommandProcessor.gd` para asegurar que los comandos que establecen estados (`set_flag`, `item_given`) se procesen antes que los comandos que dependen de ellos (`choices`), garantizando la coherencia de la lógica de juego.

### Sistema de Tiempo Regresivo

Se ha implementado un sistema de temporizador que introduce presión y consecuencias en la narrativa, haciendo que el tiempo sea un recurso más del juego.

* **Gestión Centralizada del Tiempo**: Un nuevo **Autoload (Singleton)**, `TimeManager.gd`, se encarga de toda la lógica del temporizador. Este sistema gestiona el conteo de segundos, formatea la visualización de la hora y emite una señal para mantener la interfaz de usuario actualizada.
* **Control a Través del Diálogo**: Se han añadido tres nuevos comandos para manipular el tiempo directamente desde el JSON de diálogo:
    * `set_time_absolute`: Establece un valor de tiempo inicial.
    * `modify_time`: Suma o resta tiempo al contador actual.
    * `show_time_ui`: Muestra u oculta el temporizador en la interfaz de usuario.
* **Formato de Visualización**: El temporizador se muestra en la UI con el formato `HH:MM:SS`, proporcionando una visualización clara y personalizada para el jugador.

### Correcciones y Mejoras en la Arquitectura de Transiciones

Se han solucionado varios problemas críticos relacionados con la carga de escenas y la visualización de elementos, mejorando la estabilidad y la experiencia de usuario.

* **Sincronización de Voces y Transiciones**: Se resolvió una "condición de carrera" que causaba que las voces comenzaran a sonar durante las transiciones de escena. La lógica de avance de diálogo ahora está contextualizada, permitiendo que los comandos se comporten de manera diferente durante la carga de una escena para evitar este error.
* **Corrección de la Interfaz y Carga de Sprites**: Se solucionó un problema que requería clics adicionales para avanzar en el diálogo y que a veces impedía la carga correcta de los sprites de personajes en nuevas escenas. El sistema ahora gestiona el avance de manera más inteligente, evitando interrupciones en el flujo narrativo.
* **Desaparición del "Fantasma" del Personaje**: Se eliminó un error que hacía que el sprite de un personaje de la escena anterior apareciera brevemente. La visibilidad de los sprites ahora es gestionada exclusivamente por los comandos de diálogo, asegurando que solo se muestren cuando corresponda.
* **Unificación del Control de Visibilidad**: Se corrigió un conflicto de visibilidad entre la propiedad `visible` del nodo y la transparencia (`modulate.a`). Ahora, la función `show_sprite` en `character_sprite.gd` unifica el control, asegurando que los sprites aparezcan correctamente y evitando que queden invisibles por un error de lógica.


---

## ✨ Nuevas Características y Mejoras (v0.0.4) 29-07-2025

Esta versión se centra en la **refactorización de la arquitectura central** del juego para mejorar la **escalabilidad y el mantenimiento**, además de pulir el **sistema de diálogo y la visualización de personajes** con mayor precisión.

### Refactorización Mayor para Escalabilidad

Se ha implementado una **modularización profunda del código**, abordando el problema de un `main_scene.gd` sobrecargado. Las responsabilidades se han dividido en scripts especializados:

* **`CommandProcessor.gd` (Centralizado)**: Ahora actúa como el **ejecutor principal de comandos de diálogo**. Interpreta las líneas del JSON, disparando acciones (cambios de escena, música, fondos, ítems) y, crucialmente, gestiona la lógica de **visibilidad y expresión de personajes** y la presentación del texto.
* **`DialogUI.gd` (Enfocado en UI)**: Se dedica exclusivamente a la **presentación visual del diálogo**. Muestra el texto animado, las opciones de diálogo y los nombres de los oradores, liberándose de la lógica interna de procesamiento.
* **`GameManager.gd` (Coordinador de Alto Nivel)**: Reforzado para centralizar solicitudes clave como la carga de escenas y la gestión del estado general del juego.
* **`main_scene.gd` (Simplificado)**: Transforma su rol a un **controlador**, encargándose de instanciar y conectar los módulos, así como de escuchar sus señales para actualizar la vista global (fondos, UI principal) y gestionar inputs generales.

### Mejoras en el Sistema de Diálogo y Personajes

Se han aplicado optimizaciones significativas para un control más preciso y una experiencia de diálogo más coherente:

* **Gestión Robusta de Tipos (`Enum` y Ternario)**:
    * **Compatibilidad del Operador Ternario**: Se eliminó el error `INCOMPATIBLE_TERNARY` en `main_scene.gd` mediante un **cast explícito a `int()`** en la asignación de `dialog_index`, asegurando que los tipos de datos sean compatibles.
    * **Manejo de Valores `Enum`**: Se resolvió la advertencia `INT_AS_ENUM_WITHOUT_CAST` en `command_processor.gd` mediante un **cast explícito `as Character.Name`** al convertir nombres de `string` a `enum`, garantizando una correcta interpretación del tipo.
* **Control Inteligente de Visibilidad de Personajes**:
    * La lógica centralizada en `_handle_show_character()` y `_handle_text()` (dentro de `CommandProcessor.gd`) ahora gestiona la visibilidad con precisión:
        * Si el **Narrador** es el orador, cualquier personaje visible en pantalla se **oculta automáticamente** con una transición de desvanecimiento suave (`fade-out`).
        * Si un personaje **con sprites** habla, se **muestra** con una transición de aparición (`fade-in`) y se actualiza su expresión.
        * Si un personaje **sin sprites** (ej. "IA") habla, el personaje que estaba visible **permanece en pantalla**, evitando interrupciones visuales.
    * Las **opciones de diálogo** ahora también activan el ocultamiento del personaje, manteniendo la interfaz despejada durante la toma de decisiones del jugador.

### Nuevos Activos Visuales

Para enriquecer la narrativa y la inmersión, se han integrado nuevos recursos:

* **Nuevas Imágenes para Todos los Personajes de la Tripulación**: Sprites actualizados y variados para cada miembro del equipo.
* **Nuevas Expresiones para Diálogo**: Se han añadido más expresiones faciales/corporales para los personajes, permitiendo una mayor riqueza emocional y dinamismo en las conversaciones.
* **Incorporación de CG (Computer Graphics)**: Integración de gráficos de computadora para escenas específicas, fondos detallados o momentos clave de la historia.

---

## ✨ Nuevas Características y Mejoras (v0.0.3) 24-07-2025

Esta versión integra todas las funcionalidades y mejoras previas con importantes optimizaciones en las transiciones y el flujo de diálogo:

* **Mejoras Visuales y de Personajes**:
    * **Nuevas Expresiones:** Se han añadido nuevas expresiones para los personajes, enriqueciendo sus reacciones y emociones durante el diálogo.
    * **Correcciones en Transiciones Visuales:** Se han pulido las transiciones visuales de los personajes y los fondos de escena, asegurando que los cambios de sprites y texturas sean suaves y sin artefactos, contribuyendo a una experiencia más inmersiva.

* **Sistema de Inventario Mejorado**:
    * **Apilamiento de Ítems:** Al recoger un ítem que ya tienes en el inventario, ahora se sumará la cantidad al ítem existente en lugar de duplicarlo como una entrada separada.
    * **Notificaciones de Adquisición Detalladas:** Las notificaciones al adquirir un ítem son más informativas, diferenciando si es un ítem nuevo o si se ha aumentado la cantidad de uno existente.
    * *Funcionalidades Preexistentes*: Conserva la capacidad de abrir y cerrar el panel de inventario, la gestión de ítems mediante un `InventoryManager` centralizado, el manejo de cantidades, la integración para agregar ítems a través de elecciones o líneas de diálogo, la notificación visual temporal al adquirir ítems y la pausa/reanudación del juego al abrir/cerrar el inventario.

* **Transiciones de Escena Perfectas**:
    * **Flujo Optimizado:** La transición entre escenas es ahora completamente fluida. La pantalla se oscurece por completo, la nueva escena carga todo su contenido (fondos, música) mientras está invisible, y solo entonces se revela. Esto elimina cualquier parpadeo o vista momentánea de la escena anterior.
    * **Carga Inteligente de Contenido Inicial:** El sistema busca y carga proactivamente el fondo (`location`) y la música (`music`) de la nueva escena en el momento preciso (cuando la pantalla está negra), asegurando que los elementos visuales y auditivos estén listos antes de que la escena sea visible.
    * **Inicio de Juego Coherente:** El juego ahora utiliza el mismo sistema de transición fluida desde el inicio, garantizando una primera impresión profesional.

* **Sistema de Diálogo con Narrador**:
    * **Líneas Narrativas Puras:** Es posible incluir líneas de diálogo sin un personaje específico. Usando `"speaker": "Narrator"` en el JSON, el texto aparece en la caja de diálogo principal y la caja del orador se oculta automáticamente.
    * **Manejo Robusto de `speaker`:** El sistema de diálogo ahora puede manejar tanto los `enum` de `Character.Name` como `Strings` personalizados ("Narrator") para definir el orador.

* **Manejo de Input y Pausa del Juego Refinado**:
    * **Bloqueo de Input por UI:** Se ha implementado un sistema más robusto para bloquear los inputs del juego subyacente cuando una interfaz de usuario (como el inventario) está activa, evitando clics accidentales o avances involuntarios del diálogo.
    * **Solución a Problemas de Cierre de UI:** Se resolvieron problemas donde los clics en los botones de cerrar de la interfaz de usuario no eran registrados, dando prioridad a los botones de la UI activa.
    * **Optimización de `_input`:** La lógica de `main_scene._input` ha sido simplificada para ignorar selectivamente la acción `next_line` cuando el diálogo está bloqueado, permitiendo que otros inputs de la UI superpuesta se procesen correctamente.
    * *Manejo de Entrada Global Preexistente*: El sistema robusto para escuchar entradas clave (como la tecla de inventario) incluso cuando el juego está pausado, utilizando un manejador de entrada global, se mantiene y se integra con estas mejoras.

---

* **Añadidos dos nuevos archivos:**:
    * Tutorial Creando Archivos JSON.md
    * Novedades técnicas.md

---

## ✨ Nuevas Características y Mejoras (v0.0.2 Alpha) 20-07-2025

Esta versión introduce mejoras significativas en la interactividad y la gestión de ítems:

* **Sistema de Inventario Básico**:
    * Implementada la funcionalidad para abrir y cerrar un panel de inventario.
    * Gestión de ítems mediante un `InventoryManager` centralizado.
    * Manejo de cantidades de ítems al añadirlos al inventario.
    * Integración para agregar ítems a través de elecciones de diálogo.
    * Integración para agregar ítems directamente desde líneas de diálogo.
    * Mecanismo de notificación visual temporal al adquirir nuevos ítems (soporte para múltiples ítems en secuencia).
    * Posibilidad de abrir y cerrar el inventario usando la tecla 'I'.
    * Pausa automática del juego al abrir el inventario y reanudación al cerrarlo.
* **Manejo de Entrada Global**: Implementado un sistema robusto para escuchar entradas clave (como la tecla de inventario) incluso cuando el juego está pausado, utilizando un manejador de entrada global.

---

## 🚀 Mecánicas Implementadas (v0.0.1 Alpha) 17-07-2025

En esta versión alpha inicial, las siguientes mecánicas clave ya están funcionales:

* **Cambios de Escena:** El juego puede navegar fluidamente entre diferentes ubicaciones o momentos de la historia, presentando nuevos fondos y ambientes.
* **Definición de Expresiones de Personajes:** Los personajes pueden mostrar una variedad de emociones y estados de ánimo a través de sus expresiones faciales, enriqueciendo el diálogo y la inmersión.
* **Música de Fondo (BGM):** Las escenas están acompañadas por música, lo que ayuda a establecer el tono y la atmósfera emocional del momento.
* **Efectos de Sonido (SFX):** Se utilizan efectos de sonido para resaltar acciones, eventos o momentos importantes en la narrativa.
* **Transiciones:** La narrativa fluye suavemente entre escenas y diálogos gracias a transiciones visuales, como fundidos a negro o cortes limpios.
* **Pantalla de Inicio:** El juego cuenta con una pantalla de inicio básica que ofrece al jugador las opciones para **Iniciar Juego** o **Salir del Juego**.

---

## 📋 Próximos Pasos (TODO)

El desarrollo del juego continúa, y la siguiente lista representa las principales características y contenidos que planeamos implementar:

* [ ] Sistema de Inventario: (Aunque las bases están, aún quedan mejoras por hacer como la visualización detallada de ítems, el uso/equipamiento, etc. - si aplica)
* [ ] Sistema de Tiempo: Implementar un sistema de progresión temporal que pueda afectar eventos, disponibilidad de personajes o decisiones.
* [ ] Añadir Sprites de Expresiones Básicas: Integrar los recursos visuales (sprites) para las expresiones fundamentales de los personajes, haciendo que la narrativa sea más dinámica y expresiva.
* [ ] Historia del Primer Capítulo: Escribir e implementar la narrativa completa del primer capítulo, incluyendo diálogos, eventos y ramificaciones iniciales.

---

## 🛠️ Cómo Iniciar el Proyecto

1.  **Clonar el Repositorio:**
    ```bash
    git clone [https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD-0.0.1.git](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD-0.0.1.git)
    ```
2.  **Abrir con Godot Engine:**
    * Abre Godot Engine (versión 4.4.1 o superior).
    * Haz clic en "Importar" y selecciona el archivo `project.godot` dentro de la carpeta que acabas de clonar.
    * El proyecto debería aparecer en tu lista. Haz clic en "Editar" para abrirlo.

---

## 🤝 Contribución

Actualmente, el proyecto está en una fase temprana de desarrollo individual. Si estás interesado en contribuir en el futuro, por favor, contacta con el dueño del repositorio.

---

## 📄 Licencia

Copyright (c) 2025 FedeiaTech. Todos los derechos reservados.