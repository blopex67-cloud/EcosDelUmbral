# Ecos del Umbral

Prototipo gratuito de exploración 3D en Godot 4, como base original para móvil y PC. **No es todavía un fan game de una saga concreta**: no se indicó cuál, así que evita personajes, marcas o material protegido.

## Estado
- Escena 3D ejecutable con terreno, bosque procedural sencillo, punto de luz y sombras direccionales.
- Movimiento de teclado y controles táctiles básicos (lado izquierdo: movimiento; arrastre derecho: mirar).
- Ambiente sonoro breve generado específicamente para este prototipo.
- El bosque y el jugador son formas provisionales; no hay modelos descargados, enemigos, historia, partículas ni APK validado todavía.

## Abrir
Abrir `project.godot` en Godot 4.3 o posterior y ejecutar la escena principal. Renderer **GL Compatibility** como punto de partida para Android/equipos modestos. Esto prioriza compatibilidad/rendimiento, no equivale a iluminación físicamente realista de gama alta.

## Recursos y licencias
- `assets/audio/ambience.wav` es un ambiente sintetizado original.
- Se puede reemplazar el bosque con [Stylized Nature MegaKit de Quaternius](https://quaternius.com/packs/stylizednaturemegakit.html). La ficha indica modelos texturizados, archivos glTF y licencia CC0; parte del pack es gratuita y la implementación completa para Godot corresponde a la versión Source. Añade solo los archivos descargados legítimamente y conserva la licencia con los recursos.
- Los modelos actuales se generan con primitivas de Godot; no se redistribuyen packs de terceros.

## Optimización planteada
Primitivas y materiales sencillos, renderer compatible y sombras limitadas a la luz principal. Antes de aumentar calidad, probar FPS, memoria, tamaño de APK y temperatura en el teléfono objetivo. Vegetación densa, postprocesado y modelos complejos se añadirán de forma escalable. **No está probado en Android**.

## Siguiente etapa
Elegir la saga si se quiere que sea un fan game (y revisar sus reglas), integrar assets CC0/compatibles, añadir interacción/objetivo y completar controles móviles; luego automatizar APK y probarlo en el teléfono.
