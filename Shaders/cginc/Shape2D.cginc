#ifndef EVANGELIONCORE_SHAPE_2D_INCLUDED
#define EVANGELIONCORE_SHAPE_2D_INCLUDED

float EvaRectFillMask(float2 uv, float2 mn, float2 mx)
{
    float2 aa = max(fwidth(uv) * 1.5, 1e-5);
    float2 in0 = smoothstep(mn - aa, mn + aa, uv);
    float2 in1 = 1.0 - smoothstep(mx - aa, mx + aa, uv);
    return saturate(in0.x * in0.y * in1.x * in1.y);
}

float EvaRectBorderMask(float2 uv, float2 mn, float2 mx, float thickness)
{
    float outer = EvaRectFillMask(uv, mn, mx);
    float2 mnIn = mn + thickness;
    float2 mxIn = mx - thickness;
    if (mxIn.x <= mnIn.x || mxIn.y <= mnIn.y)
    {
        return outer;
    }
    float inner = EvaRectFillMask(uv, mnIn, mxIn);
    return saturate(outer - inner);
}

float EvaHLineMask(float2 uv, float x0, float x1, float y, float thickness)
{
    float2 aa = max(fwidth(uv) * 1.5, 1e-5);
    float mx = smoothstep(x0 - aa.x, x0 + aa.x, uv.x) * (1.0 - smoothstep(x1 - aa.x, x1 + aa.x, uv.x));
    float my = 1.0 - smoothstep(thickness * 0.5 - aa.y, thickness * 0.5 + aa.y, abs(uv.y - y));
    return saturate(mx * my);
}

#endif
