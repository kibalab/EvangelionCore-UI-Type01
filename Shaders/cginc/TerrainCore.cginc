#ifndef EVANGELIONCORE_TERRAIN_CORE_INCLUDED
#define EVANGELIONCORE_TERRAIN_CORE_INCLUDED

float Hash21(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float2 Hash22(float2 p)
{
    float x = sin(dot(p, float2(127.1, 311.7))) * 43758.5453123;
    float y = sin(dot(p, float2(269.5, 183.3))) * 43758.5453123;
    return frac(float2(x, y));
}

float ValueNoise2D(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = Hash21(i);
    float b = Hash21(i + float2(1.0, 0.0));
    float c = Hash21(i + float2(0.0, 1.0));
    float d = Hash21(i + float2(1.0, 1.0));

    float ab = lerp(a, b, u.x);
    float cd = lerp(c, d, u.x);
    return lerp(ab, cd, u.y);
}

void GetCycleState(out float cycleIndex, out float blend01)
{
    EvaGetCycleState(
        _Time.y,
        _MorphDuration,
        _HoldDuration,
        _MorphElasticity,
        cycleIndex,
        blend01
    );
}

float SampleStateNoise(float2 cell, float stateIndex)
{
    float stateT = stateIndex + (_NoiseSeed * 17.0);
    float2 stateOffset = Hash22(float2(stateT, stateT + 31.0)) * 256.0;

    float2 p = cell * max(_TerrainFrequency, 1e-4) + stateOffset;

    float2 warpUV = p * 0.57 + float2(17.3, 41.9);
    float2 warp = float2(
        ValueNoise2D(warpUV),
        ValueNoise2D(warpUV + float2(73.1, 29.4))
    ) * 2.0 - 1.0;
    p += warp * _TerrainWarp;

    float n0 = ValueNoise2D(p);
    float n1 = ValueNoise2D(p * 2.07 + float2(13.7, -8.4));
    float n2 = ValueNoise2D(p * 4.31 + float2(-27.4, 15.9));
    float n = n0 * 0.62 + n1 * 0.28 + n2 * 0.10;

    float bias = (Hash21(float2(stateT, 91.7)) - 0.5) * (_TerrainBiasJitter * 2.0);
    n = saturate((n - 0.5) * _TerrainContrast + 0.5 + bias);
    return n;
}

float GetHeight01(float2 cell)
{
    float stateIndex;
    float blend01;
    GetCycleState(stateIndex, blend01);

    float n0 = SampleStateNoise(cell, stateIndex);
    float n1 = SampleStateNoise(cell, stateIndex + 1.0);
    return lerp(n0, n1, blend01);
}

float GetHeight(float2 cell, out float height01)
{
    height01 = GetHeight01(cell);
    return lerp(_HeightMin, _HeightMax, height01);
}

#endif
