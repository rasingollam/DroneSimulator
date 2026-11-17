shader_type spatial;
uniform vec4 base_color : source_color=vec4(0.30,0.33,0.32,1.0);
varying vec3 p;
void vertex(){ p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
    float grain=fract(sin(dot(floor(p.xz*3.0),vec2(12.9898,78.233)))*43758.5453);
    float rib=sin((p.x+p.z)*35.0);
    float rust=smoothstep(0.82,0.97,grain)*0.35;
    ALBEDO=mix(base_color.rgb*(0.88+0.08*rib),vec3(0.22,0.095,0.035),rust);
    METALLIC=0.50-rust;
    ROUGHNESS=0.64+rust*0.3;
}
