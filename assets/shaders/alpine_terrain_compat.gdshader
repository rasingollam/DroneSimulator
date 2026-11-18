shader_type spatial;
uniform sampler2D grass_color: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D cliff_color: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D scree_color: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D snow_color: source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float season=0.0;
varying vec3 world;
varying vec3 up;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;up=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float stone=smoothstep(0.12,0.55,1.0-normalize(up).y);
 float highland=smoothstep(250.0,550.0,world.y);
 vec2 projection=abs(up.x)>abs(up.z)?world.zy:world.xy;
 vec3 rock=texture(cliff_color,projection*0.07).rgb;
 vec3 ground=mix(texture(grass_color,world.xz*0.25).rgb,texture(scree_color,world.xz*0.13).rgb,highland);
 float far_mix=smoothstep(80.0,450.0,distance(CAMERA_POSITION_WORLD,world));
 ground=mix(ground,mix(textureLod(grass_color,vec2(0.5),10.0).rgb,textureLod(scree_color,vec2(0.5),10.0).rgb,highland),far_mix*0.8);
 float winter=smoothstep(1.0,2.0,season);
 float snow=smoothstep(620.0-winter*230.0,800.0-winter*200.0,world.y)*smoothstep(0.25,0.8,up.y);
 ALBEDO=mix(mix(ground,rock,stone),texture(snow_color,world.xz*0.2).rgb,snow);
 ALBEDO*=mix(vec3(1.0),vec3(1.12,0.91,0.72),min(season,1.0)*(1.0-winter));
 ALBEDO*=0.9+sin(world.x*0.004+TIME*0.02)*sin(world.z*0.003+TIME*0.01)*0.09;
 ROUGHNESS=0.94;SPECULAR=0.1;
}
