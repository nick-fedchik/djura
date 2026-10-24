extends RefCounted
# Корінь рівня (вузол з Platforms/Enemies). Персонажі живуть у групі «Cast» (контур «Київнаукфільм»),
# тож get_parent() більше не є коренем рівня.

static func of(node: Node) -> Node:
	var n := node.get_parent()
	while n != null and not n.has_node("Platforms"):
		n = n.get_parent()
	return n
