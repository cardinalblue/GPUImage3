#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    // 0 - 1
    float opacity;
    // 0: scale aspect fill
    // 1: scale aspect fit
    // Others: scale fill
    float mode;
} ScreenBlendUniform;

fragment half4 screenBlendFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]],
                                   texture2d<half> inputTexture2 [[texture(1)]],
                                   constant ScreenBlendUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    // Calculate the aspect ratios of the two textures
    float dimension1 = max(inputTexture.get_width() , inputTexture.get_height());
    float dimension2 = max(inputTexture2.get_width() , inputTexture2.get_height());

    float2 norSize1 = float2(inputTexture.get_width() / dimension1, inputTexture.get_height() / dimension1);
    float2 norSize2 = float2(inputTexture2.get_width() / dimension2, inputTexture2.get_height() / dimension2);

    float scaleX = norSize1.x / norSize2.x;
    float scaleY = norSize1.y / norSize2.y;

    float2 textureCoordinate2 = fragmentInput.textureCoordinate; // default scale fill

    // Linear Interpolation
    // f(min) = a
    // f(max) = b
    // f(x) = ((b - a)(x - min) / (max - min)) + a
    if (uniform.mode == 0.0) { 
        // aspect fill
        float scale = max(scaleX, scaleY);
        if (scaleX > scaleY) {
            // fill width
            float offsetY = abs(norSize1.y - norSize2.y * scale) / 2;
            offsetY /= scale;
            float min = 0;
            float max = 1;
            float a = offsetY;
            float b = 1 - offsetY;
            textureCoordinate2.y = (b - a) * (textureCoordinate2.y - min) / (max - min) + a;
        } else {
            // fill height
            float offsetX = abs(norSize1.x - norSize2.x * scale) / 2;
            offsetX /= scale;
            float min = 0;
            float max = 1;
            float a = offsetX;
            float b = 1 - offsetX;
            textureCoordinate2.x = (b - a) * (textureCoordinate2.x - min) / (max - min) + a;
        }
    } else if (uniform.mode == 1.0) { 
        // aspect fit
        float scale = min(scaleX, scaleY);
        if (scaleX < scaleY) {
            // fit width
            float offsetY = (norSize1.y - norSize2.y * scale) / 2;
            float min = offsetY;
            float max = 1 - offsetY;
            float a = 0;
            float b = 1;
            textureCoordinate2.y = (b - a) * (textureCoordinate2.y - min) / (max - min) + a;
        } else {
            // fit height
            float offsetX = (norSize1.x - norSize2.x * scale) / 2;
            float min = offsetX;
            float max = 1 - offsetX;
            float a = 0;
            float b = 1;
            textureCoordinate2.x = (b - a) * (textureCoordinate2.x - min) / (max - min) + a;
        }
    } else {
        // scale fill
        textureCoordinate2 = fragmentInput.textureCoordinate;
    }

    if (textureCoordinate2.y < 0 || textureCoordinate2.y > 1 
        || textureCoordinate2.x < 0 || textureCoordinate2.x > 1) {
        return textureColor;
    }

    half4 textureColor2 = inputTexture2.sample(quadSampler, textureCoordinate2);
    textureColor2.rgb *= uniform.opacity;

    half4 whiteColor = half4(1.0);
    return whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
}

// Original GPUImage3 implementation
//
//fragment half4 screenBlendFragment(TwoInputVertexIO fragmentInput [[stage_in]],
//                                      texture2d<half> inputTexture [[texture(0)]],
//                                      texture2d<half> inputTexture2 [[texture(1)]])
//{
//    constexpr sampler quadSampler;
//    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
//    constexpr sampler quadSampler2;
//    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
//
//    textureColor2.rgb *= 0;
//    half4 whiteColor = half4(1.0);
//
//    return whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
//}
