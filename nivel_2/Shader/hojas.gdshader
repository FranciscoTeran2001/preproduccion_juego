shader_type canvas_item;

void fragment() {
    // Distorsión horizontal con una onda basada en el tiempo
    vec2 uv = UV;
    uv.x += sin(uv.y * 8.0 + TIME * 0.9) * 0.02;

    COLOR = texture(TEXTURE, uv);
}
