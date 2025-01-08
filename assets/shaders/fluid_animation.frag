#version 460 core

#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

#define PI 3.14159265359

vec2 rotate(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

float wave(vec2 p, float t) {
    p = rotate(p, t * 0.1);
    return (sin(p.x * 4.0 + t) * 0.5 + 0.5) * 
           (sin(p.y * 3.0 + t * 1.2) * 0.5 + 0.5);
}

vec3 flow(vec2 uv, float t) {
    // 基础颜色
    vec3 col1 = vec3(0.1, 0.3, 0.8);  // 深蓝
    vec3 col2 = vec3(0.2, 0.5, 1.0);  // 亮蓝
    vec3 col3 = vec3(0.0, 0.8, 1.0);  // 青色
    
    // 多层波浪
    float w1 = wave(uv * 1.0, t);
    float w2 = wave(uv * 1.5 + vec2(0.12), t * 0.8);
    float w3 = wave(uv * 2.0 + vec2(-0.15), t * 1.2);
    
    // 混合波浪
    float w = (w1 * 0.5 + w2 * 0.3 + w3 * 0.2);
    
    // 颜色混合
    vec3 color = mix(col1, col2, w);
    color = mix(color, col3, w * w);
    
    // 添加亮度变化
    float brightness = sin(t * 0.5) * 0.1 + 0.9;
    color *= brightness;
    
    // 添加光晕效果
    float glow = exp(-length(uv) * 2.0);
    color += col3 * glow * 0.3;
    
    return color;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = (fragCoord - 0.5 * vec2(uWidth, uHeight)) / min(uWidth, uHeight);
    
    float t = uTime * 0.2;  // 减慢动画速度
    
    vec3 color = flow(uv, t);
    
    // 增加对比度和饱和度
    color = pow(color, vec3(0.8));
    
    fragColor = vec4(color, 1.0);
} 