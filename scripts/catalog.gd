class_name Catalog
extends RefCounted
## Datos estáticos del juego. Balancear aquí: precios, tiempos y desbloqueos.

## Forma (para el shader del pez):
##   len/h: semieje del cuerpo · tail: 0 abanico, 1 horquilla, 2 doble, 3 velo
##   tl/th: largo/alto de la cola · dor/ana: aletas · sweep: barrido trasero
##   point: hocico afilado · aspect: ancho/alto del quad · px: ancho en píxeles (adulto)
## Economía: price (compra), level (desbloqueo), temp/ph (rangos cómodos),
##   load (carga de oxígeno), incubate/grow (segundos reales)
## presets: [color cuerpo, color patrón, color aleta] · patterns: patrones normales de la especie
const SPECIES := {
	"guppy": {
		"name": "Guppy", "desc": "Pequeño, alegre y con colas de abanico de mil colores.",
		"price": 15, "level": 1, "temp": [21.0, 28.0], "ph": [6.8, 8.0], "load": 0.6,
		"incubate": 180, "grow": 900, "speed": 62.0, "zone": "mid",
		"shape": {"len": 0.46, "h": 0.19, "tail": 0, "tl": 0.52, "th": 0.34, "dor": 0.1, "ana": 0.05, "sweep": 0.3, "point": 0.3, "aspect": 2.0, "px": 66.0},
		"patterns": [1, 2, 7, 6],
		"presets": [["d8dde3", "ff5a36", "ff7a3d"], ["dfe4ea", "3fa3ff", "4cb8ff"], ["e8e2d8", "ffd23f", "ffbf1f"],
			["e2dde8", "ff4fa3", "ff6fb5"], ["dfe6e0", "38d39f", "3ad6b0"], ["3a3d4a", "ff3b3b", "ff4a4a"]],
	},
	"neon": {
		"name": "Tetra neón", "desc": "Su franja azul brilla como un letrero en la noche.",
		"price": 20, "level": 1, "temp": [21.0, 27.0], "ph": [5.8, 7.3], "load": 0.5,
		"incubate": 300, "grow": 1200, "speed": 72.0, "zone": "mid",
		"shape": {"len": 0.6, "h": 0.2, "tail": 1, "tl": 0.32, "th": 0.21, "dor": 0.11, "ana": 0.08, "sweep": 0.1, "point": 0.55, "aspect": 2.2, "px": 56.0},
		"patterns": [4],
		"presets": [["9fb3c8", "25d0ff", "ff4058"], ["b8c2cc", "4cf3c9", "ff5a3c"], ["a7b0d6", "6f7bff", "ff4f8a"]],
	},
	"corydoras": {
		"name": "Corydoras", "desc": "Limpiador simpático que vive pegado al fondo.",
		"price": 35, "level": 2, "temp": [21.0, 27.0], "ph": [6.0, 7.8], "load": 0.7,
		"incubate": 420, "grow": 1500, "speed": 42.0, "zone": "bottom",
		"shape": {"len": 0.6, "h": 0.26, "tail": 1, "tl": 0.3, "th": 0.23, "dor": 0.22, "ana": 0.06, "sweep": -0.1, "point": 0.15, "aspect": 2.0, "px": 64.0},
		"patterns": [2],
		"presets": [["c9a77c", "5a4632", "d6bf9e"], ["e8d3b0", "4a3a2a", "e8dcc4"], ["8fa37b", "3b4a2a", "a8b894"]],
	},
	"goldfish": {
		"name": "Pez dorado", "desc": "Un clásico de agua fría. Glotón y redondito.",
		"price": 30, "level": 2, "temp": [17.0, 24.0], "ph": [6.8, 8.0], "load": 1.4,
		"incubate": 360, "grow": 1800, "speed": 40.0, "zone": "mid",
		"shape": {"len": 0.52, "h": 0.34, "tail": 2, "tl": 0.5, "th": 0.4, "dor": 0.16, "ana": 0.08, "sweep": 0.1, "point": 0.1, "aspect": 1.7, "px": 106.0},
		"patterns": [0, 6, 1],
		"presets": [["ff8a1f", "fff4e0", "ff9a3a"], ["ffcc33", "ff6a1a", "ffd04d"], ["ff4a2e", "ffffff", "ff5a40"], ["fff3e6", "ff5a26", "fff1e0"]],
	},
	"molly": {
		"name": "Molly", "desc": "Tranquilo y resistente. Le encanta el agua dura.",
		"price": 40, "level": 3, "temp": [22.0, 28.0], "ph": [7.0, 8.2], "load": 1.0,
		"incubate": 420, "grow": 1800, "speed": 46.0, "zone": "mid",
		"shape": {"len": 0.58, "h": 0.29, "tail": 0, "tl": 0.36, "th": 0.28, "dor": 0.2, "ana": 0.07, "sweep": 0.35, "point": 0.3, "aspect": 1.9, "px": 82.0},
		"patterns": [0, 6, 1],
		"presets": [["1d1f26", "3a3d4a", "2a2d38"], ["f2b134", "ffffff", "f4c04f"], ["f5f7fa", "1d1f26", "eceff4"], ["ff8c42", "1d1f26", "ff9a55"]],
	},
	"betta": {
		"name": "Betta", "desc": "El pez luchador: aletas de seda y mucho carácter.",
		"price": 60, "level": 3, "temp": [24.0, 29.0], "ph": [6.0, 7.6], "load": 1.0,
		"incubate": 600, "grow": 2400, "speed": 34.0, "zone": "top",
		"shape": {"len": 0.46, "h": 0.21, "tail": 3, "tl": 0.56, "th": 0.5, "dor": 0.24, "ana": 0.26, "sweep": 0.7, "point": 0.35, "aspect": 1.5, "px": 104.0},
		"patterns": [0, 1, 7],
		"presets": [["2a4dff", "ff2f6d", "2f56ff"], ["d6142e", "2a1a5e", "e0183a"], ["7b2cff", "ff4fcf", "8a3cff"], ["101a4a", "35e0ff", "1a3a8a"], ["f5f2ff", "ff9ec7", "f5f0ff"]],
	},
	"rainbow": {
		"name": "Pez arcoíris", "desc": "Medio azul, medio fuego. Nada en grupo a toda velocidad.",
		"price": 75, "level": 4, "temp": [23.0, 28.0], "ph": [6.8, 8.0], "load": 1.2,
		"incubate": 720, "grow": 2700, "speed": 74.0, "zone": "mid",
		"shape": {"len": 0.62, "h": 0.32, "tail": 1, "tl": 0.32, "th": 0.26, "dor": 0.14, "ana": 0.13, "sweep": 0.45, "point": 0.6, "aspect": 1.9, "px": 94.0},
		"patterns": [1],
		"presets": [["2d5bd8", "ff8c1a", "4a73e0"], ["2fd1c4", "ffd23f", "3ad6c8"], ["7a3cff", "ff5aa5", "8a50ff"]],
	},
	"angelfish": {
		"name": "Pez ángel", "desc": "Elegancia pura con aletas como velas.",
		"price": 120, "level": 6, "temp": [24.0, 29.0], "ph": [6.0, 7.5], "load": 1.6,
		"incubate": 1200, "grow": 3600, "speed": 34.0, "zone": "mid",
		"shape": {"len": 0.44, "h": 0.37, "tail": 1, "tl": 0.32, "th": 0.32, "dor": 0.25, "ana": 0.25, "sweep": 1.0, "point": 0.45, "aspect": 1.15, "px": 104.0},
		"patterns": [3, 0, 6],
		"presets": [["dfe5ea", "2a2f3a", "e6ebef"], ["ffd23f", "ff8c1a", "ffe07a"], ["2a2f3a", "4a5060", "3a3f4a"], ["f0f2f5", "ff7a3a", "f5f6f8"]],
	},
	"discus": {
		"name": "Disco", "desc": "El rey del acuario. Exigente, carísimo y precioso.",
		"price": 260, "level": 8, "temp": [27.0, 31.0], "ph": [5.8, 7.0], "load": 1.8,
		"incubate": 1800, "grow": 5400, "speed": 30.0, "zone": "mid",
		"shape": {"len": 0.6, "h": 0.54, "tail": 0, "tl": 0.2, "th": 0.25, "dor": 0.13, "ana": 0.11, "sweep": 0.2, "point": 0.1, "aspect": 1.35, "px": 114.0},
		"patterns": [3, 6],
		"presets": [["ff3d2e", "2fd6ff", "ff5a40"], ["2fd6ff", "ff7a2e", "3fdcff"], ["ffcf3f", "ff3d2e", "ffd85a"], ["ff6fa8", "ffd0e6", "ff80b5"]],
	},
}

const SPECIES_ORDER := ["guppy", "neon", "corydoras", "goldfish", "molly", "betta", "rainbow", "angelfish", "discus"]

const PATTERN_NAMES := ["Liso", "Degradado", "Moteado", "Barras", "Franja neón", "Bandas", "Mármol", "Esmoquin"]

const RARITY_NAMES := ["Común", "Poco común", "Raro", "Épico", "Legendario"]
const RARITY_COLORS := ["9aa7b5", "4fc27a", "3fa3ff", "b36bff", "ffb020"]
const RARITY_MULT := [1.0, 1.8, 3.5, 7.0, 16.0]

const TANKS := [
	{"id": "nano", "name": "Nano 20 L", "cap": 5, "o2": 4.0, "slots": 3, "price": 0, "level": 1,
		"desc": "Tu primera pecera. Pequeñita pero acogedora."},
	{"id": "comunitario", "name": "Comunitario 60 L", "cap": 10, "o2": 8.0, "slots": 5, "price": 900, "level": 2,
		"desc": "Espacio para una comunidad animada."},
	{"id": "panoramico", "name": "Panorámico 200 L", "cap": 18, "o2": 14.0, "slots": 7, "price": 4000, "level": 5,
		"desc": "Cristal panorámico para paisajes de verdad."},
	{"id": "monumental", "name": "Monumental 1000 L", "cap": 30, "o2": 24.0, "slots": 9, "price": 16000, "level": 9,
		"desc": "Un muro de agua. El sueño de todo acuarista."},
]

## slot: filter / heater / pump / light. Instalar uno sustituye al anterior del mismo hueco.
const EQUIPMENT := {
	"esponja": {"slot": "filter", "name": "Filtro de esponja", "price": 150, "level": 1, "eff": 0.35, "desc": "Algas un 35% más lentas."},
	"mochila": {"slot": "filter", "name": "Filtro de mochila", "price": 700, "level": 3, "eff": 0.55, "desc": "Algas un 55% más lentas."},
	"canister": {"slot": "filter", "name": "Filtro canister", "price": 2400, "level": 6, "eff": 0.75, "desc": "Algas un 75% más lentas."},
	"calentador": {"slot": "heater", "name": "Calentador con termostato", "price": 220, "level": 2, "desc": "Elige la temperatura del agua (18–31 °C)."},
	"difusor": {"slot": "pump", "name": "Piedra difusora", "price": 120, "level": 1, "o2": 3.0, "desc": "+3 de oxígeno y burbujitas."},
	"bomba": {"slot": "pump", "name": "Bomba de aire doble", "price": 600, "level": 3, "o2": 6.0, "desc": "+6 de oxígeno."},
	"circulacion": {"slot": "pump", "name": "Bomba de circulación", "price": 2000, "level": 5, "o2": 10.0, "desc": "+10 de oxígeno."},
	"led_pro": {"slot": "light", "name": "Pantalla LED Pro", "price": 500, "level": 3, "happy": 6.0, "desc": "Luz brillante: +felicidad y plantas más vivas."},
}
const EQUIPMENT_ORDER := ["esponja", "mochila", "canister", "calentador", "difusor", "bomba", "circulacion", "led_pro"]

## kind: plant / ornament. cur: coins / pearls. fx: happy, clean (reduce algas), ph, breed{especie: x}, mutation
const DECOR := {
	"vallisneria": {"name": "Vallisneria", "kind": "plant", "price": 80, "cur": "coins", "level": 1, "fx": {"happy": 3.0, "clean": 0.05}, "desc": "Hierba alta que baila con la corriente."},
	"helecho": {"name": "Helecho de Java", "kind": "plant", "price": 70, "cur": "coins", "level": 1, "fx": {"happy": 3.0, "clean": 0.04}, "desc": "Resistente y frondoso."},
	"planta_rosa": {"name": "Planta artificial", "kind": "plant", "price": 40, "cur": "coins", "level": 1, "fx": {"happy": 2.0}, "desc": "Rosa chicle. No necesita cuidados."},
	"musgo": {"name": "Bolas de musgo", "kind": "plant", "price": 90, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "clean": 0.06}, "desc": "Esponjosas. Absorben suciedad."},
	"anubias": {"name": "Anubias", "kind": "plant", "price": 140, "cur": "coins", "level": 2, "fx": {"happy": 4.0, "clean": 0.04, "breed": {"betta": 1.5}}, "desc": "Hojas anchas. A los betta les encanta anidar debajo."},
	"rotala": {"name": "Rotala roja", "kind": "plant", "price": 180, "cur": "coins", "level": 3, "fx": {"happy": 5.0, "clean": 0.05}, "desc": "Tallos rojos que encienden el paisaje."},
	"rocas": {"name": "Rocas de río", "kind": "ornament", "price": 50, "cur": "coins", "level": 1, "fx": {"happy": 2.0}, "desc": "Cantos rodados suaves."},
	"tronco": {"name": "Raíz de manglar", "kind": "ornament", "price": 200, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "ph": -0.35, "breed": {"neon": 1.5, "discus": 1.3}}, "desc": "Acidifica el agua. Los tetras se sienten en casa."},
	"cueva": {"name": "Cueva de piedra", "kind": "ornament", "price": 260, "cur": "coins", "level": 2, "fx": {"happy": 3.0, "breed": {"corydoras": 2.0}}, "desc": "Un escondite. Los corydoras crían el doble de rápido."},
	"castillo": {"name": "Castillo", "kind": "ornament", "price": 320, "cur": "coins", "level": 3, "fx": {"happy": 5.0}, "desc": "Torres con musgo para explorar."},
	"anfora": {"name": "Ánfora antigua", "kind": "ornament", "price": 380, "cur": "coins", "level": 4, "fx": {"happy": 5.0, "breed": {"angelfish": 1.4}}, "desc": "Los peces ángel desovan en su superficie."},
	"barco": {"name": "Barco hundido", "kind": "ornament", "price": 900, "cur": "coins", "level": 5, "fx": {"happy": 8.0}, "desc": "Un naufragio lleno de historias."},
	"cofre": {"name": "Cofre del tesoro", "kind": "ornament", "price": 15, "cur": "pearls", "level": 1, "fx": {"happy": 6.0, "mutation": 0.02}, "desc": "Burbujea con suerte: +2% de mutaciones."},
	"coral": {"name": "Coral de fantasía", "kind": "ornament", "price": 25, "cur": "pearls", "level": 4, "fx": {"happy": 8.0, "mutation": 0.03}, "desc": "Brilla en la penumbra: +3% de mutaciones."},
}
const DECOR_ORDER := ["vallisneria", "helecho", "planta_rosa", "rocas", "cofre", "musgo", "anubias", "tronco", "cueva", "rotala", "castillo", "anfora", "coral", "barco"]

const SUBSTRATES := {
	"grava": {"name": "Grava de río", "price": 0, "cur": "coins", "level": 1, "cols": ["8c7b6a", "b9a894", "5e5246"], "pebble": 1.0, "happy": 0.0},
	"arena": {"name": "Arena dorada", "price": 150, "cur": "coins", "level": 1, "cols": ["e3c48a", "f6e3b8", "c19f62"], "pebble": 0.0, "happy": 1.0},
	"pastel": {"name": "Grava pastel", "price": 300, "cur": "coins", "level": 2, "cols": ["f6a6c1", "a8d8ff", "fff1a8"], "pebble": 1.0, "happy": 2.0},
	"negra": {"name": "Arena volcánica", "price": 12, "cur": "pearls", "level": 2, "cols": ["2a2c33", "4a4e5a", "17181c"], "pebble": 0.15, "happy": 2.0},
	"tierra": {"name": "Tierra nutritiva", "price": 400, "cur": "coins", "level": 3, "cols": ["5a4634", "7a6048", "3a2c20"], "pebble": 0.3, "happy": 1.0, "plants": 1.0},
}
const SUBSTRATE_ORDER := ["grava", "arena", "pastel", "negra", "tierra"]

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
	{"text": "Instala un filtro", "type": "filter", "target": 1, "coins": 0, "pearls": 2, "xp": 20},
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
]

const NAMES := ["Burbuja", "Coral", "Perla", "Chispa", "Lola", "Rayo", "Canela", "Miel", "Tofu", "Kiwi",
	"Mango", "Nube", "Luna", "Sol", "Pipo", "Bombón", "Gominola", "Trufa", "Azul", "Brisa", "Copito", "Duna",
	"Estrella", "Flan", "Galleta", "Jazmín", "Lima", "Menta", "Nácar", "Ola", "Pompa", "Quino", "Rubí",
	"Salsa", "Tango", "Uva", "Vainilla", "Yuyu", "Zafiro", "Almendra", "Bruma", "Churro", "Dulce", "Eco",
	"Fresa", "Gamba", "Hoja", "Iris", "Jade", "Limón", "Mora", "Nemi", "Opal", "Pixel", "Quesito", "Remo"]


static func color(hex: String) -> Color:
	return Color.html(hex)
