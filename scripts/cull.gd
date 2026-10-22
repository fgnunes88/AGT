extends RefCounted
## Ajuda a economizar processamento: só redesenha o que está perto da tela.

static func near(n: Node2D, margin := 300.0) -> bool:
	var vp := n.get_viewport()
	if vp == null:
		return false
	var cam := vp.get_camera_2d()
	if cam == null:
		return true
	var c := cam.get_screen_center_position()
	var half := vp.get_visible_rect().size * 0.5 / cam.zoom
	var p := n.global_position
	return absf(p.x - c.x) < half.x + margin and absf(p.y - c.y) < half.y + margin
