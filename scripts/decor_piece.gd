extends Node2D
## Um pedaço do cenário estático (uma rocha com seus corais, uma instalação, o fundo...).
## Cada pedaço é um item separado para o Godot deixar de desenhar o que está fora da tela.

var bg
var piece: Array = []


func setup(owner_bg, p: Array) -> void:
	bg = owner_bg
	piece = p


func _draw() -> void:
	bg.draw_piece(self, piece)
