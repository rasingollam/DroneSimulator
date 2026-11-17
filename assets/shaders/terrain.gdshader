shader_type spatial;
uniform sampler2D grass_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world;
varying vec3 up_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; up_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
    vec2 uv=world.xz*0.105;
    vec3 grass=texture(grass_color,uv).rgb;
    vec3 large=texture(grass_color,uv*0.213+vec2(0.42,0.73)).rgb;
    grass=mix(grass,large,0.25);
    float macro=noise(world.xz*0.037);
    grass*=mix(vec3(0.72,0.76,0.68),vec3(1.05,1.02,0.91),macro);
    float stripe=sin(world.z*0.32)*0.022;
    grass*=1.0+stripe*(1.0-smoothstep(70.0,110.0,length(world.xz)));
    float slope=smoothstep(0.13,0.55,1.0-up_normal.y);
    float dry=smoothstep(0.70,0.88,macro)*0.30;
    vec3 soil=texture(soil_color,world.xz*0.28).rgb*vec3(0.88,0.91,0.91);
    vec3 rock=texture(rock_color,world.xz*0.045).rgb;
    float highland=smoothstep(4.0,25.0,world.y)*0.6;
    ALBEDO=mix(mix(grass,soil,dry),rock,clamp(slope+highland,0.0,0.85));
    NORMAL_MAP=texture(grass_normal,world.xz*0.28).rgb;
    NORMAL_MAP_DEPTH=0.13*(1.0-smoothstep(8.0,30.0,world.y));
    SPECULAR=0.12;
    ROUGHNESS=0.97;
}
