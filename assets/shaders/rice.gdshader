shader_type spatial;
render_mode cull_disabled;
uniform float season=0.0;
void vertex(){vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;VERTEX.x+=sin(TIME*1.7+p.x*0.4+p.z*0.3)*0.08*(1.0-UV.y);}
void fragment(){float stem=1.0-smoothstep(0.02,0.12,abs(fract(UV.x*5.0+sin(UV.y*19.0)*0.2)-0.5));if(stem<0.25)discard;ALBEDO=mix(vec3(0.12,0.25,0.055),vec3(0.42,0.32,0.10),min(season,1.0));ROUGHNESS=0.95;}
