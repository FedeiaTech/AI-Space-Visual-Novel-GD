# AI Space Visual Novel - Versión 0.0.2 Alpha

¡Bienvenido al repositorio de **AI Space Visual Novel**! Este proyecto es un juego de novela visual en desarrollo, creado con Godot Engine, que te sumergirá en una narrativa interactiva con elementos de ciencia ficción.

---
## ✨ Nuevas Características y Mejoras (v0.0.2 Alpha)

Esta versión introduce mejoras significativas en la interactividad y la gestión de ítems:

* **Sistema de Inventario Básico**:
    * Implementada la funcionalidad para abrir y cerrar un panel de inventario.
    * Gestión de ítems mediante un `InventoryManager` centralizado.
    * Manejo de cantidades de ítems al añadirlos al inventario.
    * Integración para agregar ítems a través de elecciones de diálogo.
    * Integración para agregar ítems directamente desde líneas de diálogo (sin opciones).
    * Mecanismo de notificación visual temporal al adquirir nuevos ítems (con soporte para múltiples ítems en secuencia).
    * Posibilidad de abrir y cerrar el inventario usando la tecla 'I' (o la acción configurada).
    * Pausa automática del juego al abrir el inventario y reanudación al cerrarlo.
* **Manejo de Entrada Global**: Implementado un sistema robusto para escuchar entradas clave (como la tecla de inventario) incluso cuando el juego está pausado, utilizando un manejador de entrada global.

---

## 🚀 Mecánicas Implementadas (v0.0.1 Alpha)

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