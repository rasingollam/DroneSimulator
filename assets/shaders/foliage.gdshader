shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaf_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D leaf_alpha : filter_linear_mipmap, repeat_enable;
uniform float tint=1.0;
void vertex() {
    vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    VERTEX.x+=sin(TIME*0.45+p.x*0.16+p.z*0.09)*0.018*UV.y;
}
void fragment() {
    ALBEDO=texture(leaf_color,UV).rgb*tint;
    ALPHA=texture(leaf_alpha,UV).r;
    ALPHA_SCISSOR_THRESHOLD=0.30;
    ROUGHNESS=0.92;
    BACKLIGHT=vec3(0.10,0.13,0.04);
}
