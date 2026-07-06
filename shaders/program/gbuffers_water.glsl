#version 330 core

// ----------------------------------------------------------------------------
// Vertex Shader: Water G-Buffer
// ----------------------------------------------------------------------------
in vec3 mc_Position;
in vec4 mc_Color;
in vec2 mc_texCoord;
in vec3 mc_Normal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

out vec2 texCoord;
out vec3 normal;
out vec3 viewPos;
out vec4 color;

void main() {
    texCoord = mc_texCoord;
    color = mc_Color;
    normal = normalize(mat3(gbufferModelView) * mc_Normal);
    viewPos = (gbufferModelView * vec4(mc_Position, 1.0)).xyz;
    gl_Position = gbufferProjection * vec4(viewPos, 1.0);
}

// ----------------------------------------------------------------------------
// Fragment Shader: Water MRT Output
// ----------------------------------------------------------------------------
uniform sampler2D tex;
uniform float frametime;

in vec2 texCoord;
in vec3 normal;
in vec3 viewPos;
in vec4 color;

layout(location = 0) out vec4 gbufferColor0;
layout(location = 1) out vec4 gbufferColor1;
layout(location = 2) out vec4 gbufferColor2;

void main() {
    vec4 albedo = texture(tex, texCoord) * color;
    
    float materialID = 0.5; // 水面标识
    float specularStrength = 0.8;

    // 简易法线动画模拟波纹
    float wave = sin(frametime * 2.0 + viewPos.x * 0.5) * 0.1 + 
                 cos(frametime * 1.5 + viewPos.z * 0.5) * 0.1;
    vec3 animatedNormal = normalize(normal + vec3(wave, wave * 0.2, wave));
    
    gbufferColor0 = vec4(albedo.rgb * 0.6, specularStrength);
    gbufferColor1 = vec4(animatedNormal * 0.5 + 0.5, materialID);
    gbufferColor2 = vec4(0.8, 0.0, 0.0, 1.0);
}
