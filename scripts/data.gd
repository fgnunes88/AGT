extends RefCounted
## Todos os dados do jogo num lugar só: zonas, espécies, posições.
## Para adicionar uma espécie nova, basta acrescentar uma entrada em SPECIES
## e colocá-la em SPAWNS.

const WORLD_W := 7000.0
const ZONE_H := 1000.0
const SANCTUARY_BOTTOM := 4700.0
const CRACK_X := Vector2(5550.0, 5850.0)  # fenda que leva ao santuário

const ZONES := [
	{"name": "Recife de Coral", "top": Color(0.30, 0.80, 0.95), "bottom": Color(0.10, 0.55, 0.80), "light": 1.0, "m0": 0.0, "m1": 40.0, "faction": "Sindicato"},
	{"name": "Mar Aberto", "top": Color(0.10, 0.50, 0.78), "bottom": Color(0.05, 0.28, 0.55), "light": 0.85, "m0": 40.0, "m1": 200.0, "faction": "Sindicato"},
	{"name": "Zona da Penumbra", "top": Color(0.05, 0.22, 0.45), "bottom": Color(0.06, 0.08, 0.25), "light": 0.55, "m0": 200.0, "m1": 1000.0, "faction": "Corporação"},
	{"name": "Fossa das Marianas", "top": Color(0.05, 0.06, 0.18), "bottom": Color(0.01, 0.01, 0.05), "light": 0.32, "m0": 1000.0, "m1": 10900.0, "faction": "Corporação"},
	{"name": "Santuário Perdido", "top": Color(0.10, 0.65, 0.60), "bottom": Color(0.05, 0.40, 0.45), "light": 1.0, "m0": 10900.0, "m1": 11000.0, "faction": ""},
]

# pattern define detalhes do desenho (ver shark_art.gd)
const SPECIES := [
	{"name": "Tubarão-de-pontas-negras", "zone": 0, "len": 110.0, "h": 38.0, "body": Color(0.58, 0.64, 0.70), "belly": Color(0.95, 0.95, 0.92), "pattern": "blacktip", "speed": 130.0, "flee": 280.0,
	 "fact": "As pontas das suas barbatanas parecem mergulhadas em tinta preta. Adora as águas rasas e quentes do recife."},
	{"name": "Tubarão-lixa", "zone": 0, "len": 130.0, "h": 36.0, "body": Color(0.72, 0.56, 0.36), "belly": Color(0.90, 0.80, 0.62), "pattern": "nurse", "speed": 50.0, "flee": 120.0,
	 "fact": "Passa o dia descansando no fundo. Para comer, ele suga a comida como um aspirador!"},
	{"name": "Tubarão-zebra", "zone": 0, "len": 120.0, "h": 32.0, "body": Color(0.88, 0.78, 0.52), "belly": Color(0.97, 0.92, 0.78), "pattern": "spots", "speed": 60.0, "flee": 140.0,
	 "fact": "Quando é bebê tem listras como uma zebra. Quando cresce, as listras viram pintinhas!"},
	{"name": "Tubarão-de-pontas-brancas", "zone": 0, "len": 110.0, "h": 34.0, "body": Color(0.50, 0.56, 0.62), "belly": Color(0.92, 0.94, 0.95), "pattern": "whitetip", "speed": 90.0, "flee": 210.0,
	 "fact": "De dia descansa dentro de cavernas. À noite sai para procurar comida entre os corais."},
	{"name": "Tubarão-martelo", "zone": 1, "len": 170.0, "h": 44.0, "body": Color(0.52, 0.60, 0.64), "belly": Color(0.93, 0.93, 0.90), "pattern": "hammer", "speed": 140.0, "flee": 300.0,
	 "fact": "A cabeça em forma de martelo funciona como um detector: sente os peixes escondidos debaixo da areia."},
	{"name": "Tubarão-baleia", "zone": 1, "len": 380.0, "h": 110.0, "body": Color(0.28, 0.40, 0.58), "belly": Color(0.88, 0.90, 0.92), "pattern": "whale", "speed": 50.0, "flee": 75.0,
	 "fact": "É o maior peixe do mundo! Mesmo sendo enorme, é calmo e come bichinhos minúsculos chamados plâncton."},
	{"name": "Tubarão-tigre", "zone": 1, "len": 200.0, "h": 55.0, "body": Color(0.56, 0.60, 0.52), "belly": Color(0.94, 0.92, 0.85), "pattern": "tiger", "speed": 110.0, "flee": 250.0,
	 "fact": "Tem listras como um tigre e come quase tudo o que encontra. É o grande faxineiro do oceano."},
	{"name": "Tubarão-mako", "zone": 1, "len": 160.0, "h": 40.0, "body": Color(0.20, 0.38, 0.78), "belly": Color(0.95, 0.96, 0.98), "pattern": "mako", "speed": 240.0, "flee": 430.0,
	 "fact": "Um dos tubarões mais rápidos que existem. Consegue até saltar para fora da água!"},
	{"name": "Tubarão-raposa", "zone": 2, "len": 170.0, "h": 42.0, "body": Color(0.50, 0.42, 0.66), "belly": Color(0.90, 0.88, 0.95), "pattern": "thresher", "speed": 150.0, "flee": 330.0,
	 "fact": "Usa a cauda enorme como um chicote para atordoar os cardumes de peixes."},
	{"name": "Tubarão-lanterna", "zone": 2, "len": 70.0, "h": 22.0, "body": Color(0.22, 0.24, 0.34), "belly": Color(0.30, 0.90, 1.00), "pattern": "lantern", "speed": 80.0, "flee": 170.0,
	 "fact": "Pequenino e brilhante: a barriga dele emite luz para se esconder na escuridão."},
	{"name": "Tubarão-branco", "zone": 2, "len": 250.0, "h": 72.0, "body": Color(0.52, 0.57, 0.63), "belly": Color(0.97, 0.97, 0.97), "pattern": "white", "speed": 140.0, "flee": 360.0,
	 "fact": "O maior tubarão caçador do mundo! Apesar da fama, quase nunca ataca pessoas e consegue mergulhar até a escuridão da penumbra."},
	{"name": "Tubarão-duende", "zone": 3, "len": 190.0, "h": 44.0, "body": Color(0.92, 0.62, 0.68), "belly": Color(0.98, 0.82, 0.84), "pattern": "goblin", "speed": 60.0, "flee": 140.0,
	 "fact": "Tem um focinho comprido e consegue lançar a mandíbula para a frente para apanhar comida."},
	{"name": "Tubarão-cobra", "zone": 3, "len": 200.0, "h": 30.0, "body": Color(0.42, 0.38, 0.30), "belly": Color(0.60, 0.55, 0.45), "pattern": "frilled", "speed": 70.0, "flee": 160.0,
	 "fact": "Chamado de \"fóssil vivo\": quase não mudou em milhões de anos e nada como uma enguia."},
	{"name": "Megalodon", "zone": 3, "len": 900.0, "h": 250.0, "body": Color(0.36, 0.42, 0.50), "belly": Color(0.80, 0.82, 0.84), "pattern": "mega", "speed": 120.0, "flee": 120.0,
	 "fact": "A maior lenda dos mares! Os cientistas só conheciam o Megalodon pelos dentes fósseis, maiores que a mão de um adulto."},
]
const MEGALODON_ID := 13

# Chips de proteção necessários em cada zona (junto com as 3 peças) para liberar a próxima.
# Na Fossa, os chips liberam o ataque à antena da megabase.
const CHIP_GOAL := [6, 6, 6, 3]

# Quantos de cada espécie aparecem livres no mapa (índice da espécie: quantidade)
const SPAWNS := {0: 2, 1: 2, 2: 2, 3: 2, 4: 2, 5: 1, 6: 2, 7: 2, 8: 2, 9: 3, 10: 2, 11: 2, 12: 2}

# Algas onde Arthur se esconde: Rect2(x, y, largura, altura)
const KELP := [
	Rect2(1150, 560, 260, 440), Rect2(2600, 520, 300, 480), Rect2(4200, 580, 260, 420), Rect2(5600, 500, 300, 500),
	Rect2(800, 1520, 300, 480), Rect2(2300, 1470, 260, 530), Rect2(3900, 1520, 300, 480), Rect2(5400, 1460, 300, 540),
	Rect2(1000, 2520, 300, 480), Rect2(2800, 2460, 300, 540), Rect2(4600, 2520, 300, 480), Rect2(6000, 2460, 300, 540),
	Rect2(1200, 3580, 300, 420), Rect2(2600, 3500, 300, 500), Rect2(4000, 3540, 300, 460),
]

# Drones de patrulha: x inicial, x final, y
const DRONES := [
	[2000, 3200, 720], [4500, 5600, 820],
	[1500, 2600, 1300], [3000, 4200, 1720], [4800, 6200, 1420],
	[1600, 2700, 2300], [3300, 4500, 2720], [5000, 6000, 2420], [2000, 3200, 2860],
	[1600, 2800, 3300], [3000, 4200, 3720], [4400, 5000, 3380], [5600, 6400, 3520],
]

# Peças da Corporação: 3 por zona liberam a próxima
const PARTS := [
	[Vector2(2700, 900), Vector2(5100, 950), Vector2(6400, 420)],
	[Vector2(2100, 1900), Vector2(3700, 1950), Vector2(6500, 1800)],
	[Vector2(2200, 2950), Vector2(3900, 2950), Vector2(5600, 2260)],
]

# Redes/gaiolas com tubarões presos: posição, espécie, estilo
const NETS := [
	[Vector2(1700, 300), 0, "net"], [Vector2(3800, 450), 3, "net"],
	[Vector2(2800, 1250), 6, "net"], [Vector2(5800, 1750), 4, "net"],
	[Vector2(1400, 2880), 8, "cage"], [Vector2(4300, 2880), 9, "cage"],
]

# Gravações do pai, Philip Blake (uma por zona)
const LOGS := [
	[Vector2(900, 880), "Arthur, todo grande explorador começa devagar. Observe antes de agir."],
	[Vector2(6700, 1150), "Os tubarões não são monstros, filho. São os guardiões do equilíbrio do mar."],
	[Vector2(300, 2700), "Onde a luz acaba, a vida inventa a sua própria luz."],
	[Vector2(800, 3900), "Proteja cada vida que cruzar o seu caminho. Até aquelas que o mundo ainda não conhece."],
]

# Barcos do Sindicato na superfície: x inicial, x final
const BOATS := [[1500, 3600], [4100, 6600]]

# Boias-sonar da Corporação (paradas): avisam os drones quando a onda de sonar acerta o Manta
const BUOYS := [
	Vector2(2450, 2580), Vector2(4050, 2380), Vector2(5350, 2700),
	Vector2(2200, 3520), Vector2(3600, 3280), Vector2(6050, 3650),
]

const CHECKPOINTS := [Vector2(520, 140), Vector2(600, 1090), Vector2(600, 2090), Vector2(600, 3090), Vector2(5700, 4150)]
const MEGABASE_POS := Vector2(5000, 3760)
const SHIP_POS := Vector2(420, 0)


static func zone_of(y: float) -> int:
	return clampi(int(floor(y / ZONE_H)), 0, 4)


static func depth_meters(y: float) -> int:
	var z := zone_of(y)
	var zd: Dictionary = ZONES[z]
	var f := clampf((y - z * ZONE_H) / ZONE_H, 0.0, 1.0)
	return int(lerpf(zd["m0"], zd["m1"], f))
