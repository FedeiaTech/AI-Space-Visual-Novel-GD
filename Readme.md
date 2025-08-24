# AI Space Visual Novel - Versión 0.0.7 Alpha

¡Bienvenido al repositorio de **AI Space Visual Novel**! Este proyecto es un juego de novela visual en desarrollo, creado con Godot Engine, que te sumergirá en una narrativa interactiva con elementos de ciencia ficción.

## Links
* [Mejoras Técnicas](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Novedades%20tecnicas.md)
* [Tutorial de archivos JSON](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Tutorial%20Archivos%20JSON.md)

---

## ✨ Nuevas Características y Mejoras (v0.0.7) 23-08-2025

Esta versión transforma la experiencia de juego al pasar de escenarios estáticos a **entornos interactivos explorables**. Se introduce un sistema de **objetos clickeables** que se integra con una arquitectura de eventos robusta, permitiendo una narrativa más dinámica y no lineal.

### Introducción de Escenas Interactivas
Los fondos de pantalla estáticos han sido reemplazados por escenas interactivas. Ahora, cada ubicación puede contener múltiples **objetos clickeables** (`TextureButtons`) que simulan elementos del escenario, permitiendo al jugador explorar el entorno para descubrir detalles, iniciar conversaciones o avanzar en la trama.

### Sistema de Eventos y Narrativa No Lineal
Cada objeto interactivo está conectado al sistema de comandos unificado, lo que permite una narrativa flexible y ramificada:
* **Saltos Internos**: Un objeto puede dirigir al jugador a una parte específica del diálogo actual mediante **anclas (anchors)**, ideal para descripciones o conversaciones secundarias.
* **Saltos Externos**: Un clic puede iniciar una transición completa a una nueva escena, cargando una ubicación visual diferente junto con su propio archivo de diálogo.

### Consolidación de la Arquitectura Robusta
Para garantizar la estabilidad y una exportación sin errores, este sistema no utiliza rutas de texto frágiles. Todas las referencias a escenas y diálogos se gestionan a través de los **Autoloads** (`SceneLibrary` y `StoryLibrary`) que precargan los recursos. Esto asegura que todo el contenido interactivo esté correctamente empaquetado y funcione en la versión final del juego.

---

## ✨ Nuevas Características y Mejoras (v0.0.6) - 16-08-2025

Esta versión se enfoca en una **renovación total de la interfaz de usuario**, incorporando un sistema de menú robusto y flexible. También se han realizado **mejoras críticas en el flujo de juego** y en la **estabilidad del sistema de diario (log)**.

### Renovación de la Interfaz y Controles de Juego

Se ha rediseñado la interfaz de usuario para mejorar la experiencia del jugador, con un enfoque en la personalización y la estabilidad.

* **Aumento de la Resolución de Pantalla**: La interfaz gráfica del juego ha sido redimensionada a **1280x720 píxeles** (720p), lo que permite una mayor calidad visual y más espacio para los elementos de la interfaz.
* **Nuevo Fondo de Título**: Se ha añadido un nuevo fondo visual para la pantalla de título, mejorando la estética del inicio del juego.
* **Menús Principal y de Opciones Reestructurados**: Los menús ahora coexisten en la misma escena. El menú de opciones se muestra u oculta dinámicamente, lo que permite una navegación fluida sin recargar la escena principal.
* **Controles de Volumen Personalizables**: El jugador puede ajustar de forma independiente el volumen de la música (`BGM`), las voces y los efectos de sonido (`SFX`) mediante controles deslizantes.
* **Configuración de Resolución en Tiempo Real**: Se ha implementado un menú desplegable que permite a los jugadores cambiar la resolución del juego sobre la marcha.
* **Alternancia de Pantalla Completa**: Se ha añadido un botón para cambiar entre el modo ventana y pantalla completa.
* **Estabilidad Mejorada**: Se han corregido errores de inicialización y manejo de eventos, asegurando que los menús funcionen de manera estable en las versiones exportadas.

### Sistema de Diario (Log) y Estabilidad

Se ha implementado un sistema de registro de diálogos, junto con mejoras que aseguran su correcto funcionamiento.

* **Diario de Diálogos Global**: Se ha añadido un **Autoload (Singleton)**, `JournalManager.gd`, que registra y almacena automáticamente todas las líneas de diálogo que el jugador ha visto.
* **Registro Automático**: El `CommandProcessor` ahora envía automáticamente cada línea de diálogo con texto al `JournalManager` para su registro.
* **Corrección de Renderizado de Texto**: Se solucionó un problema de compatibilidad con `RichTextLabel` reemplazándolo por el nodo **`Label`**, que garantiza una visualización correcta de las entradas del diario.

### Correcciones Críticas en el Flujo de Juego

Se han resuelto problemas de lógica en el procesamiento de comandos para garantizar un flujo narrativo sin interrupciones.

* **Sincronización de Comandos**: Un bucle de pre-procesamiento central en `main_scene.gd` ahora se encarga de saltar las líneas de configuración, evitando que el juego se quede "atascado".
* **Transiciones Optimizadas**: El manejo de las transiciones de escena y los saltos internos (`goto_internal`) ha sido optimizado para asegurar una carga correcta y una reanudación precisa del diálogo.
* **Depuración Detallada**: Se confirmó que los datos se transmitían correctamente y que el problema de renderizado estaba localizado en la incompatibilidad del nodo de texto.

---

## ✨ Nuevas Características y Mejoras (v0.0.5) - 08-08-2025

Esta versión se centra en la **implementación de sistemas narrativos dinámicos** y en la **optimización de transiciones y gestión de personajes**.

### Sistema de Diálogos Condicionales y Lógica Narrativa

* **Diálogos Condicionales Basados en Ítems**: Las opciones de diálogo ahora pueden requerir un ítem específico en el inventario.
* **Sistema de Banderas de Misión (Quest Flags)**: Se ha implementado un sistema de banderas para rastrear el progreso del jugador, con nuevos comandos en el JSON (como **`set_flag`**) para alterar la historia dinámicamente.
* **Optimización de la Ejecución de Comandos**: Se ha corregido el orden de ejecución para asegurar que los comandos de estado (`set_flag`) se procesen antes que los que dependen de ellos.

### Sistema de Tiempo Regresivo

* **Gestión Centralizada del Tiempo**: Un nuevo **Autoload (Singleton)**, `TimeManager.gd`, gestiona un temporizador que puede ser manipulado desde el diálogo con comandos como `set_time_absolute`, `modify_time` y `show_time_ui`.

### Correcciones y Mejoras en la Arquitectura de Transiciones

* **Sincronización de Voces y Transiciones**: Se resolvió una "condición de carrera" que causaba que las voces sonaran durante las transiciones de escena.
* **Corrección de la Interfaz y Carga de Sprites**: Se solucionó un problema que requería clics adicionales para avanzar y que a veces impedía la carga correcta de sprites.
* **Desaparición del "Fantasma" del Personaje**: Se eliminó un error que hacía que el sprite de una escena anterior apareciera brevemente.
* **Unificación del Control de Visibilidad**: Se corrigió un conflicto de visibilidad, asegurando que los sprites aparezcan correctamente.

---

## ✨ Nuevas Características y Mejoras (v0.0.4) 29-07-2025

Esta versión se centra en la **refactorización de la arquitectura central** para mejorar la **escalabilidad y el mantenimiento**.

### Refactorización Mayor para Escalabilidad
Las responsabilidades se han dividido en scripts especializados:

* **`CommandProcessor.gd` (Centralizado)**: Ejecutor principal de comandos de diálogo.
* **`DialogUI.gd` (Enfocado en UI)**: Se dedica a la presentación visual del diálogo.
* **`GameManager.gd` (Coordinador de Alto Nivel)**: Centraliza solicitudes clave como la carga de escenas.
* **`main_scene.gd` (Simplificado)**: Actúa como controlador que conecta los módulos.

### Mejoras en el Sistema de Diálogo y Personajes
* **Gestión Robusta de Tipos (`Enum` y Ternario)**: Se eliminaron errores y advertencias de incompatibilidad de tipos mediante *casts* explícitos.
* **Control Inteligente de Visibilidad de Personajes**: La lógica ahora gestiona con precisión la aparición y desaparición de personajes según quién hable (Narrador, personaje con o sin sprites).

### Nuevos Activos Visuales
* Nuevas Imágenes para Todos los Personajes de la Tripulación.
* Nuevas Expresiones para Diálogo.
* Incorporación de CG (Computer Graphics) para escenas clave.

---

## ✨ Nuevas Características y Mejoras (v0.0.3) 24-07-2025

Esta versión integra funcionalidades previas con optimizaciones en transiciones y flujo de diálogo:

* **Mejoras Visuales y de Personajes**: Nuevas expresiones y transiciones visuales pulidas.
* **Sistema de Inventario Mejorado**: Apilamiento de ítems y notificaciones de adquisición detalladas.
* **Transiciones de Escena Perfectas**: La carga de escenas se realiza con la pantalla en negro para eliminar parpadeos.
* **Sistema de Diálogo con Narrador**: Posibilidad de usar `"speaker": "Narrator"` en el JSON para ocultar la caja del orador.
* **Manejo de Input y Pausa del Juego Refinado**: Bloqueo de inputs de juego cuando una UI está activa.

---

## ✨ Nuevas Características y Mejoras (v0.0.2 Alpha) 20-07-2025

Esta versión introduce mejoras en la interactividad y la gestión de ítems:

* **Sistema de Inventario Básico**: Apertura/cierre del panel, `InventoryManager` centralizado, manejo de cantidades, notificaciones visuales y pausa automática del juego.
* **Manejo de Entrada Global**: Sistema robusto para escuchar entradas clave incluso cuando el juego está pausado.

---

## 🚀 Mecánicas Implementadas (v0.0.1 Alpha) 17-07-2025

En esta versión alpha inicial, las siguientes mecánicas clave ya están funcionales:

* **Cambios de Escena**
* **Definición de Expresiones de Personajes**
* **Música de Fondo (BGM)**
* **Efectos de Sonido (SFX)**
* **Transiciones**
* **Pantalla de Inicio**

---

## 🛠️ Cómo Iniciar el Proyecto

1.  **Clonar el Repositorio:**
    ```bash
    git clone [https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD-0.0.1.git](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD-0.0.1.git)
    ```
2.  **Abrir con Godot Engine:**
    * Abre Godot Engine (versión 4.4.1 o superior).
    * Haz clic en "Importar" y selecciona el archivo `project.godot` dentro de la carpeta clonada.
    * Haz clic en "Editar" para abrir el proyecto.

---

## 🤝 Contribución

Actualmente, el proyecto está en una fase temprana de desarrollo individual. Si estás interesado en contribuir en el futuro, por favor, contacta con el dueño del repositorio.

---

## 📄 Licencia

Copyright (c) 2025 FedeiaTech. Todos los derechos reservados.