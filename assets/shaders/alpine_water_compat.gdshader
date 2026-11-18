shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color=vec3(0.035,0.105,0.105);
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){float foam=COLOR.r*(0.5+sin(world.x*2.0+world.y*0.4-TIME*4.0)*0.2);ALBEDO=mix(deep_color,vec3(0.47,0.57,0.55),foam);ROUGHNESS=0.38;SPECULAR=0.35;}
