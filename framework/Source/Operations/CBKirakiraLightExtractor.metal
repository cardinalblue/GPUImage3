//
//  CBKirakiraLightExtractor.metal
//  GPUImage_iOS
//
//  Created by Jim Wang on 2024/4/22.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
#include "Utils.h"
using namespace metal;

struct LightExtractorUniform {
    float luminanceThreshold;
    float gapThreshold;
    float noiseThreshold;
    float noiseInfluence;
    float increasingRate;
    float minHue;
    float maxHue;
    float equalMinHue;
    float equalMaxHue;
    float equalSaturation;
    float equalBrightness;
};

fragment float4 kirakiraLightExtractorFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                               texture2d<float> inputTexture [[texture(0)]],
                                               texture2d<float> noiseTexture [[texture(1)]],
                                               constant LightExtractorUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;

    float2 uv = fragmentInput.textureCoordinate;
    float4 inputColor = inputTexture.sample(quadSampler, uv);
    float4 noiseColor = noiseTexture.sample(quadSampler, uv); // to block out some area

    float3 luminanceFactor = float3(0.2126, 0.7152, 0.0722); // RGB to Y

    float widthStep = 10.0 / inputTexture.get_width();
    float heightStep = 10.0 / inputTexture.get_height();

    // uv for all 8 directions
    float2 uv_left = uv + float2(-widthStep, 0.0);
    float2 uv_right = uv + float2(widthStep, 0.0);

    float2 uv_top = uv + float2(0.0, -heightStep);
    float2 uv_topLeft = uv + float2(-widthStep, -heightStep);
    float2 uv_topRight = uv + float2(widthStep, -heightStep);

    float2 uv_bottom = uv + float2(0.0, heightStep);
    float2 uv_bottomLeft = uv + float2(-widthStep, heightStep);
    float2 uv_bottomRight = uv + float2(widthStep, heightStep);

    // luminance for 9 positions
    float luminance = dot(inputTexture.sample(quadSampler, uv).rgb, luminanceFactor);
    float luminance_left = dot(inputTexture.sample(quadSampler, uv_left).rgb, luminanceFactor);
    float luminance_right = dot(inputTexture.sample(quadSampler, uv_right).rgb, luminanceFactor);

    float luminance_top = dot(inputTexture.sample(quadSampler, uv_top).rgb, luminanceFactor);
    float luminance_topLeft = dot(inputTexture.sample(quadSampler, uv_topLeft).rgb, luminanceFactor);
    float luminance_topRight = dot(inputTexture.sample(quadSampler, uv_topRight).rgb, luminanceFactor);

    float luminance_bottom = dot(inputTexture.sample(quadSampler, uv_bottom).rgb, luminanceFactor);
    float luminance_bottomLeft = dot(inputTexture.sample(quadSampler, uv_bottomLeft).rgb, luminanceFactor);
    float luminance_bottomRight = dot(inputTexture.sample(quadSampler, uv_bottomRight).rgb, luminanceFactor);

    float count = 0.0;
    if (luminance_left + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_right + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_top + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_topLeft + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_topRight + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_bottom + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_bottomLeft + uniform.gapThreshold < luminance) count += 1.0;
    if (luminance_bottomRight + uniform.gapThreshold < luminance) count += 1.0;

    // Two ways: 1. if the center is brighter than the luminanceThreshold, then the output is bright
    //           2. lighter than 4 directions, then the output is bright
    float outputValue = luminance > uniform.luminanceThreshold ? 1.0 : 0.0;
    if (count > 4.0) outputValue = luminance;
    outputValue = count > 3.0 ? luminance : 0.0;

    // Apply threshold on noise texture
    noiseColor.r = noiseColor.r < uniform.noiseThreshold
                    ? (pow(1.0 - (uniform.noiseThreshold - noiseColor.r) / uniform.noiseThreshold, 2.0)) * noiseColor.r
                    : noiseColor.r;

    // Increase the appearance probability of the bright area
    float increaseValue = luminance > (uniform.luminanceThreshold) * 1.1 ? ((rand(uv) - (1.0 - uniform.increasingRate)) * 0.5) : 0.0;
    increaseValue = clamp(increaseValue, 0.0, 1.0);
    noiseColor.r += increaseValue;
    noiseColor.r = mix(1.0, noiseColor.r, uniform.noiseInfluence);

    outputValue *= noiseColor.r;

    // Get random color as outputColor -> to create colorful sparkle effect
    // Generate the color in HSV color space to get a high saturation color
    float minHue = uniform.minHue;
    float maxHue = uniform.maxHue < uniform.minHue ? uniform.maxHue + 1.0 : uniform.maxHue;
    float hue = fract(fract(uv.x * 3.14 + uv.y * 5.17) * (maxHue - minHue) + minHue);
    float enhanceRatio = step(hue, uniform.equalMinHue) * step(uniform.equalMaxHue, hue) > 0.0 ? 0.0 : 1.0;
    float3 hsv = float3(hue, 1.0 - enhanceRatio * uniform.equalSaturation, min(outputValue * (enhanceRatio * uniform.equalBrightness + 1.0), 1.0));
    float3 outputColor = hsv2rgb(hsv);

    return float4(outputColor, inputColor.a);
}
