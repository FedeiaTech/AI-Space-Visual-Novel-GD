# AI Space Visual Novel - Versión 0.0.9 Alpha

¡Bienvenido al repositorio de **AI Space Visual Novel**! Este proyecto es un juego de novela visual en desarrollo, creado con Godot Engine, que te sumergirá en una narrativa interactiva con elementos de ciencia ficción.

## Links
* [Mejoras Técnicas](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Novedades%20tecnicas.md)
* [Tutorial de archivos JSON](https://github.com/FedeiaTech/AI-Space-Visual-Novel-GD/blob/main/Tutorial%20Archivos%20JSON.md)

---
**v0.0.9 (01-11-2025):**
* **Optimización Profunda del Motor:** Se realizó una reestructuración masiva de la arquitectura interna para mejorar la estabilidad, el rendimiento y facilitar la implementación de futuras mecánicas.
* **Mejoras de Rendimiento Clave:** Los saltos entre diálogos (`goto`) y la carga de objetos interactivos en las escenas ahora son instantáneos, eliminando tiempos de carga.
* **Nuevas Mecánicas de Diálogo:**
    * Implementación del efecto de **temblor de pantalla** (`shake`).
    * Implementación de **desplazamiento de personajes** (`move_character`) para crear escenas más dinámicas.
* **Sistema de Sonido de Voz Mejorado:** El sonido "blip" del diálogo ahora varía según el género del personaje (masculino, femenino) e incluye sonidos únicos para expresiones específicas (como susto o duda).
* **Gestión de Ítems Centralizada:** Se implementó una base de datos de ítems para asegurar la consistencia de los objetos, sus nombres y descripciones en todo el juego.
* **Herramientas de Desarrollo:** Se añadió un **"Modo de Depuración"** secreto accesible desde el menú principal, que carga un escenario de pruebas para testear todas las funciones del juego sin afectar la historia principal.

**v0.0.8 (10-09-2025):**
* Se implementó la carga de **Imágenes CGs** en diálogo con transiciones personalizables.
* Se añadió el **modo de exploración** para ocultar la UI de diálogo y permitir interacciones con el entorno.
* Se mejoró la **retroalimentación visual** de objetos clickeables con efectos de brillo (`hover`/`pressed`).
* Nuevo **Menú de Pausa** funcional que congela el juego.
* Correcciones en el control de transiciones de escena y errores de selección de botones.

**v0.0.7 (23-08-2025):**
* Transformación de escenarios a **entornos interactivos explorables** con objetos clickeables.
* Implementación de un sistema robusto de eventos para **narrativa no lineal** (saltos internos y externos).
* Consolidación de la arquitectura con **Autoloads** (`SceneLibrary`, `StoryLibrary`) para estabilidad en la exportación.

**v0.0.6 (16-08-2025):**
* **Renovación completa de la UI** y aumento de la resolución a **1280x720p**.
* Menús Principal y de Opciones reestructurados y coexistentes para navegación fluida.
* Implementación de **controles de volumen** personalizables y **configuración de resolución** en tiempo real.
* Nuevo sistema de **Diario de Diálogos Global** (`JournalManager`) para registrar automáticamente las líneas.
* Correcciones críticas en el flujo de comandos para evitar que el juego se "atasque".

**v0.0.5 (08-08-2025):**
* Implementación de **Diálogos Condicionales** (basados en ítems) y **Sistema de Banderas de Misión** (`set_flag`).
* Nuevo **Sistema de Tiempo Regresivo** gestionado por un Autoload (`TimeManager`).
* Corrección de una "condición de carrera" que causaba que las voces sonaran durante las transiciones.
* Corrección del "fantasma" del personaje y unificación del control de visibilidad de sprites.

**v0.0.4 (29-07-2025):**
* **Refactorización mayor de la arquitectura central** para mejorar la escalabilidad (división en `CommandProcessor`, `DialogUI`, `GameManager`).
* Mejora en la **gestión de tipos** y el **control inteligente de visibilidad de personajes**.
* Incorporación de **nuevos assets visuales** para personajes y CGs.

**v0.0.3 (24-07-2025):**
* **Transiciones de Escena Perfectas** (pantalla en negro) para eliminar parpadeos.
* **Sistema de Inventario Mejorado** (apilamiento y notificaciones).
* Soporte para **Diálogo con Narrador** (`"speaker": "Narrator"`) para ocultar la caja del orador.
* Manejo refinado de la entrada y pausa del juego.

**v0.0.2 (20-07-2025):**
* Implementación del **Sistema de Inventario Básico** (panel, `InventoryManager`, pausa automática).
* Sistema robusto de **manejo de entrada global** para escuchar teclas incluso en pausa.

**v0.0.1 Alpha (17-07-2025):**
* Mecánicas base funcionales: Cambios de Escena, Expresiones de Personajes, BGM/SFX, Transiciones y Pantalla de Inicio.

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