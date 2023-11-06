//
//  Grain.metal
//  GPUImage
//
//  Created by Jim Wang on 2023/11/6.
//  Copyright © 2023 Red Queen Coder, LLC. All rights reserved.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

half3 channel_mix(half3 a, half3 b, half3 w) {
    return mix(a, b, w);
}

float gaussian(float z, float u, float o) {
    float pi = 3.14159265358979323846;
    return (1.0 / (o * sqrt(2.0 * pi))) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

half3 madd(half3 a, half3 b, float w) {
    return a + a * b * w;
}

half3 screen(half3 a, half3 b, float w) {
    return mix(a, 1.0 - ((1.0 - a) * (1.0 - b)), w);
}

half3 overlay(half3 a, half3 b, float w) {
    return mix(a, channel_mix(2.0 * a * b, 1.0 - 2.0 * (1.0 - a) * (1.0 - b), step(0.5, a)), w);
}

half3 soft_light(half3 a, half3 b, float w) {
    return mix(a, pow(a, half3(2.0 * (0.5 - b))), half3(w));
}

struct GrainUniform {
    // 0: true
    // 1: false
    float sRGB;
    // 0 ~ 1
    float strength;
    // 0 ~ 1
    float scale;
    //
    float time;
    // 1: screen
    // 2: overlay
    // 3: soft_light
    // 4: max(textureColor.rgb, grain * strength)
    // others: grain * strength;
    float blendMode;
};

fragment half4 grainEffectFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]],
                                   constant GrainUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler;
    float2 uv = fragmentInput.textureCoordinate / uniform.scale;

    // Sample the input texture
    half4 textureColor = inputTexture.sample(quadSampler, uv);

    // Calculate UV coordinates scaled by 'scale'
    uv /= uniform.scale;

    // Apply sRGB correction if needed
    if (uniform.sRGB == 1) {
        textureColor.rgb = pow(textureColor.rgb, 2.2);
    }

    // Calculate noise
    float mean = 0.0;
    float variance = 0.5;
    float t = uniform.time;
    float seed = dot(uv, float2(12.9898, 78.233));
    float noise = fract(sin(seed) * 43758.5453 + t);
    noise = gaussian(noise, mean, variance * variance);

    // Calculate grain
    half3 grain = half3(noise) * (1.0 - textureColor.rgb);
    grain *= 2.0;

    // Apply blending modes
    if (uniform.blendMode == 1) {
        textureColor.rgb = screen(textureColor.rgb, grain, uniform.strength);
    } else if (uniform.blendMode == 2) {
        textureColor.rgb = overlay(textureColor.rgb, grain, uniform.strength);
    } else if (uniform.blendMode == 3) {
        textureColor.rgb = soft_light(textureColor.rgb, grain, uniform.strength);
    } else if (uniform.blendMode == 4) {
        textureColor.rgb = max(textureColor.rgb, grain * uniform.strength);
    } else {
        textureColor.rgb += grain * uniform.strength;
    }

    // Apply sRGB correction if needed
    if (uniform.sRGB == 1) {
        textureColor.rgb = pow(textureColor.rgb, 1.0 / 2.2);
    }

    return textureColor;
}
