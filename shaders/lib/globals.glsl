#version 330 core

// ============================================================================
// Lucent-Shader Core Globals
// ============================================================================

// --- 兼容性宏定义 ---
#ifndef SHADOW_MAP_BIAS
    #define SHADOW_MAP_BIAS 0.0
#endif

#ifndef PI
    #define PI 3.14159265359
#endif
#ifndef TWO_PI
    #define TWO_PI 6.28318530718
#endif

// --- 核心 Uniform 变量 ---
uniform float frametime;
uniform int frameCounter;
uniform float rainStrength;
uniform float wetness;
uniform ivec2 eyeBrightness;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelViewInverse;

uniform ivec2 screenSize;

uniform sampler2D tex;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

uniform sampler2D gbufferColor0;
uniform sampler2D gbufferColor1;
uniform sampler2D gbufferColor2;
uniform sampler2D gbufferDepth;
uniform sampler2D gbufferShadowData;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;

// Iris specific uniforms
#ifdef IRIS_VERSION
uniform int worldTime;
uniform int moonPhase;
#endif

// --- 辅助函数 ---

vec3 getViewSpacePosition(vec2 uv, float depth, mat4 projectionInverse) {
    vec4 clipPos = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = projectionInverse * clipPos;
    return viewPos.xyz / viewPos.w;
}

vec3 getWorldSpacePosition(vec3 viewPos) {
    return (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
}

vec2 getAttributedUV() {
    return gl_FragCoord.xy / screenSize;
}

const vec3 UP_VECTOR = vec3(0.0, 1.0, 0.0);
