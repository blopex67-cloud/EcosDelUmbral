# Plano de nivel — Noche en la Pizzería

## Zonas y recorrido (coordenadas aproximadas X/Z)

- **Huella cerrada:** recinto de aproximadamente 56 × 56 m; el piso y el techo son superficies continuas bajo todos los cuartos y pasillos.
- **Comedor central:** X -20…20, Z -14…12; diez mesas en dos filas y pasillos de paso entre ellas.
- **Escenario:** al norte del comedor, centrado cerca de (0,-11), con entrada desde el comedor y cortinas/luces originales.
- **Corredor de servicio posterior:** detrás del escenario, enlazado al comedor; cocina/mostrador y un área de trabajo al fondo.
- **Pasillo oeste y pasillo este:** laterales del comedor con entradas a puertas alineadas y retorno hacia el área posterior.
- **Oficina de seguridad:** al sur, con entrada central desde el comedor por un corredor corto, escritorio y gabinetes.

## Reglas de construcción

1. Las paredes estructurales se construyen en segmentos únicamente alrededor de puertas identificables; piso y techo no tienen huecos negros.
2. Molduras, zoclos y rieles superiores siguen cada segmento de pared y no atraviesan los vanos.
3. El comedor conserva rutas de unos 2 m o más entre mesas; los colliders son cajas/cápsulas simples.
4. El perseguidor recalcula la ruta por las aperturas entre zonas, no busca cruzar muros en diagonal; raycasts a corta distancia ayudan a rodear obstáculos cercanos y detectan atascos para volver a planear.
5. El filtro CCTV queda activo al entrar a la partida; los rótulos quedan encima del filtro, para leerse como HUD del monitor.
6. Decoración y señales son originales; no se copian personajes, logotipos ni ilustraciones de FNAF.

La geometría y las rutas se validan en el smoke test headless; la escala visual, recorribilidad real y respuesta táctil aún requieren prueba en teléfono.
