//
//  File.metal
//  GPUImage_iOS
//
//  Created by Jim Wang on 2024/4/22.
//  Copyright © 2024 Red Queen Coder, LLC. All rights reserved.
//

#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

struct PerlinNoiseUniform
{
    float time;
    float scale;
};

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
float3 random3(float3 c) {
    float j = 4096.0*sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}
/* 3d simplex noise */
float simplex3d(float3 p) {
    /* skew constants for 3d simplex functions */
    float F3 =  0.3333333;
    float G3 =  0.1666667;
    /* 1. find current tetrahedron T and it's four vertices */
    /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
    /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/

    /* calculate s and x */
    float3 s = floor(p + dot(p, float3(F3)));
    float3 x = p - s + dot(s, float3(G3));

    /* calculate i1 and i2 */
    float3 e = step(float3(0.0), x - x.yzx);
    float3 i1 = e*(1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy*(1.0 - e);

    /* x1, x2, x3 */
    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0*G3;
    float3 x3 = x - 1.0 + 3.0*G3;

    /* 2. find four surflets and store them in d */
    float4 w, d;

    /* calculate surflet weights */
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
    w = max(0.6 - w, 0.0);

    /* calculate surflet components */
    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    /* multiply d by w^4 */
    w *= w;
    w *= w;
    d *= w;

    /* 3. return the sum of the four surflets */
    return dot(d, float4(52.0));
}


/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(float3 m) {
    /* const matrices for 3d rotation */
    float3x3 rot1 = float3x3(-0.37, 0.36, 0.85,-0.14,-0.93, 0.34,0.92, 0.01,0.4);
    float3x3 rot2 = float3x3(-0.55,-0.39, 0.74, 0.33,-0.91,-0.24,0.77, 0.12,0.63);
    float3x3 rot3 = float3x3(-0.71, 0.52,-0.47,-0.08,-0.72,-0.68,-0.7,-0.45,0.56);

    return   0.5333333*simplex3d(m*rot1)
    +0.2666667*simplex3d(2.0*m*rot2)
    +0.1333333*simplex3d(4.0*m*rot3)
    +0.0666667*simplex3d(8.0*m);
}

fragment float4 perlineNoiseFragment(SingleInputVertexIO fragmentInput [[ stage_in ]],
                                     texture2d<float> inputTexture [[texture(0)]],
                                     constant PerlinNoiseUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;

    float2 uv = fragmentInput.textureCoordinate;
    float4 inputColor = inputTexture.sample(quadSampler, uv);

    // 1.5: scale of the noise
    // time*0.025: the speed of the noise animation
    float3 p3 = float3(uv * uniform.scale, uniform.time*0.025);

    float value;

    value = simplex3d_fractal(p3*8.0+8.0);

    // The greater the weight(0.8), the greater the difference between light and dark.
    value = 0.2 + 0.8*value;

    // Enhance the difference
    value = pow(value + 0.5, 5.0) - 0.5;

    return float4(float3(value), inputColor.a);
}
