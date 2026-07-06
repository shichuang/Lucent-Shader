#version 330 core

#include "/lib/globals.glsl"

// ============================================================================
// Vertex Shader: Deferred Pass
// ============================================================================
in vec4 position;

out vec2 texCoord;

void main() {
    texCoord = (position.xy + 1.0) * 0.5;
    gl_Position = vec4(position.xy, 1.0, 1.0);
}

// ============================================================================
// Fragment Shader: SSAO + Lighting + Atmosphere
// ============================================================================
in vec2 texCoord;

out vec4 fragColor;

// ----------------------------------------------------------------------------
// SSAO 实现
// ----------------------------------------------------------------------------
float calculateSSAO(vec3 viewPos, vec3 normal) {
    const float radius = 0.5;
    const int samples = 8;
    
    float occlusion = 0.0;
    vec3 viewDir = normalize(-viewPos);
    
    for (int i = 0; i < samples; i++) {
        // 简单半球采样
        float angle = float(i) / float(samples) * TWO_PI;
        vec3 sampleDir = vec3(
            cos(angle) * radius,
            sin(angle) * radius,
            fract(float(i) * 0.618) * radius
        );
        
        vec3 samplePos = viewPos + sampleDir;
        
        // 转换到裁剪空间
        vec4 clipPos = gbufferProjection * vec4(samplePos, 1.0);
        clipPos.xyz /= clipPos.w;
        clipPos.xyz = clipPos.xyz * 0.5 + 0.5;
        
        if (clipPos.x < 0.0 || clipPos.x > 1.0 || 
            clipPos.y < 0.0 || clipPos.y > 1.0 ||
            clipPos.z < 0.0 || clipPos.z > 1.0) {
            continue;
        }
        
        float sampleDepth = texture(gbufferDepth, clipPos.xy).r;
        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(viewPos.z - sampleDepth * 2.0 + 1.0));
        
        if (sampleDepth < clipPos.z) {
            occlusion += rangeCheck;
        }
    }
    
    return 1.0 - (occlusion / float(samples));
}

// ----------------------------------------------------------------------------
// 简单大气散射
// ----------------------------------------------------------------------------
vec3 calculateAtmosphere(vec3 normal, vec3 sunDir) {
    float sunDot = dot(normal, sunDir);
    vec3 skyColor = vec3(0.4, 0.6, 1.0);
    vec3 sunColor = vec3(1.0, 0.95, 0.8);
    
    return mix(skyColor, sunColor, max(0.0, sunDot));
}

// ----------------------------------------------------------------------------
// 主函数
// ============================================================================
void main() {
    // 读取 G-Buffer
    vec4 albedoSpec = texture(gbufferColor0, texCoord);
    vec4 normalMat = texture(gbufferColor1, texCoord);
    vec4 lmEmission = texture(gbufferColor2, texCoord);
    float depth = texture(gbufferDepth, texCoord).r;
    
    // 重建视图空间位置
    vec3 viewPos = getViewSpacePosition(texCoord, depth, gbufferProjectionInverse);
    
    // 解码法线
    vec3 normal = normalMat.rgb * 2.0 - 1.0;
    normal = normalize(normal);
    
    // 材质 ID
    float materialID = normalMat.a;
    
    // 光照图
    vec2 lightmap = lmEmission.rg;
    float emission = lmEmission.b;
    
    // 计算 SSAO
    float ssao = calculateSSAO(viewPos, normal);
    
    // 简单太阳方向 (实际应从 uniform 获取)
    vec3 sunDir = normalize(vec3(0.5, 0.8, 0.3));
    
    // 基础光照计算
    float diffuse = max(0.0, dot(normal, sunDir));
    vec3 atmosphere = calculateAtmosphere(normal, sunDir);
    
    // 组合最终颜色
    vec3 finalColor = albedoSpec.rgb;
    
    // 应用天空光和方块光
    finalColor *= mix(lightmap.g, 1.0, lightmap.r);
    
    // 应用 SSAO
    finalColor *= ssao;
    
    // 添加大气散射
    finalColor = mix(finalColor, atmosphere * 0.3, max(0.0, dot(normal, vec3(0.0, 1.0, 0.0))));
    
    // 添加自发光
    finalColor += vec3(emission);
    
    fragColor = vec4(finalColor, 1.0);
}
