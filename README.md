# Noche en la Pizzería — fan game gratuito

Prototipo de fan game inspirado en Five Nights at Freddy's, hecho con Godot 4 para **Android en horizontal**. No tiene controles ni flujo para PC. Es una obra de fans no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Qué incluye en esta etapa

- Lobby de entrada y pizzería móvil en horizontal a pantalla completa.
- Recorrido por comedor, escenario, cocina y pasillo de servicio, con baldosa ajedrezada, mesas con manteles, sillas, decoración de fiesta y pared envejecida.
- The Mimic de SpiderBight con shader PBR de acabado más suave y sus animaciones Idle, Walk, Run y jumpscare. Pisadas espaciales sincronizadas a los ciclos de animación.
- Click de linterna, ambiente en loop, transiciones de terror, gruñidos distantes, risa de criatura y una voz infantil que dice “hiya” como saludo juguetón del juguete. No se presenta como audio oficial de Toy.

## Assets y licencias

- The Mimic DLC: modelo de SpiderBight (ArachnoBoy / vang807), [Sketchfab](https://sketchfab.com/3d-models/the-mimic-dlc-1dbe9b38ad8b47cc880b63d493b20884), licencia CC BY-NC 4.0. Requiere crédito y permite solo uso no comercial. Este fan game debe mantenerse gratuito y no comercial mientras se incluya.
- Pared Plaster001 y madera WoodFloor010 de ambientCG, CC0 1.0; piso ajedrezado generado para este proyecto.
- Efectos de Mixkit bajo su [Free SFX License](https://mixkit.co/license/#sfxFree). Los IDs y atribuciones están en `assets/models/THE_MIMIC_ATTRIBUTION.txt` y `assets/audio/SOUND_CREDITS.txt`.
- Fan game no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Construir APK

GitHub Actions ejecuta el workflow `.github/workflows/android-apk.yml` al subir cambios a `main`, o manualmente desde Actions. Produce un APK debug arm64 descargable como artefacto. Es de depuración, no para Play Store.

El proyecto está configurado a pantalla completa e inmersiva en orientación paisaje. Los controles principales son táctiles; no hace falta teclado ni ratón. Debe probarse en el teléfono: un build exitoso por sí solo no valida gestos, rendimiento ni apariencia.
