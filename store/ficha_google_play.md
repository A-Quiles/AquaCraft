# Ficha de Google Play — AquaCraft (v0.7)

Textos listos para pegar en Play Console (límites comprobados). Primero español (España); el inglés
cubre el resto de mercados hasta que traduzcamos el juego.

## Español (es-ES)

**Nombre (27/30):** AquaCraft: Acuario de Peces

**Descripción breve (79/80):**
Cría peces únicos, cuida el agua y crea tu acuario: de una bola a 1000 litros.

**Descripción completa (≈2.700/4.000):**

¿Te imaginas un acuario que sigue vivo aunque cierres el móvil? En AquaCraft empiezas con una humilde pecera
redonda y, poco a poco, construyes el acuario de tus sueños: crías peces irrepetibles, cuidas el agua como un
acuarista de verdad y decoras cada rincón. Un juego cozy, relajante y precioso, sin anuncios y sin compras.

🐠 29 ESPECIES DE AGUA DULCE Y SALADA
Guppy, tetra neón, betta, pez disco, gurami, pleco, ramirezi, pez payaso, cirujano azul, pez mandarín, ángel
emperador… Cada especie tiene su anatomía, su dieta y su carácter: los neones van en banco, el betta no tolera
a otro betta, la damisela es territorial y el barbo tigre muerde las aletas largas.

🧬 CRÍA PECES ÚNICOS
Cada pez lleva genes de color, patrón y tamaño. Cruza dos ejemplares y descubre qué nace: mezclas de color,
patrones raros y mutaciones Neón, Albino, Velo o Gigante. Cinco rarezas, de Común a Legendario, y un álbum de
colección con premios.

📦 PEDIDOS DE CLIENTES
La señora Pilar busca un guppy rojo; el Acuario Municipal, un ángel raro. Cría lo que piden y cobra mucho más
que en la tienda.

💧 CUIDA EL AGUA DE VERDAD
Temperatura, pH, oxígeno, salinidad, algas en el cristal y suciedad en el fondo. Usa el limpiacristales, el
sifón, los reguladores de pH, la sal marina y medicinas contra el punto blanco o los hongos. Los aparatos se
desgastan: los básicos son baratos pero se rompen si los descuidas.

🌱 DECORA Y MOLDEA
Arrastra plantas, rocas, castillos y corales donde quieras, moldea la arena para hacer montañas y poda tus
plantas cuando crezcan: cada esqueje es una planta nueva.

🎃 EVENTOS DE TEMPORADA
Halloween, Navidad, primavera y verano traen peces y adornos de edición limitada.

🏆 CRECE COMO ACUARISTA
De la pecera redonda al acuario Monumental de 1000 litros, hasta tres peceras a la vez, misiones, retos
diarios, racha de días con huevo misterioso y niveles que desbloquean especies y equipo.

🌙 UN RINCÓN PARA DESCONECTAR
Rayos de luz, cáusticas en el fondo, burbujas, música lo-fi y una habitación que cambia con la hora del día.
Arte 100 % propio, ligero y optimizado para cualquier Android.

✔ Juega sin conexión  ✔ Sin anuncios  ✔ Sin compras  ✔ Tres modos: Relax, Normal y Realista

Descarga AquaCraft y crea el acuario más bonito del mundo. 🐟

## English (en-US)

**Title (29/30):** AquaCraft: Cozy Fish Aquarium

**Short description (79/80):**
Breed unique fish, care for the water and grow from a fishbowl to a 1000 L tank.

**Full description:**

Start with a humble round fishbowl and grow the aquarium of your dreams. Breed one-of-a-kind fish, keep the
water healthy like a real fishkeeper and decorate every corner. Cozy, relaxing and beautiful — no ads, no
purchases.

🐠 29 FRESHWATER & SALTWATER SPECIES — guppy, neon tetra, betta, discus, gourami, pleco, clownfish, blue tang,
mandarin, emperor angelfish… each with its own anatomy, diet and temperament (schooling, territorial, fin
nippers).

🧬 BREED UNIQUE FISH — colors, patterns and sizes are inherited; Neon, Albino, Veil and Giant mutations; five
rarities and a collection album with rewards.

📦 CUSTOMER ORDERS — breed what customers ask for and earn far more than at the shop.

💧 REAL FISHKEEPING — temperature, pH, oxygen, salinity, glass algae and dirty gravel. Use the scraper, the
gravel vacuum, pH buffers, sea salt and medicines. Cheap gear wears out faster.

🌱 DECORATE & SCULPT — drag plants and ornaments anywhere, sculpt the sand into hills and trim growing plants.

🎃 SEASONAL EVENTS — limited fish and decorations for Halloween, Christmas, spring and summer.

✔ Plays offline ✔ No ads ✔ No purchases ✔ Relax, Normal and Realistic modes

## Recursos gráficos

- Icono `assets/icon.png` (512×512) y gráfico destacado `store/feature_graphic.png` (1024×500).
- Capturas `store/screenshots/1-8.png` (1080×1920). Orden pensado para la conversión: pecera bonita → cría →
  pedidos → álbum → cuidados → bola inicial → decoración → evento.
- Vídeo promocional `store/promo.mp4` (720×1280, 23 s, con música): subirlo a YouTube (no listado) y pegar la
  URL en Play Console.
- Se regeneran con: capturas `-- demo=N open=... shot=sN.png night=0` a 1080×1920 + `tools/compose_screenshots.py`;
  vídeo `--write-movie promo.avi --fixed-fps 30 -- demo=3 promo=1` (con un override.cfg de 720×1280) + ffmpeg.

## Estrategia ASO

- **Palabra clave principal:** "acuario" (en el título) + "peces" (título y primera frase).
- **Secundarias repartidas en la descripción:** pecera, criar peces, simulador, relajante, cozy, betta, pez
  payaso, guppy, mutaciones, colección, agua salada. Google indexa la descripción completa: 2-4 veces cada una,
  de forma natural.
- **Categoría:** Juegos → Simulación. **Etiquetas:** Simulación, Casual, Relajante, Animales, Un jugador.
- **Clasificación de contenido (IARC):** sin violencia, sin compras, sin chat → previsiblemente PEGI 3 / Everyone.
- **Seguridad de los datos:** no recoge ni comparte datos y no usa internet. Responder "No" a recogida y a
  compartición. Permiso de notificaciones (Android 13+): solo para avisos locales.
- **Público objetivo:** 13+ (evita el programa Familias mientras no haga falta).
- **Experimentos de ficha:** probar (A/B) icono payaso vs. bola con peces, y el titular de la primera captura.
- **Eventos:** actualizar la ficha (captura 8 y descripción breve) al empezar cada evento: Play premia la
  ficha "viva" y los eventos son un buen motivo de reinstalación.
- **Próximos idiomas:** inglés, portugués (BR), hindi, indonesio, español (LatAm), ruso, japonés, alemán,
  francés y coreano.

## Política de privacidad

Texto en `docs/privacidad.html`. Para tener una URL pública: GitHub Pages (Settings → Pages → rama `main`,
carpeta `/docs`). Con el repo privado, Pages necesita un plan de pago; alternativa gratuita: publicar ese HTML
en cualquier hosting o en un repo público aparte. Si cambia la URL, actualizar `PRIVACY_URL` en
`scripts/ui/hud.gd` (botón de Ajustes).
