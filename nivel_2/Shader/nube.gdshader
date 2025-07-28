shader_type canvas_item;

uniform float speed = 0.03; // velocidad del movimiento

void fragment() {
    // mover la coordenada UV horizontalmente según el tiempo
    vec2 uv = UV;
    uv.x -= TIME * speed;
    uv.x = fract(uv.x); // para que se repita la textura continuamente

    COLOR = texture(TEXTURE, uv);
}
