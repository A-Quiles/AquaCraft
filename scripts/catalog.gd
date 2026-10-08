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
const SPECIES := {
	"guppy": {
		"name": "Guppy", "water": "dulce", "desc": "Pequeño y alegre, con una cola en delta enorme y de mil colores.",
		"price": 15, "level": 1, "temp": [21.0, 28.0], "ph": [6.8, 8.0], "load": 0.6,
		"incubate": 180, "grow": 900, "speed": 62.0, "zone": "mid",
		"shape": {"len": 0.36, "ht": 0.15, "hb": 0.15, "peak": 0.6, "kf": 0.6, "kr": 0.5, "kb": 0.45, "ped": 0.45,
			"tail": 5, "tl": 0.66, "th": 0.4, "d": [0.12, 0.42, 0.16, 0.6], "dp": 0.8, "a": [0.2, 0.36, 0.06, 0.3], "eye": 0.82, "aspect": 1.75, "px": 74.0},
		"patterns": [1, 2, 7, 6],
		"presets": [["d8dde3", "ff5a36", "ff7a3d"], ["dfe4ea", "3fa3ff", "4cb8ff"], ["e8e2d8", "ffd23f", "ffbf1f"],
			["e2dde8", "ff4fa3", "ff6fb5"], ["dfe6e0", "38d39f", "3ad6b0"], ["3a3d4a", "ff3b3b", "ff4a4a"]],
	},
	"neon": {
		"name": "Tetra neón", "water": "dulce", "desc": "Torpedo diminuto con una franja azul que brilla como un letrero.",
		"price": 20, "level": 1, "temp": [21.0, 27.0], "ph": [5.8, 7.3], "load": 0.5,
		"incubate": 300, "grow": 1200, "speed": 72.0, "zone": "mid",
		"shape": {"len": 0.62, "ht": 0.19, "hb": 0.17, "peak": 0.6, "kf": 0.7, "kr": 0.6, "kb": 0.5, "ped": 0.35,
			"tail": 1, "tl": 0.3, "th": 0.2, "d": [0.5, 0.64, 0.12, 0.3], "dp": 1.2, "a": [0.18, 0.42, 0.08, 0.2], "adip": 1.0, "eye": 0.84, "aspect": 2.3, "px": 58.0},
		"patterns": [4],
		"presets": [["9fb3c8", "25d0ff", "ff4058"], ["b8c2cc", "4cf3c9", "ff5a3c"], ["a7b0d6", "6f7bff", "ff4f8a"]],
	},
	"corydoras": {
		"name": "Corydoras", "water": "dulce", "desc": "Acorazado, de vientre plano y con bigotitos para rebuscar en el fondo.",
		"price": 35, "level": 2, "temp": [21.0, 27.0], "ph": [6.0, 7.8], "load": 0.7,
		"incubate": 420, "grow": 1500, "speed": 42.0, "zone": "bottom",
		"shape": {"len": 0.6, "ht": 0.3, "hb": 0.13, "peak": 0.62, "kf": 0.85, "kr": 0.6, "kb": 0.15, "ped": 0.42,
			"tail": 1, "tl": 0.3, "th": 0.24, "d": [0.5, 0.7, 0.3, 0.25], "dp": 1.4, "a": [0.15, 0.3, 0.08, 0.2], "adip": 1.0, "barb": 1.0, "eye": 0.8, "aspect": 2.0, "px": 66.0},
		"patterns": [2],
		"presets": [["c9a77c", "5a4632", "d6bf9e"], ["e8d3b0", "4a3a2a", "e8dcc4"], ["8fa37b", "3b4a2a", "a8b894"]],
	},
	"goldfish": {
		"name": "Pez dorado", "water": "dulce", "desc": "Variedad cola de velo: cuerpo de huevo y doble cola. Agua fría.",
		"price": 30, "level": 2, "temp": [17.0, 24.0], "ph": [6.8, 8.0], "load": 1.4,
		"incubate": 360, "grow": 1800, "speed": 40.0, "zone": "mid",
		"shape": {"len": 0.46, "ht": 0.37, "hb": 0.35, "peak": 0.5, "kf": 0.45, "kr": 0.6, "kb": 0.45, "ped": 0.32,
			"tail": 2, "tl": 0.62, "th": 0.44, "d": [0.3, 0.68, 0.22, 0.3], "dp": 0.7, "a": [0.12, 0.3, 0.12, 0.3], "eye": 0.8, "aspect": 1.5, "px": 110.0},
		"patterns": [0, 6, 1],
		"presets": [["ff8a1f", "fff4e0", "ff9a3a"], ["ffcc33", "ff6a1a", "ffd04d"], ["ff4a2e", "ffffff", "ff5a40"], ["fff3e6", "ff5a26", "fff1e0"]],
	},
	"molly": {
		"name": "Molly velero", "water": "dulce", "desc": "Su enorme aleta dorsal es una vela. Tranquilo y resistente.",
		"price": 40, "level": 3, "temp": [22.0, 28.0], "ph": [7.0, 8.2], "load": 1.0,
		"incubate": 420, "grow": 1800, "speed": 46.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.26, "hb": 0.24, "peak": 0.55, "kf": 0.55, "kr": 0.5, "kb": 0.5, "ped": 0.55,
			"tail": 0, "tl": 0.38, "th": 0.32, "d": [0.12, 0.66, 0.3, 0.35], "dp": 0.7, "a": [0.25, 0.42, 0.09, 0.3], "eye": 0.83, "aspect": 1.7, "px": 88.0},
		"patterns": [0, 6, 1],
		"presets": [["1d1f26", "3a3d4a", "2a2d38"], ["f2b134", "ffffff", "f4c04f"], ["f5f7fa", "1d1f26", "eceff4"], ["ff8c42", "1d1f26", "ff9a55"]],
	},
	"betta": {
		"name": "Betta", "water": "dulce", "desc": "El pez luchador: aletas de seda que caen como un vestido.",
		"price": 60, "level": 3, "temp": [24.0, 29.0], "ph": [6.0, 7.6], "load": 1.0,
		"incubate": 600, "grow": 2400, "speed": 34.0, "zone": "top",
		"shape": {"len": 0.42, "ht": 0.18, "hb": 0.2, "peak": 0.55, "kf": 0.6, "kr": 0.45, "kb": 0.45, "ped": 0.6,
			"tail": 3, "tl": 0.62, "th": 0.52, "d": [0.08, 0.45, 0.3, 0.9], "dp": 0.7, "a": [0.0, 0.68, 0.36, 0.7], "eye": 0.84, "aspect": 1.35, "px": 112.0},
		"patterns": [0, 1, 7],
		"presets": [["2a4dff", "ff2f6d", "2f56ff"], ["d6142e", "2a1a5e", "e0183a"], ["7b2cff", "ff4fcf", "8a3cff"], ["101a4a", "35e0ff", "1a3a8a"], ["f5f2ff", "ff9ec7", "f5f0ff"]],
	},
	"rainbow": {
		"name": "Pez arcoíris", "water": "dulce", "desc": "Lomo alto, hocico fino y dos dorsales. Medio azul, medio fuego.",
		"price": 75, "level": 4, "temp": [23.0, 28.0], "ph": [6.8, 8.0], "load": 1.2,
		"incubate": 720, "grow": 2700, "speed": 74.0, "zone": "mid",
		"shape": {"len": 0.62, "ht": 0.38, "hb": 0.24, "peak": 0.5, "kf": 1.0, "kr": 0.55, "kb": 0.5, "ped": 0.32,
			"tail": 1, "tl": 0.32, "th": 0.27, "d": [0.32, 0.52, 0.16, 0.4], "dp": 0.9, "d2": 0.12, "a": [0.05, 0.55, 0.13, 0.4], "eye": 0.86, "aspect": 1.75, "px": 98.0},
		"patterns": [1],
		"presets": [["2d5bd8", "ff8c1a", "4a73e0"], ["2fd1c4", "ffd23f", "3ad6c8"], ["7a3cff", "ff5aa5", "8a50ff"]],
	},
	"angelfish": {
		"name": "Pez ángel", "water": "dulce", "desc": "Cuerpo de diamante, aletas como velas y largos filamentos.",
		"price": 120, "level": 6, "temp": [24.0, 29.0], "ph": [6.0, 7.5], "load": 1.6,
		"incubate": 1200, "grow": 3600, "speed": 34.0, "zone": "mid",
		"shape": {"len": 0.36, "ht": 0.3, "hb": 0.3, "peak": 0.55, "kf": 0.7, "kr": 0.75, "kb": 0.75, "ped": 0.3,
			"tail": 4, "tl": 0.42, "th": 0.36, "d": [0.12, 0.7, 0.62, 1.2], "dp": 1.3, "a": [0.12, 0.68, 0.62, 1.2], "thr": 0.55, "eye": 0.8, "aspect": 0.95, "px": 124.0},
		"patterns": [3, 0, 6],
		"presets": [["dfe5ea", "2a2f3a", "e6ebef"], ["ffd23f", "ff8c1a", "ffe07a"], ["2a2f3a", "4a5060", "3a3f4a"], ["f0f2f5", "ff7a3a", "f5f6f8"]],
	},
	"discus": {
		"name": "Disco", "water": "dulce", "desc": "Un disco perfecto con aletas como un fleco. El rey del agua dulce.",
		"price": 260, "level": 8, "temp": [27.0, 31.0], "ph": [5.8, 7.0], "load": 1.8,
		"incubate": 1800, "grow": 5400, "speed": 30.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.52, "hb": 0.52, "peak": 0.5, "kf": 0.42, "kr": 0.42, "kb": 0.42, "ped": 0.26,
			"tail": 6, "tl": 0.24, "th": 0.24, "d": [0.08, 0.8, 0.12, 0.1], "dp": 0.4, "a": [0.08, 0.74, 0.11, 0.1], "eye": 0.8, "aspect": 1.2, "px": 118.0},
		"patterns": [3, 6],
		"presets": [["ff3d2e", "2fd6ff", "ff5a40"], ["2fd6ff", "ff7a2e", "3fdcff"], ["ffcf3f", "ff3d2e", "ffd85a"], ["ff6fa8", "ffd0e6", "ff80b5"]],
	},
	# ───── Agua salada ─────
	"payaso": {
		"name": "Pez payaso", "water": "salada", "desc": "Naranja con tres bandas blancas. Feliz si tiene una anémona.",
		"price": 45, "level": 1, "temp": [24.0, 28.0], "ph": [7.9, 8.5], "load": 0.8,
		"incubate": 600, "grow": 2400, "speed": 44.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.27, "hb": 0.24, "peak": 0.55, "kf": 0.5, "kr": 0.55, "kb": 0.5, "ped": 0.5,
			"tail": 6, "tl": 0.3, "th": 0.26, "d": [0.12, 0.74, 0.14, 0.2], "dp": 0.55, "a": [0.12, 0.4, 0.13, 0.2], "eye": 0.82, "aspect": 1.8, "px": 74.0},
		"patterns": [5],
		"presets": [["ff7a1a", "ffffff", "ff8a2a"], ["ff5a14", "ffffff", "ff6a24"], ["2a2626", "ffffff", "2e2a2a"]],
	},
	"gramma": {
		"name": "Gramma loreto", "water": "salada", "desc": "Mitad violeta, mitad amarillo. Pequeño y muy pacífico.",
		"price": 60, "level": 2, "temp": [24.0, 27.0], "ph": [7.9, 8.5], "load": 0.6,
		"incubate": 540, "grow": 2100, "speed": 50.0, "zone": "mid",
		"shape": {"len": 0.58, "ht": 0.21, "hb": 0.19, "peak": 0.6, "kf": 0.6, "kr": 0.5, "kb": 0.5, "ped": 0.45,
			"tail": 0, "tl": 0.32, "th": 0.24, "d": [0.1, 0.74, 0.1, 0.2], "dp": 0.6, "a": [0.1, 0.42, 0.1, 0.2], "eye": 0.84, "aspect": 2.1, "px": 66.0},
		"patterns": [7],
		"presets": [["8a3cff", "ffd23f", "ffd23f"], ["b13cff", "ffc21f", "ffc21f"]],
	},
	"gobio_fuego": {
		"name": "Gobio de fuego", "water": "salada", "desc": "Esbelto, con una dorsal en forma de lanza y cola de fuego.",
		"price": 80, "level": 3, "temp": [24.0, 27.0], "ph": [7.9, 8.5], "load": 0.5,
		"incubate": 600, "grow": 2400, "speed": 56.0, "zone": "bottom",
		"shape": {"len": 0.62, "ht": 0.15, "hb": 0.14, "peak": 0.6, "kf": 0.6, "kr": 0.45, "kb": 0.45, "ped": 0.55,
			"tail": 0, "tl": 0.3, "th": 0.2, "d": [0.58, 0.78, 0.5, 0.35], "dp": 2.0, "d2": 0.09, "a": [0.1, 0.5, 0.08, 0.2], "eye": 0.84, "aspect": 1.7, "px": 72.0},
		"patterns": [1],
		"presets": [["fff6ee", "ff3d1f", "ff5a2a"], ["fff0f6", "c63cff", "ff3d7a"]],
	},
	"cirujano_azul": {
		"name": "Cirujano azul", "water": "salada", "desc": "Azul eléctrico con su dibujo negro de paleta y cola amarilla.",
		"price": 140, "level": 3, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.4,
		"incubate": 1200, "grow": 3600, "speed": 52.0, "zone": "mid",
		"shape": {"len": 0.56, "ht": 0.36, "hb": 0.34, "peak": 0.52, "kf": 0.9, "kr": 0.55, "kb": 0.55, "ped": 0.25,
			"tail": 4, "tl": 0.34, "th": 0.34, "d": [0.1, 0.8, 0.1, 0.15], "dp": 0.5, "a": [0.1, 0.62, 0.09, 0.15], "eye": 0.8, "aspect": 1.55, "px": 102.0},
		"patterns": [8],
		"presets": [["1f63e8", "141a2e", "ffd23f"], ["2a7bff", "121a33", "ffc81f"]],
	},
	"cirujano_amarillo": {
		"name": "Cirujano amarillo", "water": "salada", "desc": "Un disco amarillo limón con hocico de trompeta.",
		"price": 120, "level": 4, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.3,
		"incubate": 1200, "grow": 3600, "speed": 48.0, "zone": "mid",
		"shape": {"len": 0.48, "ht": 0.48, "hb": 0.46, "peak": 0.5, "kf": 1.15, "kr": 0.55, "kb": 0.55, "ped": 0.3,
			"tail": 4, "tl": 0.32, "th": 0.32, "d": [0.08, 0.86, 0.26, 0.25], "dp": 0.6, "a": [0.08, 0.72, 0.24, 0.25], "eye": 0.76, "aspect": 1.2, "px": 102.0},
		"patterns": [0],
		"presets": [["ffd400", "fff2a8", "ffd400"], ["ffe11f", "ffffff", "ffe11f"]],
	},
	"angel_llama": {
		"name": "Ángel llama", "water": "salada", "desc": "Rojo fuego con barras negras y aletas ribeteadas de azul.",
		"price": 180, "level": 5, "temp": [24.0, 27.0], "ph": [8.0, 8.4], "load": 1.0,
		"incubate": 1500, "grow": 4200, "speed": 40.0, "zone": "mid",
		"shape": {"len": 0.5, "ht": 0.32, "hb": 0.31, "peak": 0.55, "kf": 0.6, "kr": 0.6, "kb": 0.6, "ped": 0.45,
			"tail": 6, "tl": 0.3, "th": 0.3, "d": [0.08, 0.72, 0.22, 0.55], "dp": 0.9, "a": [0.08, 0.5, 0.2, 0.55], "eye": 0.82, "aspect": 1.55, "px": 86.0},
		"patterns": [3],
		"presets": [["ff3b1f", "1a1414", "3a5bff"], ["ff5a14", "1f1515", "2f6bff"]],
	},
}

const SPECIES_ORDER := ["guppy", "neon", "corydoras", "goldfish", "molly", "betta", "rainbow", "angelfish", "discus",
	"payaso", "gramma", "gobio_fuego", "cirujano_azul", "cirujano_amarillo", "angel_llama"]

const PATTERN_NAMES := ["Liso", "Degradado", "Moteado", "Barras", "Franja neón", "Bandas", "Mármol", "Bicolor", "Paleta"]

const RARITY_NAMES := ["Común", "Poco común", "Raro", "Épico", "Legendario"]
const RARITY_COLORS := ["9aa7b5", "4fc27a", "3fa3ff", "b36bff", "ffb020"]
const RARITY_MULT := [1.0, 1.8, 3.5, 7.0, 16.0]

const TANKS := [
	{"id": "nano", "name": "Nano 20 L", "cap": 5, "o2": 4.0, "slots": 5, "price": 0, "level": 1,
		"desc": "Tu primera pecera. Pequeñita pero acogedora."},
	{"id": "comunitario", "name": "Comunitario 60 L", "cap": 10, "o2": 8.0, "slots": 8, "price": 900, "level": 2,
		"desc": "Espacio para una comunidad animada."},
	{"id": "panoramico", "name": "Panorámico 200 L", "cap": 18, "o2": 14.0, "slots": 11, "price": 4000, "level": 5,
		"desc": "Cristal panorámico para paisajes de verdad."},
	{"id": "monumental", "name": "Monumental 1000 L", "cap": 30, "o2": 24.0, "slots": 15, "price": 16000, "level": 9,
		"desc": "Un muro de agua. El sueño de todo acuarista."},
]

## slot: filter / heater / pump / light / thermo. Instalar uno sustituye al anterior del mismo hueco.
## wear: % de estado que pierde por hora (el filtro, más cuanto más carga de peces).
## maint: acción de mantenimiento que lo deja al 100%.
const EQUIPMENT := {
	"esponja": {"slot": "filter", "name": "Filtro de esponja", "price": 150, "level": 1, "eff": 0.35, "wear": 2.5, "maint": "Escurrir la esponja", "desc": "Algas un 35% más lentas. Se ensucia rápido."},
	"mochila": {"slot": "filter", "name": "Filtro de mochila", "price": 700, "level": 3, "eff": 0.55, "wear": 1.6, "maint": "Cambiar el cartucho", "desc": "Algas un 55% más lentas."},
	"canister": {"slot": "filter", "name": "Filtro canister", "price": 2400, "level": 6, "eff": 0.75, "wear": 0.9, "maint": "Limpiar los cestillos", "desc": "Algas un 75% más lentas. Casi no da guerra."},
	"calentador_fijo": {"slot": "heater", "name": "Calentador fijo", "price": 90, "level": 1, "fixed": 25.0, "wear": 0.6, "maint": "Quitar la cal", "desc": "Mantiene el agua a 25 °C."},
	"calentador": {"slot": "heater", "name": "Calentador con termostato", "price": 220, "level": 2, "wear": 0.5, "maint": "Quitar la cal", "desc": "Elige la temperatura del agua (18–31 °C)."},
	"difusor": {"slot": "pump", "name": "Piedra difusora", "price": 120, "level": 1, "o2": 3.0, "wear": 1.4, "maint": "Cambiar la piedra", "desc": "+3 de oxígeno y burbujitas."},
	"bomba": {"slot": "pump", "name": "Bomba de aire doble", "price": 600, "level": 3, "o2": 6.0, "wear": 1.0, "maint": "Revisar la membrana", "desc": "+6 de oxígeno."},
	"circulacion": {"slot": "pump", "name": "Bomba de circulación", "price": 2000, "level": 5, "o2": 10.0, "wear": 0.8, "maint": "Limpiar el rotor", "desc": "+10 de oxígeno."},
	"led_pro": {"slot": "light", "name": "Pantalla LED Pro", "price": 500, "level": 3, "happy": 6.0, "wear": 0.7, "maint": "Limpiar la tapa", "desc": "Luz brillante: +felicidad y plantas más vivas."},
	"led_plantada": {"slot": "light", "name": "LED plantada RGB", "price": 1400, "level": 6, "happy": 10.0, "wear": 0.6, "maint": "Limpiar la tapa", "desc": "Espectro completo: colores intensos y mucha felicidad."},
	"skimmer": {"slot": "filter", "water": "salada", "name": "Skimmer (desnatador)", "price": 1500, "level": 3, "eff": 0.7, "wear": 1.2, "maint": "Vaciar el vaso colector", "desc": "El filtro estrella del marino: algas un 70% más lentas."},
	"ato": {"slot": "ato", "water": "salada", "name": "Reposición automática", "price": 700, "level": 2, "wear": 1.0, "maint": "Rellenar el depósito", "desc": "Repone el agua evaporada: la salinidad deja de subir."},
	"tira": {"slot": "thermo", "name": "Termómetro adhesivo", "price": 30, "level": 1, "wear": 0.0, "desc": "Muestra la temperatura en grados enteros."},
	"digital": {"slot": "thermo", "name": "Termómetro digital", "price": 180, "level": 2, "wear": 0.5, "maint": "Cambiar la pila", "desc": "Décimas de grado y alarma si tus peces pasan frío o calor."},
}
const EQUIPMENT_ORDER := ["esponja", "mochila", "canister", "skimmer", "calentador_fijo", "calentador", "difusor", "bomba", "circulacion",
	"led_pro", "led_plantada", "tira", "digital", "ato"]
const SLOT_NAMES := {"filter": "Filtro", "heater": "Calentador", "pump": "Aireador", "light": "Iluminación", "thermo": "Termómetro", "ato": "Reposición"}

## Modos de juego. algae/wear/hunger/evap: multiplicadores · tol: margen sobre los rangos ideales
## (99 = da igual) · death: los peces pueden morir · room_var: la habitación se enfría de noche.
const MODES := {
	"basico": {"name": "Relax", "desc": "Sin algas, sin desgaste y sin parámetros del agua. Solo dales de comer, cría y decora.",
		"algae": 0.0, "wear": 0.0, "hunger": 0.6, "evap": 0.0, "tol": 99.0, "death": false, "room_var": false, "hunger_hurts": false},
	"normal": {"name": "Normal", "desc": "Cuidados sencillos: limpia, mantén el equipo y vigila temperatura y pH. Los peces no mueren.",
		"algae": 1.0, "wear": 1.0, "hunger": 1.0, "evap": 1.0, "tol": 1.0, "death": false, "room_var": false, "hunger_hurts": true},
	"realista": {"name": "Realista", "desc": "Acuariofilia de verdad: márgenes estrictos, la habitación se enfría de noche, el equipo se gasta antes y los peces pueden morir.",
		"algae": 1.5, "wear": 1.6, "hunger": 1.25, "evap": 2.0, "tol": 0.0, "death": true, "room_var": true, "hunger_hurts": true},
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
	"coral": {"water": "ambas", "name": "Coral de fantasía", "kind": "ornament", "price": 25, "cur": "pearls", "level": 4, "fx": {"happy": 8.0, "mutation": 0.03}, "desc": "Brilla en la penumbra: +3% de mutaciones."},
}
const DECOR_ORDER := ["vallisneria", "helecho", "planta_rosa", "rocas", "cofre", "musgo", "anubias", "tronco", "cueva", "rotala", "castillo", "anfora", "coral", "barco",
	"caulerpa", "anemona", "roca_viva", "coral_blando", "coral_cerebro"]

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
	"escamas": {"name": "Escamas", "price": 0, "pack": 0, "level": 1, "nutrition": 20.0, "grow": 1.0, "happy": 0.5, "col": "ff8a3d", "desc": "Básico e infinito."},
	"granulos": {"name": "Gránulos premium", "price": 60, "pack": 20, "level": 1, "nutrition": 28.0, "grow": 1.7, "happy": 1.5, "col": "a0663a", "desc": "Crecen un 70% más rápido."},
	"artemia": {"name": "Artemia", "price": 90, "pack": 12, "level": 2, "nutrition": 24.0, "grow": 1.2, "happy": 6.0, "col": "ff6f8e", "desc": "¡Su manjar favorito! Mucha felicidad."},
}
const FOOD_ORDER := ["escamas", "granulos", "artemia"]

## Misiones de historia: una activa cada vez, sirven de tutorial.
## type se evalúa en Game._story_progress()
const STORY := [
	{"text": "Da de comer a tus peces", "type": "feeds", "target": 1, "coins": 30, "pearls": 0, "xp": 15},
	{"text": "Limpia las algas del cristal", "type": "cleaned", "target": 10, "coins": 40, "pearls": 0, "xp": 15},
	{"text": "Haz el mantenimiento del filtro", "type": "maint", "target": 1, "coins": 0, "pearls": 2, "xp": 20},
	{"text": "Cría tu primer pez", "type": "bred", "target": 1, "coins": 0, "pearls": 3, "xp": 30},
	{"text": "Decora con una planta", "type": "plant", "target": 1, "coins": 60, "pearls": 0, "xp": 20},
	{"text": "Vende un pez", "type": "sold", "target": 1, "coins": 80, "pearls": 0, "xp": 20},
	{"text": "Alcanza el nivel 3", "type": "level", "target": 3, "coins": 0, "pearls": 3, "xp": 0},
	{"text": "Instala un calentador", "type": "heater", "target": 1, "coins": 0, "pearls": 2, "xp": 25},
	{"text": "Muda tus peces a la pecera de 60 L", "type": "tank", "target": 1, "coins": 0, "pearls": 5, "xp": 40},
	{"text": "Consigue un pez con mutación", "type": "mutation", "target": 1, "coins": 0, "pearls": 5, "xp": 50},
	{"text": "Ten 8 peces a la vez", "type": "fishcount", "target": 8, "coins": 300, "pearls": 0, "xp": 40},
	{"text": "Cría un pez Raro o mejor", "type": "rarity", "target": 2, "coins": 0, "pearls": 6, "xp": 60},
	{"text": "Alcanza el nivel 6", "type": "level", "target": 6, "coins": 0, "pearls": 5, "xp": 0},
	{"text": "Consigue la pecera de 200 L", "type": "tank", "target": 2, "coins": 0, "pearls": 8, "xp": 80},
	{"text": "Descubre 25 variantes", "type": "variants", "target": 25, "coins": 0, "pearls": 8, "xp": 80},
	{"text": "Cría un pez Legendario", "type": "rarity", "target": 4, "coins": 0, "pearls": 15, "xp": 150},
	{"text": "Consigue el acuario Monumental", "type": "tank", "target": 3, "coins": 0, "pearls": 20, "xp": 200},
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
]

const NAMES := ["Burbuja", "Coral", "Perla", "Chispa", "Lola", "Rayo", "Canela", "Miel", "Tofu", "Kiwi",
	"Mango", "Nube", "Luna", "Sol", "Pipo", "Bombón", "Gominola", "Trufa", "Azul", "Brisa", "Copito", "Duna",
	"Estrella", "Flan", "Galleta", "Jazmín", "Lima", "Menta", "Nácar", "Ola", "Pompa", "Quino", "Rubí",
	"Salsa", "Tango", "Uva", "Vainilla", "Yuyu", "Zafiro", "Almendra", "Bruma", "Churro", "Dulce", "Eco",
	"Fresa", "Gamba", "Hoja", "Iris", "Jade", "Limón", "Mora", "Nemi", "Opal", "Pixel", "Quesito", "Remo"]


static func color(hex: String) -> Color:
	return Color.html(hex)
