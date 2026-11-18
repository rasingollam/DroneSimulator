shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color=vec3(0.035,0.105,0.105);
varying vec3 world;
varying vec3 normal_world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;normal_world=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
	float streak=noise(vec2(world.x*1.7,world.z*0.12-TIME*2.0));
	float broken=noise(vec2(world.x*0.37,world.y*0.23-TIME*3.0));
	float foam=COLOR.r*mix(0.35,0.9,streak*broken);
	vec3 deep=deep_color;
	ALBEDO=mix(deep,vec3(0.47,0.57,0.55),foam);
	vec3 geometric=normalize(normal_world);
	vec3 wave=vec3(sin(dot(world.xz,vec2(0.8,0.4))+TIME)*0.012,0.0,cos(dot(world.xz,vec2(-0.5,1.1))+TIME*0.7)*0.009);
	wave*=1.0-smoothstep(300.0,1800.0,distance(CAMERA_POSITION_WORLD,world));
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(geometric+wave),0.0)).xyz);
	ROUGHNESS=mix(0.28,0.66,foam);
	METALLIC=0.0;
	SPECULAR=0.45;
}
