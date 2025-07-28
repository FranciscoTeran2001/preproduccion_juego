shader_type canvas_item;

uniform float time_scale = 1.0;
uniform float intensity = 2.5;
uniform float speed = 1.0;

void fragment() {
    float t = TIME * speed;
    vec2 uv = UV;

    // Desplazamiento tipo fuego (horizontal leve y vertical más suave)
    uv.x += sin(uv.y * 10.0 + t * 3.0) * 0.01 * intensity;
    uv.y += cos(uv.x * 10.0 + t * 2.0) * 0.005 * intensity;

    // Mostrar solo una textura distorsionada
    COLOR = texture(TEXTURE, uv);
}
