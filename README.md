# Noche en la Pizzería — fan game gratuito

Prototipo de fan game inspirado en Five Nights at Freddy's, hecho con Godot 4 para **Android en horizontal**. No tiene controles ni flujo para PC. Es una obra de fans no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Qué incluye en esta etapa

- Exploración libre en primera persona por el comedor, pensada para Android en horizontal y a pantalla completa.
- Joystick táctil para caminar, arrastre para mirar, linterna y botón para correr.
- Un perseguidor 3D riggeado con clips Run/Sprint; acelera con el tiempo y sus pasos se oyen desde su ubicación.
- Iluminación cálida más tiras LED emisivas rojas, cian, moradas y verdes; superficies de piso, pared y madera con mapas normales PBR y filtrado mipmap.
- Efectos de ambiente en loop, pasos del jugador y pisadas del perseguidor, ajustados para no superponerse/reiniciarse antes de terminar.

## Assets y créditos

- Personaje: [3D Godot Robot Character, de CaptainRipley/Ariana Chow](https://captainripley.itch.io/godot-3d-robot-character), archivo GLB de 1.3 MB con 20 animaciones, publicado en el [repositorio original](https://github.com/AGChow/3D-Godot-Robot-Platformer-Character). Su licencia incluida es **CC0 1.0**. Es un robot genérico adaptado visualmente a animatrónico provisional; **no es Freddy ni un oso**, y los clips se usan para correr.
- Piso: [Tiles 012 de ambientCG](https://ambientcg.com/view?id=Tiles012), material PBR CC0 reducido a JPG 1K. Pared y madera son texturas 1K locales optimizadas, con mapas normales generados para el prototipo.
- Audio: [Mixkit Horror ambience](https://mixkit.co/free-sound-effects/horror/) (ID 2482), efectos cortos para pasos/robot (ID 1920 e ID 1417), bajo la licencia de efectos de [Mixkit](https://mixkit.co/license/#sfxFree).

## Freddy

El Freddy final todavía no está integrado. Encontré modelos de oso con licencia CC BY, pero Sketchfab exige autenticación para la descarga en este entorno. No he sustituido el personaje por un modelo no descargado ni afirmo que el robot genérico sea Freddy.

## Construir APK

GitHub Actions ejecuta el workflow `.github/workflows/android-apk.yml` al subir cambios a `main`, o manualmente desde Actions. Produce un APK debug arm64 descargable como artefacto. Es de depuración, no para Play Store.

El proyecto está configurado en orientación paisaje. Los controles principales son táctiles; no hace falta teclado ni ratón. Debe probarse en el teléfono: un build exitoso por sí solo no valida gestos, rendimiento ni apariencia.
