# Noche en la Pizzería — fan game gratuito

Prototipo de fan game inspirado en Five Nights at Freddy's, hecho con Godot 4 para **Android en horizontal**. No tiene controles ni flujo para PC. Es una obra de fans no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Qué incluye en esta etapa

- Exploración libre en primera persona por una pizzería ampliada: comedor, escenario, cocina, zona de preparación, máquinas recreativas y pasillo/cuarto de servicio.
- Android horizontal, pantalla inmersiva completa y joystick táctil. El stick permanece capturado mientras lo arrastras; un segundo dedo en la zona derecha gira la cámara a la vez. Los dedos extra no desactivan el stick.
- Perseguidor **The Mimic DLC** con clips Idle, Walk, Run y jumpscare incluidos en el GLB.
- Luces cálidas, LED emisivos, materiales PBR con mapas normales, mipmaps y glow moderado, equilibrados para móvil.
- Ambiente en loop y pasos cortos, evitando reinicios de efectos que corten el audio.

## Assets y créditos

- The Mimic DLC, de [SpiderBight (ArachnoBoy / vang807)](https://sketchfab.com/3d-models/the-mimic-dlc-1dbe9b38ad8b47cc880b63d493b20884), obtenido del enlace de MediaFire proporcionado. La ficha de Sketchfab indica licencia **CC BY-NC 4.0**: requiere atribución y solo permite uso no comercial. Este fan game es gratuito y no comercial; no se debe vender, monetizar ni usar en publicidad con este modelo.
- Piso: [Tiles 012 de ambientCG](https://ambientcg.com/view?id=Tiles012), material PBR CC0. Las texturas de pared y madera llevan mapas normales propios.
- Audio: Mixkit Horror ambience (ID 2482) y efectos de pasos (IDs 1920 y 1417), bajo la [licencia de efectos de Mixkit](https://mixkit.co/license/#sfxFree).
- Fan game no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Construir APK

GitHub Actions ejecuta el workflow `.github/workflows/android-apk.yml` al subir cambios a `main`, o manualmente desde Actions. Produce un APK debug arm64 descargable como artefacto. Es de depuración, no para Play Store.

El proyecto está configurado a pantalla completa e inmersiva en orientación paisaje. Los controles principales son táctiles; no hace falta teclado ni ratón. Debe probarse en el teléfono: un build exitoso por sí solo no valida gestos, rendimiento ni apariencia.
