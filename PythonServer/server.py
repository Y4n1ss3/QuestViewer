import asyncio
import websockets
import base64
import json
import requests
import os
from datetime import datetime

# ==========================================
# CONFIGURATION
# ==========================================
# Remplacez par votre clé d'API (Claude / Anthropic)
API_KEY = "VOTRE_CLE_API_CLAUDE" 
HOST = "0.0.0.0"
PORT = 8080

async def handle_connection(websocket):
    print(f"[{datetime.now().time()}] Casque Quest 3 connecté !")
    
    try:
        async for message in websocket:
            # Le message reçu est en binaire (les octets du JPG envoyé par Godot)
            if isinstance(message, bytes):
                print(f"[{datetime.now().time()}] Image reçue : {len(message)} octets")
                
                # Sauvegarder l'image localement pour vérifier (debug)
                with open("latest_frame.jpg", "wb") as f:
                    f.write(message)
                
                # Appeler l'IA avec cette image
                await analyze_image_with_ia(message, websocket)
            else:
                print(f"Message texte reçu (inattendu) : {message}")
                
    except websockets.exceptions.ConnectionClosed as e:
        print(f"[{datetime.now().time()}] Connexion fermée : {e}")

async def analyze_image_with_ia(image_bytes, websocket):
    print("Envoi à l'IA en cours...")
    
    # Encodage de l'image en Base64
    base64_image = base64.b64encode(image_bytes).decode('utf-8')
    
    # ---------------------------------------------------------
    # Exemple avec l'API Claude d'Anthropic (modèle Claude 3.5 Sonnet)
    # ---------------------------------------------------------
    url = "https://api.anthropic.com/v1/messages"
    
    payload = {
        "model": "claude-3-5-sonnet-latest",
        "max_tokens": 512,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64_image
                        }
                    },
                    {
                        "type": "text",
                        "text": "Décris ce que tu vois sur cette image de manière très concise."
                    }
                ]
            }
        ]
    }
    
    headers = {
        'x-api-key': API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json'
    }
    
    try:
        # Requête non-bloquante (avec asyncio)
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(None, lambda: requests.post(url, headers=headers, json=payload))
        
        if response.status_code == 200:
            result = response.json()
            try:
                ia_text = result['content'][0]['text']
                print(f"\n--- RÉPONSE IA ---\n{ia_text}\n------------------\n")
                
                # On renvoie la réponse au Quest 3
                await websocket.send(ia_text)
            except KeyError:
                print("Erreur de parsing de la réponse :", result)
        else:
            print(f"Erreur API ({response.status_code}):", response.text)
            
    except Exception as e:
        print("Erreur de connexion à l'API :", str(e))


async def main():
    print(f"Démarrage du serveur WebSocket sur ws://{HOST}:{PORT}")
    print("En attente de la connexion du Quest 3...")
    
    # Démarrage du serveur
    async with websockets.serve(handle_connection, HOST, PORT):
        await asyncio.Future()  # Tourne à l'infini

if __name__ == "__main__":
    asyncio.run(main())
