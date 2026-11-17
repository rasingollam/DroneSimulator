shader_type spatial;
render_mode depth_prepass_alpha;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ripple = noise(world_position.xz * 0.18 + vec2(TIME * 0.025, TIME * 0.015));
	ALBEDO = vec3(0.035,0.10,0.11) * (0.96 + ripple * 0.08);
	float dx = sin(dot(world_position.xz,vec2(0.8,0.4))+TIME)*0.018 + sin(world_position.z*2.4+TIME*1.7)*0.009;
	float dy = cos(dot(world_position.xz,vec2(-0.5,0.9))+TIME*0.8)*0.016;
	NORMAL_MAP = normalize(vec3(dx,dy,1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.30;
	METALLIC = 0.15;
	SPECULAR = 0.65;
	ALPHA = 0.93;
}
