#version 330 core

// ----------------------------------------------------------------------------
// Vertex Shader: Shadow Pass
// ----------------------------------------------------------------------------
in vec3 mc_Position;
in vec4 mc_Color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;

out gl_PerVertex {
    vec4 gl_Position;
};

void main() {
    vec4 worldPos = gbufferModelViewInverse * vec4(mc_Position, 1.0);
    gl_Position = shadowProjection * shadowModelView * worldPos;
}

// ----------------------------------------------------------------------------
// Fragment Shader: Shadow Depth Output
// ----------------------------------------------------------------------------
uniform float frametime;

void main() {
    // 基础阴影深度输出
    // 依赖 glPolygonOffset 处理 Shadow Acne
}
