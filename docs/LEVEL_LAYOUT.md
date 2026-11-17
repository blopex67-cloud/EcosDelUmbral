# Planeación de nivel — Noche en la Pizzería

## Plano de zonas (ejes Godot X/Z)

- **Comedor central:** límites aproximados X -24…24, Z -22…22. Entrada al sur, mesas en dos filas con pasillos longitudinales despejados.
- **Escenario:** extremo norte del comedor, centrado cerca de (0, -18.5); tarima, cortinas, luces y decoración original genérica.
- **Cocina y preparación:** detrás del escenario, alrededor de Z -12…-20, con mostradores y espacio de paso.
- **Pasillo oeste:** conecta comedor y corredores de servicio/alacenas del ala oeste; iluminación cálida interrumpida para controlar líneas de visión.
- **Ala este:** corredor de servicio que lleva a una intersección y a una vuelta corta con habitaciones laterales.

## Reglas de composición

1. Las mesas low-poly quedan en una cuadrícula repetible; cada grupo conserva corredores para pasar y que no tape la cámara en primera persona.
2. Los muebles low-poly se comparten mediante dos MultiMesh (mesa/silla), con colisionadores de caja sencillos; no se crean colliders triangulares.
3. Mantener las rutas principales a unos 2 m de ancho o más, evitando callejones sin salida no intencionados.
4. Usar muros estructurales separados de molduras, tuberías y cortinas; las piezas decorativas no deben cerrar pasos.
5. El terror se obtiene con luces, siluetas, audio, desgaste y cámaras genéricas, no copiando personajes, logos, poster art ni diseños identificables de FNAF.

Este documento describe el mapa procedural actual y el criterio para ampliarlo; la prueba en teléfono sigue siendo necesaria para validar escala y navegación.
