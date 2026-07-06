#version 330 core

#include "/lib/globals.glsl"

// ============================================================================
// Vertex Shader: Composite Pass (Bloom Extraction)
// ============================================================================
in vec4 position;

out vec2 texCoord;

void main() {
    texCoord = (position.xy + 1.0) * 0.5;
    gl_Position = vec4(position.xy, 1.0, 1.0);
}

// ============================================================================
// Fragment Shader: Bloom Extraction
// ============================================================================
in vec2 texCoord;

out vec4 fragColor;

uniform sampler2D colortex0; // 来自 deferred 的场景颜色

// ----------------------------------------------------------------------------
// 亮度提取 - 只保留高亮区域
// ----------------------------------------------------------------------------
vec3 extractBloom(vec3 color, float threshold) {
    float brightness = dot(color, vec3(0.299, 0.587, 0.114));
    return max(vec3(0.0), color - vec3(threshold));
}

// ----------------------------------------------------------------------------
// 主函数
// ============================================================================
void main() {
    vec3 sceneColor = texture(colortex0, texCoord).rgb;
    
    // 提取亮度高于阈值的部分
    float bloomThreshold = 0.8;
    vec3 bloom = extractBloom(sceneColor, bloomThreshold);
    
    fragColor = vec4(bloom, 1.0);
}
