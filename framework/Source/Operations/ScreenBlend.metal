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
    float2 size1 = float2(inputTexture.get_width() , inputTexture.get_height());
    float2 size2 = float2(inputTexture2.get_width() , inputTexture2.get_height());

    float ratio1 = size1.x / size1.y;
    float ratio2 = size2.x / size2.y;

    float2 scale = 1.0;

    if (uniform.mode == 0) {
        // Fill
        float rate = max(ratio1, ratio2);
        scale = float2(ratio1, ratio2) / rate;
    } else if (uniform.mode == 1) {
        // Fit
        float rate = min(ratio1, ratio2);
        scale = float2(ratio1, ratio2) / rate;
    }

    float2 textureCoordinate = fragmentInput.textureCoordinate;
    float2 textureCoordinate2 = (textureCoordinate - 0.5) * scale + 0.5;

    half4 textureColor2 = inputTexture2.sample(quadSampler, textureCoordinate2);

    if (textureCoordinate2.y < 0 || textureCoordinate2.y > 1
        || textureCoordinate2.x < 0 || textureCoordinate2.x > 1) {
        return textureColor;
    }

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
