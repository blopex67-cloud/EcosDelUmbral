# Flujo de prueba y APK

1. Cada cambio subido a GitHub inicia `Godot project tests`: importa recursos y arranca la escena principal en Godot 4.3. Este flujo **no exporta ni entrega un APK**.
2. Se revisa la versión en el proyecto ZIP o en el editor de Godot y Chapio confirma si le gusta.
3. Solo después de su aprobación explícita se ejecuta manualmente `Export Android APK (manual after visual approval)` desde GitHub Actions. Ese flujo hace la prueba de escena antes de exportar el APK debug y adjuntar el artefacto de Godot/Android.

La prueba automática valida importación y arranque en headless; no sustituye la comprobación visual, táctil ni de rendimiento en el teléfono.
