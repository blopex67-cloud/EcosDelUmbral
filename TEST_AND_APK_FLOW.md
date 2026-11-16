# Flujo de test, ZIP de proyecto y APK aprobado

1. Cada cambio en `main` ejecuta `Godot project tests`: importa recursos, arranca la escena real en Godot 4.3, verifica que se construyó el mapa nuevo y sube `EcosDelUmbral-project-review` (ZIP del proyecto sin cachés). No compila ni sube APK.
2. Chapio recibe aquí el ZIP para revisar. También puede inspeccionarlo/importarlo en el editor de Godot; el test headless no reemplaza la prueba visual, táctil o de rendimiento en su Android.
3. Solo cuando Chapio diga que esa versión le gustó, Zapia ejecuta `.github/workflows/android-apk.yml` con `workflow_dispatch`. Ese flujo vuelve a importar y arrancar la escena antes de exportar `EcosDelUmbral-debug.apk`.

## Separación de los dos flujos

- `godot-test.yml`: automático al cambiar el proyecto; test + ZIP de revisión, sin APK.
- `android-apk.yml`: manual y separado; APK debug arm64 únicamente tras la aprobación explícita en el chat.

El APK de depuración no es una compilación de Play Store. Un test CI correcto confirma que Godot pudo importar y arrancar la escena en modo headless, no demuestra cómo se ve o responde en el teléfono.
