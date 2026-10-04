shader_type canvas_item;

// En Godot 4, CameraServer fournit automatiquement la texture de la caméra 
// si on utilise un CameraTexture. Cependant, au cas où vous devriez lire les 
// buffers Y et CbCr manuellement (par exemple pour la texture de profondeur),
// voici le shader de base de conversion YUV -> RGB.

uniform sampler2D camera_y; // Texture Y
uniform sampler2D camera_cbcr; // Texture CbCr (ou UV)

void fragment() {
    // Dans Godot 4, si vous assignez directement un CameraTexture à un TextureRect,
    // ce shader n'est pas strictement nécessaire car Godot gère la conversion.
    // Ce shader est donné à titre d'exemple si vous utilisez l'API de bas niveau.
    
    vec2 uv = UV;
    
    float y = texture(camera_y, uv).r;
    vec2 cbcr = texture(camera_cbcr, uv).rg - vec2(0.5, 0.5);
    
    float r = y + 1.402 * cbcr.y;
    float g = y - 0.34414 * cbcr.x - 0.71414 * cbcr.y;
    float b = y + 1.772 * cbcr.x;
    
    COLOR = vec4(r, g, b, 1.0);
}
