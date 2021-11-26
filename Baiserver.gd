extends Node2D

var waitlist := []

var connections := {}

var c := 0

var poll_timer = Timer.new()
const POLL_TIME = 0.5

export var listen_port = 6969

func _ready() -> void:
	var server := WebSocketServer.new()
	server.listen(listen_port,[],true)
	get_tree().network_peer = server
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	poll_timer.wait_time = POLL_TIME
	poll_timer.connect("timeout", self, "_poll")
	add_child(poll_timer)
	poll_timer.start()

func _poll():
	get_tree().network_peer.poll()

func _player_connected(id:int) -> void:
	waitlist.append(id)
	print(str(id) + " is here")
	if waitlist.size() == 2:
		print(str(id) + " is playing")
		connections[c] = [waitlist[0], waitlist[1], false]
		rset_id(waitlist[0], "game_connection", c)
		rset_id(waitlist[1], "game_connection", c)
		rset_id(waitlist[0], "this_side", true)
		rset_id(waitlist[1], "this_side", false)
		waitlist.remove(0)
		waitlist.remove(0)


func _player_disconnected(id:int) -> void:
	waitlist.erase(id)
	print(str(id) + " is gone")


remote func swap(connection, swapinfo) -> void:
	print("swap")
	var cc :Array = connections[connection]
	cc[2] = !cc[2]
	if not cc[0] in get_tree().get_network_connected_peers() or not cc[1] in get_tree().get_network_connected_peers():
		connections.erase(connection)
		return
	rset_id(cc[0], "side", cc[2])
	rset_id(cc[1], "side", cc[2])
	rpc_id(cc[0], "get_swap", swapinfo)
	rpc_id(cc[1], "get_swap", swapinfo)


remote func add_to_amount(side, piece, amt, connection):
	var cc :Array = connections[connection]
	rpc_id(cc[0], "add_to_amount", side, piece, amt)
	rpc_id(cc[1], "add_to_amount", side, piece, amt)
