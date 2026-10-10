class_name Catalog
extends RefCounted
## Datos estáticos del juego. Balancear aquí: precios, tiempos y desbloqueos.

## Forma (anatomía para el shader del pez; x de cola a hocico, t = 0 pedúnculo → 1 hocico):
##   len: semilongitud del cuerpo · ht/hb: altura del lomo / del vientre · peak: dónde es más alto (t)
##   kf/kr/kb: curvatura del morro / de la parte trasera / del vientre (0.3 redondo … 1.2 afilado)
##   ped: grosor del pedúnculo · tail: 0 redonda, 1 horquilla, 2 doble, 3 velo, 4 lira/media luna,
##   5 delta (guppy), 6 corta redondeada · tl/th: largo/alto de la cola
##   d/a: aleta dorsal / anal [t inicio, t fin, altura, barrido hacia atrás] · dp: punta de la dorsal (<1 redonda)
##   d2: 2ª dorsal · adip: aleta adiposa · barb: barbillones · thr: filamentos ventrales · eye: posición del ojo (t)
##   aspect: ancho/alto del quad · px: ancho en píxeles (adulto)
## water: "dulce" o "salada" · temp/ph: rangos cómodos (las marinas además necesitan salinidad 1.020–1.026)
## Economía: price, level, load (oxígeno), incubate/grow (segundos reales)
## presets: [cuerpo, patrón, aletas] · patterns: patrones normales de la especie
## Convivencia (opcional): school = mínimo de su especie para estar a gusto (pez de banco) · solo = no tolera a otro
## de su especie · aggr = acosa a los peces tranquilos · nipper = muerde aletas largas · predator = se come a los
## peces pequeños (px ≤ 62) · algae_eat = frena las algas · cleaner = previene parásitos
## life: días de vida (después de ~80% es anciano)
const SPECIES := {
	"guppy": {
		"diet": ["escamas", "granulos", "artemia"], "name": "Guppy", "water": "dulce", "desc": "Pequeño y alegre, con una cola en delta enorme y de mil colores.",
		"price": 15, "level": 1, "temp": [21.0, 28.0], "ph": [6.8, 8.0], "load": 0.6,
		"incubate": 180, "grow": 900, "speed": 62.0, "zone": "mid",
		"shape": {"len": 0.36, "ht": 0.15, "hb": 0.15, "peak": 0.6, "kf": 0.6, "kr": 0.5, "kb": 0.45, "ped": 0.45,
			"tail": 5, "tl": 0.66, "th": 0.4, "d": [0.12, 0.42, 0.16, 0.6], "dp": 0.8, "a": [0.2, 0.36, 0.06, 0.3], "eye": 0.82, "aspect": 1.75, "px": 74.0},
		"patterns": [1, 2, 7, 6],
		"presets": [["d8dde3", "ff5a36", "ff7a3d"], ["dfe4ea", "3fa3ff", "4cb8ff"], ["e8e2d8", "ffd23f", "ffbf1f"],
			["e2dde8", "ff4fa3", "ff6fb5"], ["dfe6e0", "38d39f", "3ad6b0"], ["3a3d4a", "ff3b3b", "ff4a4a"]],
	},
	"neon": {
		"school": 3, "diet": ["escamas", "artemia"], "name": "Tetra neón", "water": "dulce", "desc": "Torpedo diminuto con una franja azul que brilla como un letrero.",
		"price": 20, "level": 1, "temp": [21.0, 27.0], "ph": [5.8, 7.3], "load": 0.5,
		"incubate": 300, "grow": 1200, "speed": 72.0, "zone": "mid",
		"shape": {"len": 0.62, "ht": 0.19, "hb": 0.17, "peak": 0.6, "kf": 0.7, "kr": 0.6, "kb": 0.5, "ped": 0.35,
			"tail": 1, "tl": 0.3, "th": 0.2, "d": [0.5, 0.64, 0.12, 0.3], "dp": 1.2, "a": [0.18, 0.42, 0.08, 0.2], "adip": 1.0, "eye": 0.84, "aspect": 2.3, "px": 58.0},
		"patterns": [4],
		"presets": [["9fb3c8", "25d0ff", "ff4058"], ["b8c2cc", "4cf3c9", "ff5a3c"], ["a7b0d6", "6f7bff", "ff4f8a"]],
	},
	"corydoras": {
		"school": 3, "diet": ["granulos"], "name": "Corydoras", "water": "dulce", "desc": "Acorazado, de vientre plano y con bigotitos para rebuscar en el fondo.",
		"price": 35, "level": 2, "temp": [21.0, 27.0], "ph": [6.0, 7.8], "load": 0.7,
		"incubate": 420, "grow": 1500, "speed": 42.0, "zone": "bottom",
		"shape": {"len": 0.6, "ht": 0.3, "hb": 0.13, "peak": 0.62, "kf": 0.85, "kr": 0.6, "kb": 0.15, "ped": 0.42,
			"tail": 1, "tl": 0.3, "th": 0.24, "d": [0.5, 0.7, 0.3, 0.25], "dp": 1.4, "a": [0.15, 0.3, 0.08, 0.2], "adip": 1.0, "barb": 1.0, "eye": 0.8, "aspect": 2.0, "px": 66.0},
		"patterns": [2],
		"presets": [["c9a77c", "5a4632", "d6bf9e"], ["e8d3b0", "4a3a2a", "e8dcc4"], ["8fa37b", "3b4a2a", "a8b894"]],
	},
	"goldfish": {
		"diet": ["escamas", "granulos"], "name": "Pez dorado", "water": "dulce", "desc": "Variedad cola de velo: cuerpo de huevo y doble cola. Agua fría.",
		"price": 30, "level": 2, "temp": [17.0, 24.0], "ph": [6.8, 8.0], "load": 1.4,
		"incubate": 360, "grow": 1800, "speed": 40.0, "zone": "mid",
		"shape": {"len": 0.46, "ht": 0.37, "hb": 0.35, "peak": 0.5, "kf": 0.45, "kr": 0.6, "kb": 0.45, "ped": 0.32,
			"tail": 2, "tl": 0.62, "th": 0.44, "d": [0.3, 0.68, 0.22, 0.3], "dp": 0.7, "a": [0.12, 0.3, 0.12, 0.3], "eye": 0.8, "aspect": 1.5, "px": 110.0},
		"patterns": [0, 6, 1],
		"presets": [["ff8a1f", "fff4e0", "ff9a3a"], ["ffcc33", "ff6a1a", "ffd04d"], ["ff4a2e", "ffffff", "ff5a40"], ["fff3e6", "ff5a26", "fff1e0"]],
	},
	"molly": {
		"diet": ["escamas", "nori", "granulos"], "name": "Molly velero", "water": "dulce", "desc": "Su enorme aleta dorsal es una vela. Tranquilo y resistente.",
		"price": 40, "level": 3, "temp": [22.0, 28.0], "ph": [7.0, 8.2], "load": 1.0,
		"incubate": 420, "grow": 1800, "speed": 46.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.26, "hb": 0.24, "peak": 0.55, "kf": 0.55, "kr": 0.5, "kb": 0.5, "ped": 0.55,
			"tail": 0, "tl": 0.38, "th": 0.32, "d": [0.12, 0.66, 0.3, 0.35], "dp": 0.7, "a": [0.25, 0.42, 0.09, 0.3], "eye": 0.83, "aspect": 1.7, "px": 88.0},
		"patterns": [0, 6, 1],
		"presets": [["1d1f26", "3a3d4a", "2a2d38"], ["f2b134", "ffffff", "f4c04f"], ["f5f7fa", "1d1f26", "eceff4"], ["ff8c42", "1d1f26", "ff9a55"]],
	},
	"betta": {
		"solo": true, "diet": ["artemia", "granulos"], "name": "Betta", "water": "dulce", "desc": "El pez luchador: aletas de seda que caen como un vestido.",
		"price": 60, "level": 3, "temp": [24.0, 29.0], "ph": [6.0, 7.6], "load": 1.0,
		"incubate": 600, "grow": 2400, "speed": 34.0, "zone": "top",
		"shape": {"len": 0.42, "ht": 0.18, "hb": 0.2, "peak": 0.55, "kf": 0.6, "kr": 0.45, "kb": 0.45, "ped": 0.6,
			"tail": 3, "tl": 0.62, "th": 0.52, "d": [0.08, 0.45, 0.3, 0.9], "dp": 0.7, "a": [0.0, 0.68, 0.36, 0.7], "eye": 0.84, "aspect": 1.35, "px": 112.0},
		"patterns": [0, 1, 7],
		"presets": [["2a4dff", "ff2f6d", "2f56ff"], ["d6142e", "2a1a5e", "e0183a"], ["7b2cff", "ff4fcf", "8a3cff"], ["101a4a", "35e0ff", "1a3a8a"], ["f5f2ff", "ff9ec7", "f5f0ff"]],
	},
	"rainbow": {
		"school": 3, "diet": ["escamas", "artemia"], "name": "Pez arcoíris", "water": "dulce", "desc": "Lomo alto, hocico fino y dos dorsales. Medio azul, medio fuego.",
		"price": 75, "level": 4, "temp": [23.0, 28.0], "ph": [6.8, 8.0], "load": 1.2,
		"incubate": 720, "grow": 2700, "speed": 74.0, "zone": "mid",
		"shape": {"len": 0.62, "ht": 0.38, "hb": 0.24, "peak": 0.5, "kf": 1.0, "kr": 0.55, "kb": 0.5, "ped": 0.32,
			"tail": 1, "tl": 0.32, "th": 0.27, "d": [0.32, 0.52, 0.16, 0.4], "dp": 0.9, "d2": 0.12, "a": [0.05, 0.55, 0.13, 0.4], "eye": 0.86, "aspect": 1.75, "px": 98.0},
		"patterns": [1],
		"presets": [["2d5bd8", "ff8c1a", "4a73e0"], ["2fd1c4", "ffd23f", "3ad6c8"], ["7a3cff", "ff5aa5", "8a50ff"]],
	},
	"angelfish": {
		"predator": true, "diet": ["escamas", "artemia"], "name": "Pez ángel", "water": "dulce", "desc": "Cuerpo de diamante, aletas como velas y largos filamentos.",
		"price": 120, "level": 6, "temp": [24.0, 29.0], "ph": [6.0, 7.5], "load": 1.6,
		"incubate": 1200, "grow": 3600, "speed": 34.0, "zone": "mid",
		"shape": {"len": 0.36, "ht": 0.3, "hb": 0.3, "peak": 0.55, "kf": 0.7, "kr": 0.75, "kb": 0.75, "ped": 0.3,
			"tail": 4, "tl": 0.42, "th": 0.36, "d": [0.12, 0.7, 0.62, 1.2], "dp": 1.3, "a": [0.12, 0.68, 0.62, 1.2], "thr": 0.55, "eye": 0.8, "aspect": 0.95, "px": 124.0},
		"patterns": [3, 0, 6],
		"presets": [["dfe5ea", "2a2f3a", "e6ebef"], ["ffd23f", "ff8c1a", "ffe07a"], ["2a2f3a", "4a5060", "3a3f4a"], ["f0f2f5", "ff7a3a", "f5f6f8"]],
	},
	"discus": {
		"diet": ["artemia", "granulos"], "name": "Disco", "water": "dulce", "desc": "Un disco perfecto con aletas como un fleco. El rey del agua dulce.",
		"price": 260, "level": 8, "temp": [27.0, 31.0], "ph": [5.8, 7.0], "load": 1.8,
		"incubate": 1800, "grow": 5400, "speed": 30.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.52, "hb": 0.52, "peak": 0.5, "kf": 0.42, "kr": 0.42, "kb": 0.42, "ped": 0.26,
			"tail": 6, "tl": 0.24, "th": 0.24, "d": [0.08, 0.8, 0.12, 0.1], "dp": 0.4, "a": [0.08, 0.74, 0.11, 0.1], "eye": 0.8, "aspect": 1.2, "px": 118.0},
		"patterns": [3, 6],
		"presets": [["ff3d2e", "2fd6ff", "ff5a40"], ["2fd6ff", "ff7a2e", "3fdcff"], ["ffcf3f", "ff3d2e", "ffd85a"], ["ff6fa8", "ffd0e6", "ff80b5"]],
	},
	"platy": {
		"diet": ["escamas", "granulos", "nori"], "name": "Platy", "water": "dulce", "desc": "Pequeño, tranquilo y de colores vivos. Perfecto para empezar.",
		"price": 18, "level": 1, "temp": [20.0, 26.0], "ph": [7.0, 8.2], "load": 0.6, "life": 45,
		"incubate": 200, "grow": 1000, "speed": 50.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.25, "hb": 0.22, "peak": 0.55, "kf": 0.55, "kr": 0.5, "kb": 0.5, "ped": 0.5,
			"tail": 0, "tl": 0.32, "th": 0.28, "d": [0.3, 0.58, 0.15, 0.3], "dp": 0.8, "a": [0.25, 0.4, 0.08, 0.3], "eye": 0.82, "aspect": 1.8, "px": 64.0},
		"patterns": [0, 7, 2],
		"presets": [["ff4a2e", "1d1f26", "ff5a3a"], ["ffb020", "ff4a2e", "ffc040"], ["3a7bd5", "1d1f26", "f2b134"], ["f5f2e8", "ff7a3a", "fff4e0"]],
	},
	"danio": {
		"diet": ["escamas", "artemia"], "name": "Pez cebra", "water": "dulce", "desc": "Rayado como una cebra y siempre en movimiento. Va en grupo.",
		"price": 16, "level": 1, "temp": [18.0, 25.0], "ph": [6.5, 7.8], "load": 0.45, "life": 45, "school": 3,
		"incubate": 160, "grow": 900, "speed": 82.0, "zone": "top",
		"shape": {"len": 0.64, "ht": 0.15, "hb": 0.14, "peak": 0.55, "kf": 0.7, "kr": 0.5, "kb": 0.45, "ped": 0.42,
			"tail": 1, "tl": 0.3, "th": 0.22, "d": [0.4, 0.58, 0.1, 0.3], "dp": 0.9, "a": [0.2, 0.42, 0.08, 0.25], "barb": 0.4, "eye": 0.85, "aspect": 2.5, "px": 60.0},
		"patterns": [9],
		"presets": [["d9d2b0", "2a3f8f", "e8e2c8"], ["e8d58a", "2c3a7a", "f0e6b0"], ["f0b0c8", "4a3a9a", "f5c0d0"]],
	},
	"rasbora": {
		"diet": ["escamas", "artemia"], "name": "Rasbora arlequín", "water": "dulce", "desc": "Cobriza con un triángulo negro. Nada en bancos muy sincronizados.",
		"price": 25, "level": 2, "temp": [22.0, 27.0], "ph": [6.0, 7.5], "load": 0.5, "life": 50, "school": 3,
		"incubate": 300, "grow": 1200, "speed": 64.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.24, "hb": 0.21, "peak": 0.55, "kf": 0.6, "kr": 0.55, "kb": 0.5, "ped": 0.38,
			"tail": 1, "tl": 0.32, "th": 0.24, "d": [0.42, 0.6, 0.13, 0.3], "dp": 1.0, "a": [0.2, 0.42, 0.1, 0.25], "eye": 0.84, "aspect": 2.0, "px": 60.0},
		"patterns": [10],
		"presets": [["e88a5a", "1a1414", "ff7a4a"], ["f0a070", "1d1818", "ff9a5a"], ["d8b4a0", "201a1a", "ffb080"]],
	},
	"gurami": {
		"diet": ["escamas", "artemia"], "name": "Gurami enano", "water": "dulce", "desc": "Rayas rojas y azules y dos antenas que usa para tantear. Un macho por pecera.",
		"price": 55, "level": 3, "temp": [24.0, 28.0], "ph": [6.0, 7.5], "load": 0.9, "life": 70, "solo": true,
		"incubate": 480, "grow": 2000, "speed": 38.0, "zone": "top",
		"shape": {"len": 0.5, "ht": 0.31, "hb": 0.29, "peak": 0.5, "kf": 0.55, "kr": 0.55, "kb": 0.55, "ped": 0.45,
			"tail": 0, "tl": 0.34, "th": 0.32, "d": [0.12, 0.62, 0.16, 0.5], "dp": 0.6, "a": [0.0, 0.62, 0.2, 0.5], "thr": 0.42, "eye": 0.82, "aspect": 1.45, "px": 82.0},
		"patterns": [3],
		"presets": [["ff4a2e", "3fa3ff", "ff5a3a"], ["ff6a1a", "4cb8ff", "ff7a2a"], ["3fa3ff", "ff4a2e", "4cb8ff"]],
	},
	"pleco": {
		"diet": ["nori", "granulos"], "name": "Pleco ancistrus", "water": "dulce", "desc": "Ventosa en la boca y cara peluda. Se come las algas del cristal (un 20% menos).",
		"price": 70, "level": 3, "temp": [22.0, 27.0], "ph": [6.5, 7.8], "load": 1.0, "life": 90, "algae_eat": 0.2,
		"incubate": 720, "grow": 2400, "speed": 26.0, "zone": "bottom",
		"shape": {"len": 0.62, "ht": 0.22, "hb": 0.1, "peak": 0.68, "kf": 0.95, "kr": 0.55, "kb": 0.15, "ped": 0.5,
			"tail": 0, "tl": 0.28, "th": 0.26, "d": [0.5, 0.78, 0.26, 0.2], "dp": 0.8, "a": [0.15, 0.3, 0.08, 0.2], "adip": 1.0, "barb": 1.0, "eye": 0.86, "aspect": 2.2, "px": 92.0},
		"patterns": [2],
		"presets": [["4a3a2a", "d8c8a8", "3a2e22"], ["3a3a36", "e8e0c8", "2e2e2a"], ["e8c8a0", "ffffff", "e0c098"]],
	},
	"ramirezi": {
		"diet": ["artemia", "granulos"], "name": "Ramirezi", "water": "dulce", "desc": "Cíclido enano con lentejuelas azules y ojo rojo. Delicado: agua cálida y limpia.",
		"price": 140, "level": 5, "temp": [26.0, 30.0], "ph": [5.5, 7.0], "load": 0.9, "life": 70,
		"incubate": 900, "grow": 3000, "speed": 36.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.33, "hb": 0.27, "peak": 0.55, "kf": 0.6, "kr": 0.55, "kb": 0.55, "ped": 0.42,
			"tail": 6, "tl": 0.3, "th": 0.3, "d": [0.1, 0.76, 0.22, 0.4], "dp": 1.4, "a": [0.12, 0.42, 0.14, 0.4], "eye": 0.8, "aspect": 1.6, "px": 76.0},
		"patterns": [2, 1],
		"presets": [["f2c040", "3fa3ff", "ff7a3a"], ["ffd23f", "4cb8ff", "ff5a3a"], ["3fa3ff", "ffd23f", "4cb8ff"]],
	},
	"barbo": {
		"diet": ["escamas", "granulos", "artemia"], "name": "Barbo tigre", "water": "dulce", "desc": "Dorado con cuatro barras negras. Vivaracho y muerde las aletas largas.",
		"price": 45, "level": 3, "temp": [20.0, 26.0], "ph": [6.0, 7.8], "load": 0.7, "life": 60, "school": 3, "nipper": true,
		"incubate": 360, "grow": 1500, "speed": 70.0, "zone": "mid",
		"shape": {"len": 0.52, "ht": 0.34, "hb": 0.28, "peak": 0.5, "kf": 0.75, "kr": 0.55, "kb": 0.5, "ped": 0.36,
			"tail": 1, "tl": 0.32, "th": 0.3, "d": [0.42, 0.62, 0.2, 0.3], "dp": 1.0, "a": [0.18, 0.36, 0.12, 0.3], "eye": 0.84, "aspect": 1.7, "px": 70.0},
		"patterns": [3],
		"presets": [["e8b84a", "1a1414", "ff3b1f"], ["d8c060", "1d1a14", "ff4a2a"], ["4a8a4a", "1a2a1a", "ff3b1f"]],
	},
	"hacha": {
		"diet": ["escamas", "artemia"], "name": "Pez hacha", "water": "dulce", "desc": "Vientre en forma de hacha y espalda recta. Vive pegado a la superficie, en grupo.",
		"price": 50, "level": 4, "temp": [23.0, 28.0], "ph": [6.0, 7.0], "load": 0.5, "life": 60, "school": 3,
		"incubate": 420, "grow": 1600, "speed": 60.0, "zone": "top",
		"shape": {"len": 0.46, "ht": 0.06, "hb": 0.46, "peak": 0.55, "kf": 0.9, "kr": 0.6, "kb": 0.95, "ped": 0.3,
			"tail": 1, "tl": 0.3, "th": 0.24, "d": [0.3, 0.42, 0.1, 0.3], "dp": 1.0, "a": [0.1, 0.4, 0.06, 0.3], "eye": 0.82, "aspect": 1.35, "px": 60.0},
		"patterns": [1],
		"presets": [["c8d2dc", "8a98a8", "e0e6ec"], ["d8d0c0", "a09078", "e8e0d0"]],
	},
	# ───── Agua salada ─────
	"payaso": {
		"diet": ["escamas", "artemia", "granulos"], "name": "Pez payaso", "water": "salada", "desc": "Naranja con tres bandas blancas. Feliz si tiene una anémona.",
		"price": 45, "level": 1, "temp": [24.0, 28.0], "ph": [7.9, 8.5], "load": 0.8,
		"incubate": 600, "grow": 2400, "speed": 44.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.27, "hb": 0.24, "peak": 0.55, "kf": 0.5, "kr": 0.55, "kb": 0.5, "ped": 0.5,
			"tail": 6, "tl": 0.3, "th": 0.26, "d": [0.12, 0.74, 0.14, 0.2], "dp": 0.55, "a": [0.12, 0.4, 0.13, 0.2], "eye": 0.82, "aspect": 1.8, "px": 74.0},
		"patterns": [5],
		"presets": [["ff7a1a", "ffffff", "ff8a2a"], ["ff5a14", "ffffff", "ff6a24"], ["2a2626", "ffffff", "2e2a2a"]],
	},
	"gramma": {
		"diet": ["artemia"], "name": "Gramma loreto", "water": "salada", "desc": "Mitad violeta, mitad amarillo. Pequeño y muy pacífico.",
		"price": 60, "level": 2, "temp": [24.0, 27.0], "ph": [7.9, 8.5], "load": 0.6,
		"incubate": 540, "grow": 2100, "speed": 50.0, "zone": "mid",
		"shape": {"len": 0.58, "ht": 0.21, "hb": 0.19, "peak": 0.6, "kf": 0.6, "kr": 0.5, "kb": 0.5, "ped": 0.45,
			"tail": 0, "tl": 0.32, "th": 0.24, "d": [0.1, 0.74, 0.1, 0.2], "dp": 0.6, "a": [0.1, 0.42, 0.1, 0.2], "eye": 0.84, "aspect": 2.1, "px": 66.0},
		"patterns": [7],
		"presets": [["8a3cff", "ffd23f", "ffd23f"], ["b13cff", "ffc21f", "ffc21f"]],
	},
	"gobio_fuego": {
		"diet": ["artemia"], "name": "Gobio de fuego", "water": "salada", "desc": "Esbelto, con una dorsal en forma de lanza y cola de fuego.",
		"price": 80, "level": 3, "temp": [24.0, 27.0], "ph": [7.9, 8.5], "load": 0.5,
		"incubate": 600, "grow": 2400, "speed": 56.0, "zone": "bottom",
		"shape": {"len": 0.62, "ht": 0.15, "hb": 0.14, "peak": 0.6, "kf": 0.6, "kr": 0.45, "kb": 0.45, "ped": 0.55,
			"tail": 0, "tl": 0.3, "th": 0.2, "d": [0.58, 0.78, 0.5, 0.35], "dp": 2.0, "d2": 0.09, "a": [0.1, 0.5, 0.08, 0.2], "eye": 0.84, "aspect": 1.7, "px": 72.0},
		"patterns": [1],
		"presets": [["fff6ee", "ff3d1f", "ff5a2a"], ["fff0f6", "c63cff", "ff3d7a"]],
	},
	"cirujano_azul": {
		"solo": true, "diet": ["nori"], "name": "Cirujano azul", "water": "salada", "desc": "Azul eléctrico con su dibujo negro de paleta y cola amarilla.",
		"price": 140, "level": 3, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.4,
		"incubate": 1200, "grow": 3600, "speed": 52.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.36, "hb": 0.34, "peak": 0.52, "kf": 0.9, "kr": 0.55, "kb": 0.55, "ped": 0.25,
			"tail": 4, "tl": 0.34, "th": 0.34, "d": [0.1, 0.8, 0.1, 0.15], "dp": 0.5, "a": [0.1, 0.62, 0.09, 0.15], "eye": 0.8, "aspect": 1.55, "px": 102.0},
		"patterns": [8],
		"presets": [["1f63e8", "141a2e", "ffd23f"], ["2a7bff", "121a33", "ffc81f"]],
	},
	"cirujano_amarillo": {
		"diet": ["nori"], "name": "Cirujano amarillo", "water": "salada", "desc": "Un disco amarillo limón con hocico de trompeta.",
		"price": 120, "level": 4, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.3,
		"incubate": 1200, "grow": 3600, "speed": 48.0, "zone": "mid",
		"shape": {"len": 0.48, "ht": 0.48, "hb": 0.46, "peak": 0.5, "kf": 1.15, "kr": 0.55, "kb": 0.55, "ped": 0.3,
			"tail": 4, "tl": 0.32, "th": 0.32, "d": [0.08, 0.86, 0.26, 0.25], "dp": 0.6, "a": [0.08, 0.72, 0.24, 0.25], "eye": 0.76, "aspect": 1.2, "px": 102.0},
		"patterns": [0],
		"presets": [["ffd400", "fff2a8", "ffd400"], ["ffe11f", "ffffff", "ffe11f"]],
	},
	"angel_llama": {
		"solo": true, "diet": ["nori", "artemia"], "name": "Ángel llama", "water": "salada", "desc": "Rojo fuego con barras negras y aletas ribeteadas de azul.",
		"price": 180, "level": 5, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.0,
		"incubate": 1500, "grow": 4200, "speed": 40.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.32, "hb": 0.31, "peak": 0.55, "kf": 0.6, "kr": 0.6, "kb": 0.6, "ped": 0.45,
			"tail": 6, "tl": 0.3, "th": 0.3, "d": [0.08, 0.72, 0.22, 0.55], "dp": 0.9, "a": [0.08, 0.5, 0.2, 0.55], "eye": 0.82, "aspect": 1.55, "px": 86.0},
		"patterns": [3],
		"presets": [["ff3b1f", "1a1414", "3a5bff"], ["ff5a14", "1f1515", "2f6bff"]],
	},
	"damisela": {
		"diet": ["escamas", "artemia", "granulos"], "name": "Damisela azul", "water": "salada", "desc": "Azul eléctrico, dura y barata. Pero es territorial: acosa a los peces tranquilos.",
		"price": 30, "level": 1, "temp": [24.0, 28.0], "ph": [7.9, 8.5], "load": 0.6, "life": 60, "aggr": true,
		"incubate": 400, "grow": 1600, "speed": 58.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.29, "hb": 0.26, "peak": 0.55, "kf": 0.55, "kr": 0.55, "kb": 0.5, "ped": 0.42,
			"tail": 1, "tl": 0.3, "th": 0.28, "d": [0.12, 0.74, 0.14, 0.3], "dp": 0.8, "a": [0.12, 0.42, 0.13, 0.3], "eye": 0.82, "aspect": 1.75, "px": 64.0},
		"patterns": [0, 1],
		"presets": [["1f63e8", "0f2a8a", "ffd23f"], ["2a7bff", "1a3aa0", "2a7bff"]],
	},
	"banggai": {
		"diet": ["artemia", "escamas"], "name": "Cardenal de Banggai", "water": "salada", "desc": "Plateado con barras negras, puntos blancos y aletas en abanico. Muy tranquilo.",
		"price": 65, "level": 2, "temp": [24.0, 28.0], "ph": [7.9, 8.5], "load": 0.7, "life": 60,
		"incubate": 600, "grow": 2200, "speed": 34.0, "zone": "mid",
		"shape": {"len": 0.46, "ht": 0.34, "hb": 0.32, "peak": 0.55, "kf": 0.6, "kr": 0.6, "kb": 0.55, "ped": 0.34,
			"tail": 1, "tl": 0.4, "th": 0.34, "d": [0.12, 0.32, 0.42, 0.6], "dp": 1.6, "d2": 0.3, "a": [0.1, 0.42, 0.3, 0.5], "thr": 0.25, "eye": 0.8, "aspect": 1.2, "px": 74.0},
		"patterns": [3],
		"presets": [["e6e8ea", "1a1a1e", "d8dade"], ["eef0f2", "141418", "e0e2e6"]],
	},
	"mandarin": {
		"diet": ["artemia"], "name": "Pez mandarín", "water": "salada", "desc": "Un cuadro psicodélico naranja y azul. Solo come artemia y vive en el fondo.",
		"price": 160, "level": 4, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 0.6, "life": 80,
		"incubate": 1200, "grow": 3600, "speed": 24.0, "zone": "bottom",
		"shape": {"len": 0.56, "ht": 0.24, "hb": 0.18, "peak": 0.6, "kf": 0.5, "kr": 0.5, "kb": 0.3, "ped": 0.5,
			"tail": 6, "tl": 0.3, "th": 0.3, "d": [0.4, 0.78, 0.18, 0.3], "dp": 0.7, "d2": 0.18, "a": [0.15, 0.55, 0.12, 0.3], "eye": 0.84, "aspect": 1.75, "px": 70.0},
		"patterns": [6],
		"presets": [["2a6aff", "ff7a1a", "2a8aff"], ["1f5ae8", "ff8a2a", "3fa3ff"]],
	},
	"pez_cofre": {
		"diet": ["artemia", "nori", "granulos"], "name": "Pez cofre", "water": "salada", "desc": "Una cajita amarilla con lunares negros que nada como un dron.",
		"price": 150, "level": 5, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.0, "life": 90,
		"incubate": 1200, "grow": 3600, "speed": 22.0, "zone": "mid",
		"shape": {"len": 0.46, "ht": 0.3, "hb": 0.3, "peak": 0.45, "kf": 0.28, "kr": 0.3, "kb": 0.25, "ped": 0.28,
			"tail": 6, "tl": 0.24, "th": 0.22, "d": [0.12, 0.2, 0.12, 0.3], "dp": 0.6, "a": [0.1, 0.2, 0.1, 0.3], "eye": 0.76, "aspect": 1.45, "px": 72.0},
		"patterns": [2],
		"presets": [["ffd400", "141414", "ffe04a"], ["ffcc1f", "1a1a1a", "ffd84a"]],
	},
	"limpiador": {
		"diet": ["artemia", "escamas"], "name": "Lábrido limpiador", "water": "salada", "desc": "Franja negra sobre azul. Desparasita a los demás: casi no hay punto blanco con él.",
		"price": 70, "level": 3, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 0.4, "life": 60, "cleaner": true,
		"incubate": 600, "grow": 2200, "speed": 60.0, "zone": "mid",
		"shape": {"len": 0.64, "ht": 0.15, "hb": 0.14, "peak": 0.55, "kf": 0.75, "kr": 0.5, "kb": 0.45, "ped": 0.42,
			"tail": 0, "tl": 0.28, "th": 0.22, "d": [0.1, 0.72, 0.08, 0.2], "dp": 0.6, "a": [0.1, 0.45, 0.07, 0.2], "eye": 0.86, "aspect": 2.6, "px": 64.0},
		"patterns": [4],
		"presets": [["4cb8ff", "141418", "4cb8ff"], ["8fd0ff", "121216", "8fd0ff"]],
	},
	"emperador": {
		"diet": ["nori", "artemia"], "name": "Ángel emperador", "water": "salada", "desc": "Rayas amarillas sobre azul profundo y antifaz negro. La joya del arrecife. Solo uno.",
		"price": 420, "level": 7, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.8, "life": 140, "solo": true,
		"incubate": 2400, "grow": 6000, "speed": 34.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.4, "hb": 0.38, "peak": 0.5, "kf": 0.6, "kr": 0.6, "kb": 0.6, "ped": 0.36,
			"tail": 6, "tl": 0.3, "th": 0.3, "d": [0.08, 0.78, 0.24, 0.45], "dp": 0.8, "a": [0.08, 0.6, 0.22, 0.45], "eye": 0.8, "aspect": 1.35, "px": 128.0},
		"patterns": [9],
		"presets": [["1a3ab8", "ffd23f", "ffd23f"], ["1f2fa0", "ffc81f", "ffe04a"]],
	},
}

const SPECIES_ORDER := ["guppy", "platy", "danio", "neon", "corydoras", "goldfish", "rasbora", "molly", "betta", "barbo",
	"gurami", "pleco", "rainbow", "hacha", "angelfish", "ramirezi", "discus",
	"payaso", "damisela", "gramma", "banggai", "gobio_fuego", "limpiador", "cirujano_azul", "cirujano_amarillo", "mandarin",
	"angel_llama", "pez_cofre", "emperador"]

const PATTERN_NAMES := ["Liso", "Degradado", "Moteado", "Barras", "Franja neón", "Bandas", "Mármol", "Bicolor", "Paleta", "Rayas", "Triángulo"]

const RARITY_NAMES := ["Común", "Poco común", "Raro", "Épico", "Legendario"]
const RARITY_COLORS := ["9aa7b5", "4fc27a", "3fa3ff", "b36bff", "ffb020"]
const RARITY_MULT := [1.0, 1.8, 3.5, 7.0, 16.0]

## round: pecera redonda (se dibuja recortada en círculo) · max_q: calidad máxima de equipo que admite
## equip: huecos de equipo disponibles (la redonda no tiene tapa: ni luz ni aireador)
const TANKS := [
	{"id": "bola", "name": "Pecera redonda 8 L", "cap": 4, "o2": 3.0, "slots": 3, "price": 0, "level": 1, "round": true, "max_q": 1,
		"equip": ["filter", "heater", "thermo"], "desc": "Una bola de cristal para empezar. Solo admite aparatos básicos."},
	{"id": "nano", "name": "Nano 20 L", "cap": 6, "o2": 4.5, "slots": 5, "price": 350, "level": 2, "max_q": 2,
		"equip": ["filter", "heater", "pump", "light", "thermo", "ato"], "desc": "Rectangular y con tapa: ya admite luz, aireador y equipo estándar."},
	{"id": "comunitario", "name": "Comunitario 60 L", "cap": 10, "o2": 8.0, "slots": 8, "price": 900, "level": 3, "max_q": 3,
		"equip": ["filter", "heater", "pump", "light", "thermo", "ato"], "desc": "Espacio para una comunidad animada y equipo profesional."},
	{"id": "panoramico", "name": "Panorámico 200 L", "cap": 18, "o2": 14.0, "slots": 11, "price": 4000, "level": 5, "max_q": 3,
		"equip": ["filter", "heater", "pump", "light", "thermo", "ato"], "desc": "Cristal panorámico para paisajes de verdad."},
	{"id": "monumental", "name": "Monumental 1000 L", "cap": 30, "o2": 24.0, "slots": 15, "price": 16000, "level": 9, "max_q": 3,
		"equip": ["filter", "heater", "pump", "light", "thermo", "ato"], "desc": "Un muro de agua. El sueño de todo acuarista."},
]

## slot: filter / heater / pump / light / thermo / ato. Instalar uno sustituye al anterior del mismo hueco.
## q: calidad 1 básico (barato, se gasta rápido y SE ROMPE al llegar a 0%) · 2 estándar · 3 pro.
## wear: % de estado que pierde por hora (el filtro, más cuanto más carga de peces).
## rate: °C por minuto que mueve el calentador (los básicos tardan más en calentar).
## maint: acción de mantenimiento que lo deja al 100%.
const EQUIPMENT := {
	"filtro_mini": {"slot": "filter", "q": 1, "name": "Mini filtro de cascada", "price": 45, "level": 1, "eff": 0.2, "wear": 4.0, "maint": "Aclarar la esponjita", "desc": "Algas un 20% más lentas. Barato, pero se atasca enseguida."},
	"esponja": {"slot": "filter", "q": 1, "name": "Filtro de esponja", "price": 120, "level": 1, "eff": 0.35, "wear": 2.5, "maint": "Escurrir la esponja", "desc": "Algas un 35% más lentas. Se ensucia rápido."},
	"mochila": {"slot": "filter", "q": 2, "name": "Filtro de mochila", "price": 700, "level": 3, "eff": 0.55, "wear": 1.6, "maint": "Cambiar el cartucho", "desc": "Algas un 55% más lentas."},
	"canister": {"slot": "filter", "q": 3, "name": "Filtro canister", "price": 2400, "level": 6, "eff": 0.75, "wear": 0.9, "maint": "Limpiar los cestillos", "desc": "Algas un 75% más lentas. Casi no da guerra."},
	"calentador_mini": {"slot": "heater", "q": 1, "name": "Calentador mini 10 W", "price": 40, "level": 1, "fixed": 24.0, "rate": 0.1, "wear": 1.6, "maint": "Quitar la cal", "desc": "Fijo a 24 °C. Calienta muy despacio y la cal lo gasta pronto."},
	"calentador_fijo": {"slot": "heater", "q": 2, "name": "Calentador fijo 50 W", "price": 110, "level": 1, "fixed": 25.0, "rate": 0.3, "wear": 0.6, "maint": "Quitar la cal", "desc": "Mantiene el agua a 25 °C."},
	"calentador": {"slot": "heater", "q": 2, "name": "Calentador con termostato", "price": 220, "level": 2, "rate": 0.6, "wear": 0.5, "maint": "Quitar la cal", "desc": "Elige la temperatura del agua (18–31 °C). Rápido."},
	"difusor": {"slot": "pump", "q": 1, "name": "Piedra difusora", "price": 120, "level": 1, "o2": 3.0, "wear": 1.4, "maint": "Cambiar la piedra", "desc": "+3 de oxígeno y burbujitas."},
	"bomba": {"slot": "pump", "q": 2, "name": "Bomba de aire doble", "price": 600, "level": 3, "o2": 6.0, "wear": 1.0, "maint": "Revisar la membrana", "desc": "+6 de oxígeno."},
	"circulacion": {"slot": "pump", "q": 3, "name": "Bomba de circulación", "price": 2000, "level": 5, "o2": 10.0, "wear": 0.8, "maint": "Limpiar el rotor", "desc": "+10 de oxígeno."},
	"led_pro": {"slot": "light", "q": 2, "name": "Pantalla LED Pro", "price": 500, "level": 2, "happy": 6.0, "wear": 0.7, "maint": "Limpiar la tapa", "desc": "Luz brillante: +felicidad y plantas más vivas."},
	"led_plantada": {"slot": "light", "q": 3, "name": "LED plantada RGB", "price": 1400, "level": 6, "happy": 10.0, "wear": 0.6, "maint": "Limpiar la tapa", "desc": "Espectro completo: colores intensos y mucha felicidad."},
	"skimmer": {"slot": "filter", "q": 2, "water": "salada", "name": "Skimmer (desnatador)", "price": 1500, "level": 3, "eff": 0.7, "wear": 1.2, "maint": "Vaciar el vaso colector", "desc": "El filtro estrella del marino: algas un 70% más lentas."},
	"ato": {"slot": "ato", "q": 2, "water": "salada", "name": "Reposición automática", "price": 700, "level": 2, "wear": 1.0, "maint": "Rellenar el depósito", "desc": "Repone el agua evaporada: la salinidad deja de subir."},
	"tira": {"slot": "thermo", "q": 1, "name": "Termómetro adhesivo", "price": 30, "level": 1, "wear": 0.35, "maint": "Despegarla y limpiarla", "desc": "Grados enteros. La tira se decolora con el tiempo."},
	"digital": {"slot": "thermo", "q": 2, "name": "Termómetro digital", "price": 180, "level": 2, "wear": 0.5, "maint": "Cambiar la pila", "desc": "Décimas de grado y alarma si tus peces pasan frío o calor."},
}
const EQUIPMENT_ORDER := ["filtro_mini", "esponja", "mochila", "canister", "skimmer", "calentador_mini", "calentador_fijo", "calentador",
	"difusor", "bomba", "circulacion", "led_pro", "led_plantada", "tira", "digital", "ato"]
const QUALITY_NAMES := ["", "Básico", "Estándar", "Pro"]
const QUALITY_COLORS := ["", "9aa7b5", "3fa3ff", "b36bff"]
const SLOT_NAMES := {"filter": "Filtro", "heater": "Calentador", "pump": "Aireador", "light": "Iluminación", "thermo": "Termómetro", "ato": "Reposición"}

## Modos de juego. algae/waste/wear/hunger/evap: multiplicadores · tol: margen sobre los rangos ideales
## (99 = da igual) · death: los peces pueden morir · room_var: la habitación se enfría de noche.
const MODES := {
	"basico": {"name": "Relax", "desc": "Sin algas, sin desgaste y sin parámetros del agua. Solo dales de comer, cría y decora.",
		"algae": 0.0, "waste": 0.0, "disease": 0.0, "wear": 0.0, "hunger": 0.6, "evap": 0.0, "tol": 99.0, "death": false, "room_var": false, "hunger_hurts": false},
	"normal": {"name": "Normal", "desc": "Cuidados sencillos: limpia, mantén el equipo y vigila temperatura y pH. Los peces no mueren.",
		"algae": 1.0, "waste": 1.0, "disease": 0.5, "wear": 0.3, "hunger": 1.0, "evap": 1.0, "tol": 1.0, "death": false, "room_var": false, "hunger_hurts": true},
	"realista": {"name": "Realista", "desc": "Acuariofilia de verdad: márgenes estrictos, la habitación se enfría de noche, el equipo se gasta antes y los peces pueden morir.",
		"algae": 1.5, "waste": 1.5, "disease": 1.5, "wear": 0.5, "hunger": 1.25, "evap": 2.0, "tol": 0.0, "death": true, "room_var": true, "hunger_hurts": true},
}
const MODE_ORDER := ["basico", "normal", "realista"]
const SALINITY := [1.020, 1.026]     ## rango cómodo de las especies marinas
const WATER_NAMES := {"dulce": "Agua dulce", "salada": "Agua salada"}


## ¿Sirve este elemento (especie, decoración, equipo, sustrato) para el tipo de agua?
static func fits(item: Dictionary, water: String) -> bool:
	var w: String = item.get("water", "ambas")
	return w == "ambas" or w == water

## kind: plant / ornament. cur: coins / pearls. fx: happy, clean (reduce algas), ph, breed{especie: x}, mutation
const DECOR := {
	"vallisneria": {"water": "dulce", "name": "Vallisneria", "kind": "plant", "price": 80, "cur": "coins", "level": 1, "fx": {"happy": 3.0, "clean": 0.05}, "desc": "Hierba alta que baila con la corriente."},
	"helecho": {"water": "dulce", "name": "Helecho de Java", "kind": "plant", "price": 70, "cur": "coins", "level": 1, "fx": {"happy": 3.0, "clean": 0.04}, "desc": "Resistente y frondoso."},
	"planta_rosa": {"water": "ambas", "name": "Planta artificial", "kind": "plant", "price": 40, "cur": "coins", "level": 1, "fx": {"happy": 2.0}, "desc": "Rosa chicle. No necesita cuidados."},
	"musgo": {"water": "dulce", "name": "Bolas de musgo", "kind": "plant", "price": 90, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "clean": 0.06}, "desc": "Esponjosas. Absorben suciedad."},
	"anubias": {"water": "dulce", "name": "Anubias", "kind": "plant", "price": 140, "cur": "coins", "level": 2, "fx": {"happy": 4.0, "clean": 0.04, "breed": {"betta": 1.5}}, "desc": "Hojas anchas. A los betta les encanta anidar debajo."},
	"rotala": {"water": "dulce", "name": "Rotala roja", "kind": "plant", "price": 180, "cur": "coins", "level": 3, "fx": {"happy": 5.0, "clean": 0.05}, "desc": "Tallos rojos que encienden el paisaje."},
	"rocas": {"water": "ambas", "name": "Rocas de río", "kind": "ornament", "price": 50, "cur": "coins", "level": 1, "fx": {"happy": 2.0}, "desc": "Cantos rodados suaves."},
	"tronco": {"water": "dulce", "name": "Raíz de manglar", "kind": "ornament", "price": 200, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "ph": -0.35, "breed": {"neon": 1.5, "discus": 1.3}}, "desc": "Acidifica el agua. Los tetras se sienten en casa."},
	"cueva": {"water": "ambas", "name": "Cueva de piedra", "kind": "ornament", "price": 260, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "breed": {"corydoras": 2.0}}, "desc": "Un escondite. Los corydoras crían el doble de rápido."},
	"castillo": {"water": "ambas", "name": "Castillo", "kind": "ornament", "price": 320, "cur": "coins", "level": 3, "fx": {"happy": 5.0}, "desc": "Torres con musgo para explorar."},
	"anfora": {"water": "ambas", "name": "Ánfora antigua", "kind": "ornament", "price": 380, "cur": "coins", "level": 4, "fx": {"happy": 5.0, "breed": {"angelfish": 1.4}}, "desc": "Los peces ángel desovan en su superficie."},
	"barco": {"water": "ambas", "name": "Barco hundido", "kind": "ornament", "price": 900, "cur": "coins", "level": 5, "fx": {"happy": 8.0}, "desc": "Un naufragio lleno de historias."},
	"cofre": {"water": "ambas", "name": "Cofre del tesoro", "kind": "ornament", "price": 15, "cur": "pearls", "level": 1, "fx": {"happy": 6.0, "mutation": 0.02}, "desc": "Burbujea con suerte: +2% de mutaciones."},
	"caulerpa": {"water": "salada", "name": "Caulerpa", "kind": "plant", "price": 80, "cur": "coins", "level": 1, "fx": {"happy": 3.0, "clean": 0.05}, "desc": "Macroalga en racimos verdes. Absorbe nitratos."},
	"anemona": {"water": "salada", "name": "Anémona", "kind": "plant", "price": 220, "cur": "coins", "level": 1, "fx": {"happy": 4.0, "breed": {"payaso": 2.0}}, "desc": "El hogar del pez payaso: con ella crían el doble de rápido."},
	"coral_blando": {"water": "salada", "name": "Coral blando", "kind": "plant", "price": 160, "cur": "coins", "level": 2, "fx": {"happy": 5.0}, "desc": "Pólipos que se abren y ondulan con la corriente."},
	"roca_viva": {"water": "salada", "name": "Roca viva", "kind": "ornament", "price": 120, "cur": "coins", "level": 1, "fx": {"happy": 2.0, "clean": 0.06}, "desc": "Roca porosa llena de bacterias buenas: limpia el agua."},
	"coral_cerebro": {"water": "salada", "name": "Coral cerebro", "kind": "ornament", "price": 350, "cur": "coins", "level": 3, "fx": {"happy": 6.0}, "desc": "Una cúpula de surcos hipnóticos."},
	"calabaza": {"water": "ambas", "event": "halloween", "name": "Calabaza encantada", "kind": "ornament", "price": 300, "cur": "coins", "level": 1, "fx": {"happy": 6.0}, "desc": "Brilla por dentro. Solo durante Halloween."},
	"arbol_coral": {"water": "ambas", "event": "navidad", "name": "Árbol de coral", "kind": "ornament", "price": 300, "cur": "coins", "level": 1, "fx": {"happy": 6.0}, "desc": "Coral nevado con lucecitas. Solo en Navidad."},
	"cerezo": {"water": "ambas", "event": "primavera", "name": "Bonsái de cerezo", "kind": "ornament", "price": 300, "cur": "coins", "level": 1, "fx": {"happy": 6.0}, "desc": "Pétalos rosas bajo el agua. Solo en primavera."},
	"castillo_arena": {"water": "ambas", "event": "verano", "name": "Castillo de arena", "kind": "ornament", "price": 300, "cur": "coins", "level": 1, "fx": {"happy": 6.0}, "desc": "Con banderita y conchas. Solo en verano."},
	"coral": {"water": "ambas", "name": "Coral de fantasía", "kind": "ornament", "price": 25, "cur": "pearls", "level": 4, "fx": {"happy": 8.0, "mutation": 0.03}, "desc": "Brilla en la penumbra: +3% de mutaciones."},
}
const DECOR_ORDER := ["vallisneria", "helecho", "planta_rosa", "rocas", "cofre", "musgo", "anubias", "tronco", "cueva", "rotala", "castillo", "anfora", "coral", "barco",
	"caulerpa", "anemona", "roca_viva", "coral_blando", "coral_cerebro", "calabaza", "arbol_coral", "cerezo", "castillo_arena"]

const SUBSTRATES := {
	"grava": {"water": "dulce", "name": "Grava de río", "price": 0, "cur": "coins", "level": 1, "cols": ["8c7b6a", "b9a894", "5e5246"], "pebble": 1.0, "happy": 0.0},
	"arena": {"water": "ambas", "name": "Arena dorada", "price": 150, "cur": "coins", "level": 1, "cols": ["e3c48a", "f6e3b8", "c19f62"], "pebble": 0.0, "happy": 1.0},
	"pastel": {"water": "dulce", "name": "Grava pastel", "price": 300, "cur": "coins", "level": 2, "cols": ["f6a6c1", "a8d8ff", "fff1a8"], "pebble": 1.0, "happy": 2.0},
	"negra": {"water": "ambas", "name": "Arena volcánica", "price": 12, "cur": "pearls", "level": 2, "cols": ["2a2c33", "4a4e5a", "17181c"], "pebble": 0.15, "happy": 2.0},
	"aragonita": {"water": "salada", "name": "Arena de aragonita", "price": 120, "cur": "coins", "level": 1, "cols": ["efe6d8", "fffaf2", "d8c9b4"], "pebble": 0.2, "happy": 2.0},
	"tierra": {"water": "dulce", "name": "Tierra nutritiva", "price": 400, "cur": "coins", "level": 3, "cols": ["5a4634", "7a6048", "3a2c20"], "pebble": 0.3, "happy": 1.0, "plants": 1.0},
}
const SUBSTRATE_ORDER := ["grava", "arena", "pastel", "negra", "tierra", "aragonita"]

## nutrition: hambre que quita · grow: multiplicador de crecimiento · happy: felicidad por bocado
const FOODS := {
	"escamas": {"name": "Escamas", "price": 0, "pack": 0, "level": 1, "nutrition": 20.0, "grow": 1.0, "happy": 0.5, "col": "ff8a3d", "desc": "Básico e infinito. Flotan y caen despacio."},
	"granulos": {"name": "Gránulos de fondo", "price": 60, "pack": 20, "level": 1, "nutrition": 28.0, "grow": 1.7, "happy": 1.5, "col": "a0663a", "desc": "Se hunden hasta el fondo. Crecen un 70% más rápido."},
	"nori": {"name": "Alga nori", "price": 70, "pack": 12, "level": 1, "nutrition": 26.0, "grow": 1.2, "happy": 2.0, "col": "3f7a3a", "desc": "Para herbívoros: cirujanos, ángel llama, molly."},
	"artemia": {"name": "Artemia", "price": 90, "pack": 12, "level": 2, "nutrition": 24.0, "grow": 1.2, "happy": 6.0, "col": "ff6f8e", "desc": "¡Su manjar favorito! Mucha felicidad."},
}
const FOOD_ORDER := ["escamas", "granulos", "artemia", "nori"]

## Productos para el agua (se compran en la tienda y se usan desde la estantería).
const PRODUCTS := {
	"ph_up": {"name": "Regulador pH+", "short": "pH+", "price": 80, "pack": 5, "level": 1, "col": "3f8cff", "desc": "Sube el pH unas 3 décimas. El efecto se va perdiendo en un día."},
	"ph_down": {"name": "Regulador pH−", "short": "pH−", "price": 80, "pack": 5, "level": 1, "col": "ff7a3a", "desc": "Baja el pH unas 3 décimas. Ideal para tetras y discos."},
	"oxigeno": {"name": "Pastillas de oxígeno", "short": "O₂", "price": 60, "pack": 4, "level": 1, "col": "45b8f0", "desc": "Liberan oxígeno durante 12 horas. Para peceras sin aireador."},
	"sal": {"water": "salada", "name": "Sal marina", "short": "Sal", "price": 70, "pack": 5, "level": 1, "col": "c9d6e3", "desc": "Sube la salinidad 2 milésimas (si repusiste demasiada agua dulce)."},
	"antialgas": {"name": "Antialgas", "short": "Alg", "price": 120, "pack": 4, "level": 2, "col": "3fbf6a", "desc": "Disuelve parte de las algas y frena su crecimiento 12 horas."},
	"med_ich": {"name": "Tratamiento punto blanco", "short": "Ich", "price": 110, "pack": 3, "level": 1, "col": "8a6cff", "desc": "Cura el punto blanco en unas horas. Trata a toda la pecera."},
	"med_hongos": {"name": "Antifúngico", "short": "Hon", "price": 100, "pack": 3, "level": 1, "col": "ffb020", "desc": "Cura los hongos (manchas algodonosas) en unas horas."},
	"med_bact": {"name": "Antibacteriano", "short": "Bac", "price": 100, "pack": 3, "level": 1, "col": "e84a6a", "desc": "Cura la podredumbre de aletas en unas horas."},
}
const PRODUCT_ORDER := ["ph_up", "ph_down", "oxigeno", "sal", "antialgas", "med_ich", "med_hongos", "med_bact"]

## Enfermedades: aparecen con agua sucia, parámetros malos o estrés (no en Relax). med: producto que la cura.
const DISEASES := {
	"ich": {"name": "Punto blanco", "med": "med_ich", "spread": true, "desc": "Puntitos blancos como sal. Es contagioso."},
	"hongos": {"name": "Hongos", "med": "med_hongos", "spread": false, "desc": "Manchas blancas algodonosas."},
	"aletas": {"name": "Podredumbre de aletas", "med": "med_bact", "spread": false, "desc": "Aletas deshilachadas; suele venir del estrés o del agua sucia."},
}

## Racha diaria (días 1..7, luego se repite). kind: coins / pearls / food:<id> / egg (huevo misterioso).
const STREAK := [
	{"kind": "coins", "n": 60, "text": "60 monedas"}, {"kind": "food:granulos", "n": 10, "text": "10 gránulos"},
	{"kind": "pearls", "n": 2, "text": "2 perlas"}, {"kind": "coins", "n": 150, "text": "150 monedas"},
	{"kind": "food:artemia", "n": 10, "text": "10 artemias"}, {"kind": "pearls", "n": 4, "text": "4 perlas"},
	{"kind": "egg", "n": 1, "text": "Huevo misterioso"},
]

## Eventos de temporada (fechas [mes, día], ambos incluidos). Traen una decoración y un pez de edición limitada.
const EVENTS := [
	{"id": "halloween", "name": "Halloween", "from": [10, 15], "to": [11, 2], "decor": "calabaza",
		"fish": {"dulce": ["betta", "Betta Calabaza", ["ff7a1a", "1a1414", "ff8a2a"]], "salada": ["payaso", "Payaso Calabaza", ["2a2626", "ff7a1a", "2e2a2a"]]}},
	{"id": "navidad", "name": "Navidad", "from": [12, 10], "to": [1, 6], "decor": "arbol_coral",
		"fish": {"dulce": ["guppy", "Guppy Navidad", ["f5f5f5", "e8202a", "2a9a4a"]], "salada": ["gramma", "Gramma Navidad", ["e8202a", "2a9a4a", "e8202a"]]}},
	{"id": "primavera", "name": "Primavera", "from": [3, 20], "to": [4, 30], "decor": "cerezo",
		"fish": {"dulce": ["goldfish", "Dorado Sakura", ["ffd0e0", "ff6fa8", "ffe0ea"]], "salada": ["cirujano_amarillo", "Cirujano Sakura", ["ffb8d8", "ffffff", "ffb8d8"]]}},
	{"id": "verano", "name": "Verano", "from": [7, 1], "to": [8, 31], "decor": "castillo_arena",
		"fish": {"dulce": ["neon", "Neón Tropical", ["40e0d0", "ffd23f", "ff6040"]], "salada": ["damisela", "Damisela Sol", ["ff8a1f", "ffd23f", "ff8a1f"]]}},
]
const EVENT_FISH_PRICE := 3.0         ## × precio de la especie

## Más peceras: precio y nivel de la 2ª y 3ª.
const TANK_SLOTS := [{"price": 0, "level": 1}, {"price": 1500, "level": 4}, {"price": 6000, "level": 7}]

## Pedidos de clientes.
const CUSTOMERS := ["Sra. Pilar", "Don Andrés", "Lucía (8 años)", "Acuario Municipal", "Tienda Coral Azul", "Hotel Marina",
	"Dr. Ruiz", "Abuelo Paco", "Colegio Las Dunas", "Clínica Sonrisa", "Café La Pecera", "Marta, criadora", "Restaurante Neptuno"]
const COLOR_NAMES := ["rojo", "naranja", "amarillo", "verde", "azul", "morado", "rosa"]

## Misiones de historia: una activa cada vez, sirven de tutorial.
## type se evalúa en Game._story_progress()
const STORY := [
	{"text": "Da de comer a tus peces", "type": "feeds", "target": 1, "coins": 30, "pearls": 0, "xp": 15},
	{"text": "Limpia las algas del cristal", "type": "cleaned", "target": 10, "coins": 40, "pearls": 0, "xp": 15},
	{"text": "Aspira el fondo con el sifón", "type": "vacuumed", "target": 3, "coins": 40, "pearls": 0, "xp": 15},
	{"text": "Instala un filtro", "type": "filter", "target": 1, "coins": 40, "pearls": 0, "xp": 20},
	{"text": "Instala un calentador", "type": "heater", "target": 1, "coins": 0, "pearls": 2, "xp": 25},
	{"text": "Haz el mantenimiento de un aparato", "type": "maint", "target": 1, "coins": 0, "pearls": 2, "xp": 20},
	{"text": "Cría tu primer pez", "type": "bred", "target": 1, "coins": 0, "pearls": 3, "xp": 30},
	{"text": "Decora con una planta", "type": "plant", "target": 1, "coins": 60, "pearls": 0, "xp": 20},
	{"text": "Vende un pez", "type": "sold", "target": 1, "coins": 80, "pearls": 0, "xp": 20},
	{"text": "Muda tus peces a la Nano 20 L", "type": "tank", "target": 1, "coins": 0, "pearls": 3, "xp": 30},
	{"text": "Alcanza el nivel 3", "type": "level", "target": 3, "coins": 0, "pearls": 3, "xp": 0},
	{"text": "Muda tus peces a la pecera de 60 L", "type": "tank", "target": 2, "coins": 0, "pearls": 5, "xp": 40},
	{"text": "Consigue un pez con mutación", "type": "mutation", "target": 1, "coins": 0, "pearls": 5, "xp": 50},
	{"text": "Ten 8 peces a la vez", "type": "fishcount", "target": 8, "coins": 300, "pearls": 0, "xp": 40},
	{"text": "Cría un pez Raro o mejor", "type": "rarity", "target": 2, "coins": 0, "pearls": 6, "xp": 60},
	{"text": "Alcanza el nivel 6", "type": "level", "target": 6, "coins": 0, "pearls": 5, "xp": 0},
	{"text": "Consigue la pecera de 200 L", "type": "tank", "target": 3, "coins": 0, "pearls": 8, "xp": 80},
	{"text": "Descubre 25 variantes", "type": "variants", "target": 25, "coins": 0, "pearls": 8, "xp": 80},
	{"text": "Cría un pez Legendario", "type": "rarity", "target": 4, "coins": 0, "pearls": 15, "xp": 150},
	{"text": "Consigue el acuario Monumental", "type": "tank", "target": 4, "coins": 0, "pearls": 20, "xp": 200},
]

## Diarias: se eligen 3 al día de forma determinista por fecha.
const DAILY := [
	{"id": "feed", "text": "Alimenta a tus peces %d veces", "min": 4, "max": 8, "coins": 60, "xp": 20},
	{"id": "clean", "text": "Limpia %d trozos de alga", "min": 15, "max": 35, "coins": 70, "xp": 20},
	{"id": "bred", "text": "Cría %d peces", "min": 1, "max": 2, "coins": 90, "xp": 30},
	{"id": "hatched", "text": "Haz eclosionar %d huevos", "min": 1, "max": 3, "coins": 80, "xp": 25},
	{"id": "sold", "text": "Vende %d peces", "min": 1, "max": 3, "coins": 70, "xp": 20},
	{"id": "earned", "text": "Gana %d monedas vendiendo", "min": 40, "max": 150, "coins": 80, "xp": 25},
	{"id": "artemia", "text": "Da artemia %d veces", "min": 2, "max": 4, "coins": 60, "xp": 20},
	{"id": "bought", "text": "Compra %d cosas en la tienda", "min": 1, "max": 2, "coins": 50, "xp": 15},
	{"id": "maint", "text": "Haz %d mantenimientos del equipo", "min": 1, "max": 3, "coins": 70, "xp": 20},
	{"id": "orders", "text": "Entrega %d pedido(s) a clientes", "min": 1, "max": 2, "coins": 90, "xp": 30},
	{"id": "pruned", "text": "Poda %d planta(s)", "min": 1, "max": 1, "coins": 50, "xp": 15},
	{"id": "vacuumed", "text": "Aspira el fondo %d veces", "min": 2, "max": 4, "coins": 50, "xp": 15},
]

const NAMES := ["Burbuja", "Coral", "Perla", "Chispa", "Lola", "Rayo", "Canela", "Miel", "Tofu", "Kiwi",
	"Mango", "Nube", "Luna", "Sol", "Pipo", "Bombón", "Gominola", "Trufa", "Azul", "Brisa", "Copito", "Duna",
	"Estrella", "Flan", "Galleta", "Jazmín", "Lima", "Menta", "Nácar", "Ola", "Pompa", "Quino", "Rubí",
	"Salsa", "Tango", "Uva", "Vainilla", "Yuyu", "Zafiro", "Almendra", "Bruma", "Churro", "Dulce", "Eco",
	"Fresa", "Gamba", "Hoja", "Iris", "Jade", "Limón", "Mora", "Nemi", "Opal", "Pixel", "Quesito", "Remo"]


## Altura del terreno: nº de puntos de control (el jugador los sube o baja en Decorar → Arena).
const TERRAIN_N := 14
const FLOOR_N := 24                   ## columnas de suciedad del fondo (se aspiran con el sifón)
const TERRAIN_MIN := -0.05            ## fracción del alto de la pecera (cavar)
const TERRAIN_MAX := 0.26             ## (montaña)


static func color(hex: String) -> Color:
	return Color.html(hex)
