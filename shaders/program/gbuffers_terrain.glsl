#version 330 core

// ============================================================================
// Vertex Shader: Terrain G-Buffer
// ============================================================================
in vec3 mc_Position;
in vec4 mc_Color;
in vec2 mc_texCoord;
in ivec3 mc_midTexCoord;
in vec3 mc_Normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform float frametime;

out vec2 texCoord;
out vec4 color;
out vec3 normal;
out vec3 viewPos;
out vec2 lightCoord;

void main() {
    texCoord = mc_texCoord;
    color = mc_Color;
    normal = normalize(mat3(gbufferModelView) * mc_Normal);
    
    vec4 pos = gbufferModelView * vec4(mc_Position, 1.0);
    viewPos = pos.xyz;
    
    lightCoord = (mc_midTexCoord.xy + 0.5) / 16.0; 

    gl_Position = gbufferProjection * pos;
}

// ============================================================================
// Fragment Shader: Terrain MRT Output
// ============================================================================
uniform sampler2D tex;
uniform sampler2D lightmap;

in vec2 texCoord;
in vec4 color;
in vec3 normal;
in vec3 viewPos;
in vec2 lightCoord;

layout(location = 0) out vec4 gbufferColor0;
layout(location = 1) out vec4 gbufferColor1;
layout(location = 2) out vec4 gbufferColor2;

void main() {
    vec4 albedo = texture(tex, texCoord) * color;
    
    if (albedo.a < 0.1) discard;

    vec2 lm = texture(lightmap, lightCoord).rg;
    
    float materialID = 0.0;
    
    // 检测发光方块
    if (lm.g > 0.9 && lm.r > 0.5) {
        materialID = 1.0; 
    }

    float specularStrength = 0.1;
    gbufferColor0 = vec4(albedo.rgb, specularStrength);

    vec3 encodedNormal = normal * 0.5 + 0.5;
    gbufferColor1 = vec4(encodedNormal, materialID);

    float emission = (materialID == 1.0) ? length(albedo.rgb) : 0.0;
    gbufferColor2 = vec4(lm.r, lm.g, emission, 1.0);
}
