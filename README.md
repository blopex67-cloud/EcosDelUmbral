# Noche en la Pizzería — fan game gratuito

Prototipo de fan game inspirado en Five Nights at Freddy's, hecho con Godot 4 para **Android en horizontal**. No tiene controles ni flujo para PC. Es una obra de fans no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Qué incluye en esta etapa

- Lobby de entrada y pizzería móvil en horizontal a pantalla completa.
- Distribución por zonas: comedor central, escenario, cocina, pasillo oeste de servicio y ala este con cruces y puertas metálicas. Incluye tuberías, luces prácticas y rutas amplias entre filas de mesas.
- Mesas y sillas 3D realistas de Poly Haven, descargadas en GLTF 1K y usadas bajo CC0. Decoración de fiesta y máscaras de mascotas genéricas hechas para el juego; sin logos ni modelos de personajes de FNAF.
- Filtro de cámara CCTV opcional: escala de grises verdosa, scanlines, grano, leve separación de color y viñeta; se activa/desactiva desde el HUD.
- The Mimic de SpiderBight con shader PBR de acabado más suave y sus animaciones Idle, Walk, Run y jumpscare. Pisadas espaciales sincronizadas a los ciclos de animación.
- Click de linterna, ambiente en loop, transiciones de terror, gruñidos distantes, risa de criatura y la frase infantil “hiya” como saludo juguetón del juguete. Son efectos licenciados de biblioteca; no se presentan como audio oficial de Toy.

## Assets y licencias

- The Mimic DLC: modelo de SpiderBight (ArachnoBoy / vang807), [Sketchfab](https://sketchfab.com/3d-models/the-mimic-dlc-1dbe9b38ad8b47cc880b63d493b20884), licencia CC BY-NC 4.0. Requiere crédito y permite solo uso no comercial. Este fan game debe mantenerse gratuito y no comercial mientras se incluya.
- Pared Plaster001 y madera WoodFloor010 de ambientCG, CC0 1.0; piso ajedrezado generado para este proyecto.
- Mesa Dining Table de Aron Łyczek y Dining Chair 02 de Poly Haven, CC0 1.0. Créditos y vínculos en `assets/models/props/CREDITS.txt`.
- Efectos de Mixkit bajo su [Free SFX License](https://mixkit.co/license/#sfxFree). Los IDs y atribuciones están en `assets/models/THE_MIMIC_ATTRIBUTION.txt` y `assets/audio/SOUND_CREDITS.txt`.
- Fan game no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Prueba y exportación sin builds innecesarios

Los cambios ejecutan `Godot project tests` automáticamente: importa recursos y hace un smoke test de la escena, verifica carga de muebles CC0 y filtro CCTV, sin crear APK. Después de revisar el ZIP/proyecto y dar aprobación, se lanza manualmente `Export Android APK (manual after visual approval)`. Pasos completos: [TEST_AND_APK_FLOW.md](TEST_AND_APK_FLOW.md).

## Flujo de revisión y APK

Cada push ejecuta únicamente `.github/workflows/godot-test.yml`: importa recursos, arranca la escena y publica un ZIP de revisión del proyecto. **No genera APK.** El empaquetado del APK está aislado en `.github/workflows/android-apk.yml`, con `workflow_dispatch` solamente; debe activarse después de que Chapio apruebe explícitamente la versión visual. Produce un APK debug arm64, no apto para Play Store.

El proyecto está configurado a pantalla completa e inmersiva en orientación paisaje. Los controles principales son táctiles; no hace falta teclado ni ratón. Debe probarse en el teléfono: un build exitoso por sí solo no valida gestos, rendimiento ni apariencia.
