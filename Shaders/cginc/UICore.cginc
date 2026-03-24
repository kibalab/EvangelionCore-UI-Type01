#ifndef EVANGELIONCORE_UI_CORE_INCLUDED
#define EVANGELIONCORE_UI_CORE_INCLUDED

#include "UnityCG.cginc"
#include "MorphEasing.cginc"
#include "Shape2D.cginc"

fixed4 _BackgroundColor;
fixed4 _StrokeColor;
fixed4 _LineColor;
fixed4 _MarkerColor;
fixed4 _MiniStrokeColor;

float _ElementCount;
float _SideMargin;
float _StrokeBoxWidth;
float _VerticalInset;
float _StrokeThickness;
float _InnerPadding;
float _LineThickness;
float _OutsideGap;
float _SquareSize;
float _SquareOnProbability;
float _SquareScaleFade;
float _SquareSwitchGap;
float _VerticalJitter;
float _MiniRectWidthScale;
float _MiniRectHeightScale;
float _MiniRectSpacing;
float _MiniLineGap;
float _MiniStrokeThickness;
float _MiniLineCount;
float _MiniStackMin;
float _MiniStackMax;

float _MorphDuration;
float _HoldDuration;
float _MorphElasticity;
float _RandomSeed;

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    return o;
}

float Hash11(float p)
{
    return frac(sin(p) * 43758.5453123);
}

float RandElem(int idx, float stateIndex, float side, float channel)
{
    float p = (idx + 1) * 17.131 + stateIndex * 61.713 + side * 101.97 + channel * 13.37 + _RandomSeed * 37.0;
    return Hash11(p);
}

void GetCycleState(out float stateIndex, out float blend01)
{
    EvaGetCycleState(
        _Time.y,
        _MorphDuration,
        _HoldDuration,
        _MorphElasticity,
        stateIndex,
        blend01
    );
}

float MarkerDisplayState(float stateIndex, float morph01, out float scale01)
{
    // No positional interpolation:
    // old set -> off gap -> new set, with very short scale fade near switches.
    float gap = saturate(_SquareSwitchGap);
    float fade = saturate(_SquareScaleFade);
    float outEnd = 0.5 - gap * 0.5;
    float inStart = 0.5 + gap * 0.5;
    float outStart = max(0.0, outEnd - fade);
    float inEnd = min(1.0, inStart + fade);

    if (morph01 < outEnd)
    {
        if (morph01 <= outStart)
        {
            scale01 = 1.0;
        }
        else
        {
            scale01 = 1.0 - smoothstep(outStart, outEnd, morph01);
        }
        return stateIndex;
    }

    if (morph01 > inStart)
    {
        if (morph01 >= inEnd)
        {
            scale01 = 1.0;
        }
        else
        {
            scale01 = smoothstep(inStart, inEnd, morph01);
        }
        return stateIndex + 1.0;
    }

    scale01 = 0.0;
    return -1.0;
}

float StratifiedY01(int i, int count, float stateIndex, float side, float channel)
{
    float denom = max((float)count, 1.0);
    float jitter = (RandElem(i, stateIndex, side, channel) - 0.5) * 2.0 * saturate(_VerticalJitter);
    float y = ((float)i + 0.5 + jitter * 0.45) / denom;
    return saturate(y);
}

float EvenYFromLine(int lineIdx, int count, float yMin, float yMax)
{
    float t = ((float)lineIdx + 0.5) / max((float)count, 1.0);
    return lerp(yMin, yMax, t);
}

fixed4 frag(v2f i) : SV_Target
{
    float2 uv = i.uv;
    int count = clamp((int)round(_ElementCount), 1, 32);

    float sideMargin = saturate(_SideMargin);
    float width = saturate(_StrokeBoxWidth);
    float vInset = saturate(_VerticalInset);

    float2 leftMin = float2(sideMargin, vInset);
    float2 leftMax = float2(sideMargin + width, 1.0 - vInset);
    float2 rightMax = float2(1.0 - sideMargin, 1.0 - vInset);
    float2 rightMin = float2(rightMax.x - width, vInset);

    float2 liMin = leftMin + _InnerPadding;
    float2 liMax = leftMax - _InnerPadding;
    float2 riMin = rightMin + _InnerPadding;
    float2 riMax = rightMax - _InnerPadding;

    float strokeMask = 0.0;
    strokeMask = max(strokeMask, EvaRectBorderMask(uv, leftMin, leftMax, _StrokeThickness));
    strokeMask = max(strokeMask, EvaRectBorderMask(uv, rightMin, rightMax, _StrokeThickness));

    float lineMask = 0.0;
    float markerMask = 0.0;
    float miniMask = 0.0;

    float stateIndex;
    float blend01;
    GetCycleState(stateIndex, blend01);

    float lineYMin = max(liMin.y, riMin.y);
    float lineYMax = min(liMax.y, riMax.y);
    int miniMin = clamp((int)round(_MiniStackMin), 0, 12);
    int miniMax = clamp((int)round(_MiniStackMax), 0, 12);
    if (miniMax < miniMin)
    {
        int tmp = miniMin;
        miniMin = miniMax;
        miniMax = tmp;
    }
    int miniRange = miniMax - miniMin + 1;
    int miniLineCount = clamp((int)round(_MiniLineCount), 1, 32);
    float sqBase = max(_SquareSize, 1e-4);
    float miniW = sqBase * saturate(_MiniRectWidthScale);
    float miniH = sqBase * saturate(_MiniRectHeightScale);
    if (lineYMax > lineYMin && liMax.x > liMin.x && riMax.x > riMin.x)
    {
        [loop]
        for (int idx = 0; idx < 32; idx++)
        {
            if (idx >= count) break;

            // Same line Y for both boxes so they move together.
            float ly0 = StratifiedY01(idx, count, stateIndex, 0.0, 11.0);
            float ly1 = StratifiedY01(idx, count, stateIndex + 1.0, 0.0, 11.0);
            float lineY = lerp(lineYMin, lineYMax, lerp(ly0, ly1, blend01));

            lineMask = max(lineMask, EvaHLineMask(uv, liMin.x, liMax.x, lineY, _LineThickness));
            lineMask = max(lineMask, EvaHLineMask(uv, riMin.x, riMax.x, lineY, _LineThickness));

            float scaleFade = 1.0;
            float markState = MarkerDisplayState(stateIndex, blend01, scaleFade);
            if (markState >= 0.0)
            {
                float sq = sqBase * scaleFade;
                if (sq <= 1e-5) continue;

                // Left squares: outside on the opposite side (to the right of left stroke box).
                float ly01 = StratifiedY01(idx, count, markState, 0.0, 53.0);
                float lYMin = leftMin.y + sqBase * 0.5;
                float lYMax = leftMax.y - sqBase * 0.5;
                if (lYMax > lYMin)
                {
                    float lcy = lerp(lYMin, lYMax, ly01);
                    float lcx = leftMax.x + _OutsideGap + sqBase * 0.5;
                    float lOn = step(RandElem(idx, markState, 0.0, 71.0), saturate(_SquareOnProbability));
                    if (lOn > 0.5)
                    {
                        float2 lmn = float2(lcx - sq * 0.5, lcy - sq * 0.5);
                        float2 lmx = float2(lcx + sq * 0.5, lcy + sq * 0.5);
                        markerMask = max(markerMask, EvaRectFillMask(uv, lmn, lmx));
                    }
                }

                // Right squares: outside on the opposite side (to the left of right stroke box).
                float ry01 = StratifiedY01(idx, count, markState, 1.0, 53.0);
                float rYMin = rightMin.y + sqBase * 0.5;
                float rYMax = rightMax.y - sqBase * 0.5;
                if (rYMax > rYMin)
                {
                    float rcy = lerp(rYMin, rYMax, ry01);
                    float rcx = rightMin.x - _OutsideGap - sqBase * 0.5;
                    float rOn = step(RandElem(idx, markState, 1.0, 71.0), saturate(_SquareOnProbability));
                    if (rOn > 0.5)
                    {
                        float2 rmn = float2(rcx - sq * 0.5, rcy - sq * 0.5);
                        float2 rmx = float2(rcx + sq * 0.5, rcy + sq * 0.5);
                        markerMask = max(markerMask, EvaRectFillMask(uv, rmn, rmx));
                    }
                }
            }
        }

        // Independent mini stack lines:
        // line positions are fixed (even spacing by miniLineCount),
        // only mini boxes move between lines on morph.
        if (miniW > 1e-5 && miniH > 1e-5 && miniRange > 0)
        {
            [loop]
            for (int idx = 0; idx < 32; idx++)
            {
                if (idx >= miniLineCount) break;

                int lStack = miniMin + (int)floor(RandElem(idx, 0.0, 0.0, 83.0) * (float)miniRange);
                int rStack = miniMin + (int)floor(RandElem(idx, 0.0, 1.0, 83.0) * (float)miniRange);
                lStack = clamp(lStack, 0, 12);
                rStack = clamp(rStack, 0, 12);

                float lStart = leftMax.x + _OutsideGap + sqBase + _MiniLineGap + miniW * 0.5;
                float rStart = rightMin.x - _OutsideGap - sqBase - _MiniLineGap - miniW * 0.5;

                [loop]
                for (int s = 0; s < 12; s++)
                {
                    if (s < lStack)
                    {
                        int keyL = idx * 17 + s;
                        int lLineA = (int)floor(RandElem(keyL, stateIndex, 0.0, 121.0) * (float)miniLineCount);
                        int lLineB = (int)floor(RandElem(keyL, stateIndex + 1.0, 0.0, 121.0) * (float)miniLineCount);
                        float lcy = lerp(
                            EvenYFromLine(lLineA, miniLineCount, lineYMin, lineYMax),
                            EvenYFromLine(lLineB, miniLineCount, lineYMin, lineYMax),
                            blend01
                        );

                        float cx = lStart + (float)s * (miniW + _MiniRectSpacing);
                        float2 mmn = float2(cx - miniW * 0.5, lcy - miniH * 0.5);
                        float2 mmx = float2(cx + miniW * 0.5, lcy + miniH * 0.5);
                        miniMask = max(miniMask, EvaRectBorderMask(uv, mmn, mmx, _MiniStrokeThickness));
                    }

                    if (s < rStack)
                    {
                        int keyR = idx * 19 + s;
                        int rLineA = (int)floor(RandElem(keyR, stateIndex, 1.0, 121.0) * (float)miniLineCount);
                        int rLineB = (int)floor(RandElem(keyR, stateIndex + 1.0, 1.0, 121.0) * (float)miniLineCount);
                        float rcy = lerp(
                            EvenYFromLine(rLineA, miniLineCount, lineYMin, lineYMax),
                            EvenYFromLine(rLineB, miniLineCount, lineYMin, lineYMax),
                            blend01
                        );

                        float cx = rStart - (float)s * (miniW + _MiniRectSpacing);
                        float2 mmn = float2(cx - miniW * 0.5, rcy - miniH * 0.5);
                        float2 mmx = float2(cx + miniW * 0.5, rcy + miniH * 0.5);
                        miniMask = max(miniMask, EvaRectBorderMask(uv, mmn, mmx, _MiniStrokeThickness));
                    }
                }
            }
        }
    }

    fixed4 col = _BackgroundColor;
    col.rgb = lerp(col.rgb, _StrokeColor.rgb, strokeMask * _StrokeColor.a);
    col.rgb = lerp(col.rgb, _LineColor.rgb, lineMask * _LineColor.a);
    col.rgb = lerp(col.rgb, _MarkerColor.rgb, markerMask * _MarkerColor.a);
    col.rgb = lerp(col.rgb, _MiniStrokeColor.rgb, miniMask * _MiniStrokeColor.a);

    float shapeA = 0.0;
    shapeA = max(shapeA, strokeMask * _StrokeColor.a);
    shapeA = max(shapeA, lineMask * _LineColor.a);
    shapeA = max(shapeA, markerMask * _MarkerColor.a);
    shapeA = max(shapeA, miniMask * _MiniStrokeColor.a);
    col.a = saturate(max(_BackgroundColor.a, shapeA));

    return col;
}

#endif
