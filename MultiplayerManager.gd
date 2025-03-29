## Detta är en autoload, res://MultiplayerManager.gd
extends Node

# Antal maxspelare
const MAX_PLAYERS := 8
const PORT := 12345
const PLAYER = preload("res://player.tscn")

var game: Node2D

# Godot-nätverk
var peer = ENetMultiplayerPeer.new()

func host() -> void:
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Hosting on port", PORT)

func join(ip: String, port: int = 12345) -> void:
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Joining", ip, ":", PORT)

func is_host() -> bool:
	return multiplayer.is_server()

@rpc("any_peer")
func request_spawn_player():
	if is_host():
		#var peer_id = multiplayer.get_remote_sender_id()
		$/root/Game/PlayerSpawner.spawn("res://player.tscn")
