# Última Ronda

Juego arcade 2D de supervivencia zombi en arena cenital, creado con Godot. Sobrevive oleadas cada vez más intensas, gana puntos al eliminar zombis y compra mejoras entre rondas.

## Ejecutar el juego

1. Instala Godot 4.x (usa una versión compatible con el proyecto y sus plantillas de exportación).
2. Abre `project.godot` desde el Project Manager de Godot.
3. Ejecuta el proyecto con **F6/F5** o el botón de reproducir.

El directorio `site/` contiene la exportación web incluida con esta entrega. Para servirla localmente, desde la raíz del proyecto ejecuta `python3 -m http.server 8000 --directory site` y abre `http://localhost:8000`.

## Controles

- **Moverte:** WASD o flechas.
- **Apuntar:** ratón.
- **Disparar:** clic izquierdo o Espacio.
- **Pausar/reanudar:** Esc o P.
- **Comprar mejora:** 1, 2 o 3 durante la tienda entre rondas.
- **Continuar sin comprar:** Enter.
- **Reintentar tras la derrota:** R o Enter.
- **Volver al menú desde pausa:** M.

## Estructura

- `scenes/`, `scripts/`, `autoload/`: escenas y lógica principal en GDScript.
- `assets/`: sprites, fondos, sonidos, fuentes y sus licencias/import sidecars; están incluidos y deben conservarse en Git.
- `web/` y `localization/`: cargador HTML y datos de localización.
- `server/`: backend opcional para el inicio de sesión Manus, con migración y lockfile de npm.
- `site/`: build web exportado listo para servir como estático.
- `test/`: pruebas del juego y contratos.

## Pruebas y exportación

Se necesita Node.js y Godot instalado en PATH para ejecutar las pruebas: `npm test`. Para exportar desde Godot, instala también las plantillas de exportación correspondientes y usa el preset `Web` en Project → Export. `npm run export` es un atajo para exportar a `dist/`.

Algunos comandos heredados del entorno Manus (`npm run check`, `npm run dev`, `npm run build` y `npm run preview:*`) usan un runtime de desarrollo proporcionado por la plataforma Manus y no forman parte de este ZIP. El proyecto base y la partida como invitado sí se pueden ejecutar localmente con Godot.

## Inicio de sesión

El inicio de sesión Manus es opcional para jugar. El backend de `server/` depende de servicios de Manus y requiere configuración de entorno y base de datos compatible. Fuera de Manus no arrancará sin un proveedor/entorno equivalente. No subas secretos reales, credenciales, archivos `.env` ni valores privados a GitHub.

## Licencias

Conserva los avisos de `site/THIRD_PARTY_NOTICES.txt`, los archivos de licencia junto a las fuentes y `docs/provenance/`.
