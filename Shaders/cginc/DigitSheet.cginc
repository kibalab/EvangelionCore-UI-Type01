#ifndef EVANGELIONCORE_DIGIT_SHEET_INCLUDED
#define EVANGELIONCORE_DIGIT_SHEET_INCLUDED

struct EvaDigitBillboardQuad
{
    float3 p0;
    float3 p1;
    float3 p2;
    float3 p3;
    float2 uv0;
    float2 uv1;
    float2 uv2;
    float2 uv3;
};

EvaDigitBillboardQuad EvaBuildVerticalDigitBillboardQuad(
    float3 anchor,
    float3 cameraWorldPos,
    float planeWidth,
    float planeHeight,
    float digitIndex)
{
    float3 up = float3(0.0, 1.0, 0.0);
    float3 toCam = cameraWorldPos - anchor;
    toCam.y = 0.0;

    // Keep digit quads vertical and only yaw toward camera.
    float3 forward = normalize(toCam + float3(1e-5, 0.0, 0.0));
    float3 right = normalize(cross(up, forward));

    float halfW = planeWidth * 0.5;
    float u0 = digitIndex + 1.0;
    float u1 = digitIndex;

    EvaDigitBillboardQuad q;
    q.p0 = anchor - right * halfW;
    q.p1 = anchor + right * halfW;
    q.p2 = q.p1 + up * planeHeight;
    q.p3 = q.p0 + up * planeHeight;

    q.uv0 = float2(u0, 0.0);
    q.uv1 = float2(u1, 0.0);
    q.uv2 = float2(u1, 1.0);
    q.uv3 = float2(u0, 1.0);
    return q;
}

bool EvaComputeBarycentricUV(
    float2 p,
    float2 a,
    float2 b,
    float2 c,
    out float3 bary)
{
    float2 v0 = b - a;
    float2 v1 = c - a;
    float2 v2 = p - a;

    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float denom = d00 * d11 - d01 * d01;
    if (abs(denom) < 1e-10)
    {
        bary = 0;
        return false;
    }

    float invDenom = 1.0 / denom;
    float v = (d11 * d20 - d01 * d21) * invDenom;
    float w = (d00 * d21 - d01 * d20) * invDenom;
    float u = 1.0 - v - w;
    bary = float3(u, v, w);
    return true;
}

float2 EvaDigitSheetUV(float2 digitUV, float digitCount)
{
    float count = max(digitCount, 1.0);
    return float2(digitUV.x / count, digitUV.y);
}

float EvaDigitMaskFromTexel(float4 texel, float maskSource)
{
    float luma = dot(texel.rgb, float3(0.299, 0.587, 0.114));
    float alphaMask = texel.a;
    float mask = alphaMask;

    if (maskSource < 0.5)
    {
        // Auto: if alpha looks unused (near 1), fall back to luminance.
        mask = (alphaMask < 0.999) ? alphaMask : luma;
    }
    else if (maskSource < 1.5)
    {
        mask = alphaMask;
    }
    else if (maskSource < 2.5)
    {
        mask = luma;
    }
    else
    {
        mask = 1.0 - luma;
    }
    return saturate(mask);
}

#endif
