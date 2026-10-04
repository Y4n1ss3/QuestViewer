# QuestViewer - Passthrough to AI Streaming

## Contexte du Projet
Ce projet permet de récupérer le flux vidéo "Passthrough" (caméra couleur) d'un casque Meta Quest 3, et de l'envoyer en temps réel à un modèle d'Intelligence Artificielle multimodale (actuellement **Claude 3.5 Sonnet** d'Anthropic) pour analyse. L'application est développée avec **Godot 4.3** et un serveur relais en **Python**.

> **Note technique** : Bien que le Quest 3 utilisé soit rooté, nous utilisons les API officielles Meta (via OpenXR) plutôt qu'un accès brut `/dev/video` (V4L2), car les caméras sont verrouillées par le DSP et le rendu direct OpenXR gère automatiquement la correction de distorsion (fisheye).

---

## 🛠️ Ce qui a été accompli (Statut actuel)

1. **Le client VR (Godot 4.3) :**
   * Mise en place de la scène de base VR (`main.tscn`) avec le plugin **Godot OpenXR Vendors**.
   * Configuration de l'export Android avec l'activation obligatoire du Passthrough Meta et de la permission `CAMERA`.
   * Création de `CameraStreamer.gd` : 
     * Accède au flux caméra frontal via `CameraServer.feeds()[0]`.
     * Récupère la frame rendue (conversion implicite YUV -> RGB via Viewport).
     * Compresse la frame en JPEG en mémoire.
     * Envoie la frame via un client `WebSocketPeer` toutes les 3 secondes.
   * Ajout d'un shader manuel (`yuv2rgb.gdshader`) en cas de besoin de manipulation bas-niveau des buffers.

2. **Le serveur relais (Python) :**
   * Création de `PythonServer/server.py`.
   * Mise en place d'un serveur WebSocket asynchrone (`websockets`).
   * Réception des images binaires (JPEG) en provenance du casque.
   * Encodage en Base64 et formatage du payload pour l'API Messages d'Anthropic.
   * Envoi du prompt ("Décris ce que tu vois...") et réception de la réponse de l'IA.

3. **Environnement de travail :**
   * Regroupement des codes Godot et Python dans un seul dépôt Git.
   * Push initial réalisé avec succès sur GitHub.

---

## 🚀 Ce qu'il reste à faire (To-Do List pour la prochaine IA)

Si un autre assistant IA prend le relais, voici les priorités d'implémentation :

### 1. Implémenter la Depth API (Carte de profondeur)
* **Objectif** : Actuellement, seul le flux RGB (image plate) est envoyé. Le but initial du projet est de transmettre **également la profondeur**.
* **Action** : Utiliser l'extension Meta Environment Depth du plugin OpenXR Vendors dans Godot pour extraire le buffer de profondeur en niveaux de gris (Depth Map), le superposer ou le joindre à l'image RGB, et l'envoyer dans le même payload WebSocket.

### 2. Affichage 3D des réponses dans le casque
* **Objectif** : L'IA Claude répond bien au serveur Python, le serveur Python renvoie le texte au casque (le code de réception est prêt dans `CameraStreamer.gd`), mais le texte n'est affiché que dans la console de debug de Godot.
* **Action** : Créer un panneau (Label3D ou un Canvas transparent) attaché à la caméra ou au poignet du joueur dans la scène `main.tscn`, et y injecter le texte de l'IA dès qu'il est reçu via le WebSocket.

### 3. Gestion dynamique de l'IP
* **Objectif** : Ne plus avoir à recompiler le jeu à chaque fois que l'IP locale du PC (qui héberge le serveur Python) change.
* **Action** : Créer un petit clavier/UI virtuel dans Godot pour permettre de taper l'adresse IP au lancement, ou implémenter un système d'auto-découverte (Broadcast UDP local).

### 4. Configuration finale par l'utilisateur
* Ne pas oublier de remplacer la variable `API_KEY` dans `server.py` par la véritable clé secrète Anthropic avant d'exécuter.
