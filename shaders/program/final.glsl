#version 330 core

#include "/lib/globals.glsl"

// ============================================================================
// Vertex Shader: Final Pass
// ============================================================================
in vec4 position;

out vec2 texCoord;

void main() {
    texCoord = (position.xy + 1.0) * 0.5;
    gl_Position = vec4(position.xy, 1.0, 1.0);
}

// ============================================================================
// Fragment Shader: Tone Mapping + Color Correction + Gamma
// ============================================================================
in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D colortex0; // 来自 composite1 的最终颜色

// ----------------------------------------------------------------------------
// Reinhard 色调映射
// ----------------------------------------------------------------------------
vec3 reinhardToneMapping(vec3 color) {
    return color / (color + 1.0);
}

// ----------------------------------------------------------------------------
// ACES 色调映射 (更电影化)
// ----------------------------------------------------------------------------
vec3 acesToneMapping(vec3 color) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    
    return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

// ----------------------------------------------------------------------------
// 色彩分级
// ----------------------------------------------------------------------------
vec3 colorGrade(vec3 color) {
    // 对比度
    float contrast = 1.05;
    color = mix(vec3(0.5), color, contrast);
    
    // 饱和度
    float saturation = 1.1;
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(lum), color, saturation);
    
    // 色温微调
    color.r *= 1.02;
    color.g *= 1.01;
    
    return color;
}

// ----------------------------------------------------------------------------
// FXAA 抗锯齿 (简化版)
// ----------------------------------------------------------------------------
vec3 fxaa(vec2 uv, sampler2D tex) {
    vec2 inverseScreenSize = 1.0 / screenSize;
    
    vec3 rgbN = textureOffset(tex, uv, ivec2(0, -1)).rgb;
    vec3 rgbS = textureOffset(tex, uv, ivec2(0, 1)).rgb;
    vec3 rgbW = textureOffset(tex, uv, ivec2(-1, 0)).rgb;
    vec3 rgbE = textureOffset(tex, uv, ivec2(1, 0)).rgb;
    
    vec3 rgbM = texture(tex, uv).rgb;
    
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaN = dot(rgbN, luma);
    float lumaS = dot(rgbS, luma);
    float lumaW = dot(rgbW, luma);
    float lumaE = dot(rgbE, luma);
    float lumaM = dot(rgbM, luma);
    
    float lumaMin = min(lumaM, min(min(lumaN, lumaS), min(lumaW, lumaE)));
    float lumaMax = max(lumaM, max(max(lumaN, lumaS), max(lumaW, lumaE)));
    
    float lumaRange = lumaMax - lumaMin;
    
    if (lumaRange < max(0.05, lumaMax * 0.1)) {
        return rgbM;
    }
    
    vec3 rgbL = (rgbN + rgbS + rgbW + rgbE) * 0.25;
    return rgbL;
}

// ----------------------------------------------------------------------------
// 主函数
// ============================================================================
void main() {
    // 1. 读取最终场景颜色
    vec3 color = texture(colortex0, texCoord).rgb;
    
    // 2. 应用 FXAA 抗锯齿
    color = fxaa(texCoord, colortex0);
    
    // 3. 色调映射 (使用 ACES 获得更电影化的效果)
    color = acesToneMapping(color * 1.2);
    
    // 4. 色彩分级
    color = colorGrade(color);
    
    // 5. Gamma 校正 (sRGB 输出)
    color = pow(color, vec3(1.0 / 2.2));
    
    fragColor = vec4(color, 1.0);
}
