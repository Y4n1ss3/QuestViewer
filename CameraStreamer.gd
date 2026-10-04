extends Node

@export var server_url: String = "ws://192.168.1.100:8080" # REMPLACEZ PAR L'IP DE VOTRE PC
@export var send_interval_seconds: float = 3.0

var websocket: WebSocketPeer
var timer: Timer
var camera_feed: CameraFeed

@onready var viewport: SubViewport = $SubViewport

func _ready():
    # 1. Configuration du WebSocket
    websocket = WebSocketPeer.new()
    var err = websocket.connect_to_url(server_url)
    if err != OK:
        print("Erreur de connexion WebSocket: ", err)
    else:
        print("En cours de connexion à ", server_url)

    # 2. Configuration de la caméra (Passthrough)
    var feeds = CameraServer.feeds()
    if feeds.size() > 0:
        camera_feed = feeds[0]
        camera_feed.set_active(true)
        print("Caméra trouvée et activée : ", camera_feed.get_name())
        
        # Le flux s'affiche automatiquement si vous avez configuré le CameraTexture 
        # sur un TextureRect ou un Mesh (voir instructions).
    else:
        print("AUCUNE CAMÉRA TROUVÉE. Vérifiez les permissions Android.")

    # 3. Timer pour envoyer l'image à intervalles réguliers
    timer = Timer.new()
    timer.wait_time = send_interval_seconds
    timer.autostart = true
    timer.timeout.connect(_on_timer_timeout)
    add_child(timer)

func _process(_delta):
    # Gestion des messages WebSocket
    websocket.poll()
    var state = websocket.get_ready_state()
    
    if state == WebSocketPeer.STATE_OPEN:
        while websocket.get_available_packet_count():
            var packet = websocket.get_packet()
            var message = packet.get_string_from_utf8()
            print("[IA RÉPOND] : ", message)
            # ICI: Vous pouvez afficher ce texte en 3D dans votre jeu !

func _on_timer_timeout():
    if websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
        return
        
    print("Capture et envoi de la frame...")
    
    # Récupérer l'image depuis le SubViewport
    # (Le SubViewport doit contenir la scène qui affiche le flux caméra)
    var img: Image = viewport.get_texture().get_image()
    
    # Si le viewport est vide, img sera vide
    if img.is_empty():
        print("L'image est vide !")
        return
        
    # Redimensionner l'image pour l'IA (optionnel, permet d'économiser de la bande passante)
    img.resize(800, 800, Image.INTERPOLATE_BILINEAR)
    
    # Convertir en JPEG
    var jpg_buffer: PackedByteArray = img.save_jpg_to_buffer(75) # Qualité 75%
    
    # Envoyer le binaire via WebSocket
    websocket.send(jpg_buffer)
    print("Frame envoyée ! (Taille: ", jpg_buffer.size(), " octets)")
