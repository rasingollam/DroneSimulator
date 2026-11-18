shader_type spatial;
uniform sampler2D grass_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D cliff_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D cliff_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D scree_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D scree_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D snow_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D snow_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D forest_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float season=0.0;
varying vec3 world;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
vec3 untiled(sampler2D tex, vec2 uv) {
	float k=noise(uv*0.055)*8.0;
	float i=floor(k),f=fract(k);
	vec2 a=sin(vec2(3.0,7.0)*i)*17.0,b=sin(vec2(3.0,7.0)*(i+1.0))*17.0;
	vec2 dx=dFdx(uv),dy=dFdy(uv);
	return mix(textureGrad(tex,uv+a,dx,dy).rgb,textureGrad(tex,uv+b,dx,dy).rgb,smoothstep(0.15,0.85,f));
}
vec3 tri(sampler2D tex, vec3 p, vec3 weights) { return untiled(tex,p.zy)*weights.x+untiled(tex,p.xz)*weights.y+untiled(tex,p.xy)*weights.z; }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
	vec3 weights=pow(abs(world_normal),vec3(5.0));weights/=max(dot(weights,vec3(1)),0.001);
	float macro=noise(world.xz*0.014);
	float view_distance=distance(CAMERA_POSITION_WORLD,world);
	float distant=smoothstep(80.0,450.0,view_distance);
	vec3 geometric=normalize(world_normal);
	float stone=smoothstep(0.12,0.55,1.0-geometric.y);
	float scree=smoothstep(250.0,550.0,world.y)*(1.0-stone);
	float winter=smoothstep(1.0,2.0,season);
	float snow=smoothstep(570.0+macro*95.0-winter*240.0,720.0+macro*90.0-winter*200.0,world.y)*smoothstep(0.25,0.8,world_normal.y);
	vec3 grass=mix(texture(grass_color,world.xz*0.35).rgb,texture(grass_color,mat2(vec2(0.8,0.6),vec2(-0.6,0.8))*world.xz*0.13+vec2(3.7)).rgb,0.4)*mix(vec3(0.65,0.82,0.67),vec3(0.95,1.0,0.9),macro);
	vec3 warped=world+vec3(noise(world.zy*0.008),noise(world.xz*0.008+vec2(7)),noise(world.xy*0.008+vec2(14)))*22.0;
	vec3 rock=tri(cliff_color,warped*0.10,weights);
	rock=mix(rock,textureLod(cliff_color,vec2(0.5),10.0).rgb*(0.85+noise(world.xz*0.008)*0.3),distant*0.8);
	rock=mix(vec3(dot(rock,vec3(0.3,0.59,0.11))),rock,0.7)*vec3(0.86,0.92,0.97);
	float t=-world.z-1600.0;
	float river=-250.0+sin(t*0.0033)*210.0+sin(t*0.007)*55.0;
	float woodland=(1.0-smoothstep(75.0,260.0,abs(world.x-river)))*(1.0-smoothstep(430.0,580.0,world.y))*smoothstep(0.65,0.9,geometric.y)*smoothstep(0.25,0.8,macro);
	grass=mix(grass,texture(forest_color,world.xz*0.35).rgb,woodland*0.65);
	vec3 gravel=untiled(scree_color,world.xz*0.18);
	gravel=mix(gravel,textureLod(scree_color,vec2(0.5),10.0).rgb*(0.85+macro*0.3),distant*0.92);
	ALBEDO=mix(mix(mix(grass,gravel,scree),rock,stone),texture(snow_color,world.xz*0.32).rgb,snow);
	ALBEDO*=0.90+noise(world.xz*0.06)*0.16;
	ALBEDO*=mix(vec3(1.0),vec3(1.12,0.91,0.72),smoothstep(0.0,1.0,season)*(1.0-winter)*geometric.y);
	float cloud=noise(world.xz*0.0018+vec2(TIME*0.008,TIME*0.003));
	ALBEDO*=mix(0.72,1.0,smoothstep(0.32,0.68,cloud));
	vec3 tx=texture(cliff_normal,world.zy*0.15).rgb*2.0-1.0;
	vec3 ty=texture(cliff_normal,world.xz*0.15).rgb*2.0-1.0;
	vec3 tz=texture(cliff_normal,world.xy*0.15).rgb*2.0-1.0;
	vec3 cliff_detail=vec3(0.0,tx.y,tx.x)*weights.x+vec3(ty.x,0.0,ty.y)*weights.y+vec3(tz.x,tz.y,0.0)*weights.z;
	vec3 ground_detail=mix(mix(texture(grass_normal,world.xz*0.35).rgb,texture(scree_normal,world.xz*0.28).rgb,scree),texture(snow_normal,world.xz*0.32).rgb,snow)*2.0-1.0;
	vec3 tangent=normalize(vec3(1.0,0.0,0.0)-geometric*geometric.x);
	vec3 bitangent=normalize(cross(tangent,geometric));
	vec3 perturb=mix(tangent*ground_detail.x+bitangent*ground_detail.y,cliff_detail,stone);
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(geometric+perturb*(0.22*(1.0-smoothstep(25.0,180.0,view_distance)))),0.0)).xyz);
	ROUGHNESS=mix(0.94,0.78,snow);
	SPECULAR=0.15;
}
