extends Node2D
## Um pedaço do cenário estático (uma rocha com seus corais, uma instalação, o fundo...).
## Cada pedaço é um item separado para o Godot deixar de desenhar o que está fora da tela.

var bg
var piece: Array = []


var baked := false


func setup(owner_bg, p: Array) -> void:
	bg = owner_bg
	piece = p
	if bg.baker != null:
		# modo leve: o pedaço vira uma imagem pronta (bem mais leve no navegador)
		var info: Array = bg.bake_info(p)
		var texs: Array = bg.baker.request(info[0], info[1], info[2], 1, info[3])
		add_child(bg.baker.make_sprite(texs[0], info[1], info[2]))
		baked = true


func _draw() -> void:
	if not baked:
		bg.draw_piece(self, piece)
