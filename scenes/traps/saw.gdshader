shader_type canvas_item;

// 可在检查器中调节滚动速度
uniform float scroll_speed = 2.0;

void fragment() {
	// 允许纹理在 U 轴（横向）按 TIME 偏移平铺
	vec2 custom_uv = UV - vec2(TIME * scroll_speed, 0.0);
	COLOR = texture(TEXTURE, custom_uv);
}
