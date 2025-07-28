shader_type canvas_item;

uniform float wave_speed = 0.5;       // velocidad de flujo
uniform float wave_strength = 0.01;   // qué tanto se ondula
uniform float wave_frequency = 20.0;  // número de ondas

void fragment() {
    vec2 uv = UV;

    // Movimiento en X: simula el flujo lateral del agua
    uv.x += sin(uv.y * wave_frequency + TIME * wave_speed) * wave_strength;

    COLOR = texture(TEXTURE, uv);
}
