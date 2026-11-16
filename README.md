# Noche en la Pizzería — fan game gratuito

Prototipo de fan game inspirado en Five Nights at Freddy's, hecho con Godot 4 para **Android en horizontal**. No tiene controles ni flujo para PC. Es una obra de fans no oficial; FNAF y sus personajes pertenecen a sus titulares.

## Qué incluye en esta etapa

- Exploración libre en primera persona por un comedor de pizzería, en Android horizontal y a pantalla completa.
- Joystick táctil para caminar, arrastre en el lado derecho para mirar, botón de linterna y botón de correr.
- Un animatrónico provisional te persigue por el comedor; su velocidad sube gradualmente, y hay pisadas que se oyen más al acercarse.
- Ambiente oscuro, mostrador, escenario, mesas y luces cálidas; recursos geométricos ligeros para priorizar rendimiento en móvil.
- El animatrónico visible es un placeholder hecho con primitivas, **no es todavía el modelo final de Freddy**.

## Sonidos y licencia

Se añadieron tres efectos descargados de Mixkit: ambiente de terror (ID 2482, 1:22), pasos (ID 542) y pisada/impacto grave (ID 3046). Mixkit los publica bajo su licencia gratuita de efectos; consulta la [licencia de Mixkit](https://mixkit.co/license/#sfxFree). Se incluyen como MP3 compactos para el APK móvil. Catálogos consultados: [ambiente de terror](https://mixkit.co/free-sound-effects/horror/) y [pasos](https://mixkit.co/free-sound-effects/footsteps/).

## Modelo de Freddy y licencia

Encontré [FNaF 1 Freddy Fazbear Rigged, de ShadowSupreme en Sketchfab](https://sketchfab.com/3d-models/fnaf-1-freddy-fazbear-rigged-eddb20dca006466c811c6bfd9b8a8e83). La ficha lo describe como riggeado y muestra licencia Free Standard; el autor solicita crédito y prohíbe atribuirlo a otra persona, hacer recolores o redistribuir su archivo. También informa que tiene 74,5 mil triángulos y texturas 4K, por lo que requiere optimización antes de usarlo en móvil.

La API oficial de descarga exige autenticación y desde este entorno no fue posible bajar el archivo del creador. Por eso no lo incluí ni afirmo que ya esté en el juego. El placeholder se deja explícito en el código y se reemplaza cuando se tenga el archivo original descargado y optimizado con atribución. La página también enlaza un [Freddy animado de FusedMaker](https://sketchfab.com/3d-models/animated-freddy-1229722b704a4b17b2ea956783623297), con CC BY; verificar su contenido y optimizarlo antes de integrarlo.

## Construir APK

GitHub Actions ejecuta el workflow `.github/workflows/android-apk.yml` al subir cambios a `main`, o manualmente desde Actions. Produce un APK debug arm64 descargable como artefacto. Es de depuración, no para Play Store.

El proyecto está configurado en orientación paisaje. Los controles principales son táctiles; no hace falta teclado ni ratón. Debe probarse en el teléfono: un build exitoso por sí solo no valida gestos, rendimiento ni apariencia.
