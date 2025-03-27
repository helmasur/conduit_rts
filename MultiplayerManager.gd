extends Node

# Antal maxspelare
const MAX_PLAYERS := 8

# Godot-nätverk
var peer: MultiplayerPeer = null

func host(port: int = 12345) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Hosting on port", port)

func join(ip: String, port: int = 12345) -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	print("Joining", ip, ":", port)

func is_host() -> bool:
	return multiplayer.is_server()
