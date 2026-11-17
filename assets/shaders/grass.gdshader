shader_type spatial;
render_mode cull_disabled;
varying float variation;
void vertex() {
    vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    variation=INSTANCE_CUSTOM.r;
    VERTEX.x+=sin(TIME*0.7+p.x*0.3+p.z*0.21)*UV.y*UV.y*0.012;
}
void fragment() {
    NORMAL=normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
    ALBEDO=mix(vec3(0.08,0.12,0.035),vec3(0.17,0.23,0.065),UV.y)*mix(0.88,1.15,variation);
    ROUGHNESS=1.0;
}
