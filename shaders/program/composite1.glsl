#version 330 core

#include "/lib/globals.glsl"

// ============================================================================
// Vertex Shader: Composite1 Pass (Bloom Blur + SSR)
// ============================================================================
in vec4 position;

out vec2 texCoord;

void main() {
    texCoord = (position.xy + 1.0) * 0.5;
    gl_Position = vec4(position.xy, 1.0, 1.0);
}

// ============================================================================
// Fragment Shader: Bloom Blur (Gaussian)
// ============================================================================
in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D colortex0; // 原始场景颜色
uniform sampler2D colortex1; // Bloom 提取结果 (来自 composite)

// ----------------------------------------------------------------------------
// 高斯模糊核 (5x5)
// ----------------------------------------------------------------------------
vec3 gaussianBlur(sampler2D tex, vec2 uv, vec2 direction) {
    vec3 result = vec3(0.0);
    
    float weights[5] = float[](0.06136, 0.24477, 0.38774, 0.24477, 0.06136);
    float offsets[5] = float[](-2.0, -1.0, 0.0, 1.0, 2.0);
    
    for (int i = 0; i < 5; i++) {
        vec2 offset = uv + direction * offsets[i] / screenSize;
        result += texture(tex, offset).rgb * weights[i];
    }
    
    return result;
}

// ----------------------------------------------------------------------------
// 主函数
// ============================================================================
void main() {
    // 水平模糊
    vec3 blurredH = gaussianBlur(colortex1, texCoord, vec2(1.0, 0.0));
    
    // 垂直模糊
    vec3 blurredV = gaussianBlur(colortex1, texCoord, vec2(0.0, 1.0));
    
    // 取平均
    vec3 bloom = (blurredH + blurredV) * 0.5;
    
    // 读取原始场景颜色
    vec3 sceneColor = texture(colortex0, texCoord).rgb;
    
    // 混合 Bloom
    float bloomStrength = 0.5;
    vec3 finalColor = sceneColor + bloom * bloomStrength;
    
    fragColor = vec4(finalColor, 1.0);
}
