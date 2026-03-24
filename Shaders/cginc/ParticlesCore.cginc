#ifndef EVANGELIONCORE_PARTICLES_CORE_INCLUDED
#define EVANGELIONCORE_PARTICLES_CORE_INCLUDED

#include "UnityCG.cginc"
#include "MorphEasing.cginc"

fixed4 _ColorA;
fixed4 _ColorB;
float _ColorAProbability;

float _ParticlesPerTriangle;
float _SpawnChance;
float4 _VolumeCenter;
float4 _VolumeSize;
float4 _ParticleWidthRange;
float4 _ParticleHeightRange;

float4 _FlowDirection;
float _FlowSpeed;
float _FlowSpatialScale;
float _MorphElasticity;
float _FlowHeadWidth;
float _FlowTailLength;
float _FlowJitter;
float _DriftDistance;
float _VerticalBob;

float _Seed;

struct appdata
{
    float4 vertex : POSITION;
};

struct v2g
{
    float3 localPos : TEXCOORD0;
};

struct g2f
{
    float4 pos : SV_POSITION;
    fixed4 color : COLOR0;
};

v2g vert(appdata v)
{
    v2g o;
    o.localPos = v.vertex.xyz;
    return o;
}

uint HashU32(uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

uint InitRng(uint pid, uint salt)
{
    uint seedBits = asuint(_Seed * 16384.0 + 0.5);
    return HashU32(pid ^ (salt * 0x9e3779b9u) ^ seedBits ^ 0xa511e9b3u);
}

float NextRand01(inout uint state)
{
    state = HashU32(state + 0x9e3779b9u);
    return ((float)state + 0.5) * (1.0 / 4294967296.0);
}

float3 SafeNormalize(float3 v, float3 fallbackDir)
{
    float lenSq = dot(v, v);
    if (lenSq <= 1e-8) return fallbackDir;
    return v * rsqrt(lenSq);
}

float DirectionalGate(float phase01)
{
    float head = saturate(_FlowHeadWidth);
    float tail = max(_FlowTailLength, 1e-4);
    float activeWindow = min(head + tail, 0.999);
    return step(phase01, activeWindow);
}

void AppendVertex(float3 localPos, fixed4 color, inout TriangleStream<g2f> stream)
{
    g2f o;
    o.pos = UnityObjectToClipPos(float4(localPos, 1.0));
    o.color = color;
    stream.Append(o);
}

void EmitTri(float3 a, float3 b, float3 c, fixed4 color, inout TriangleStream<g2f> stream)
{
    AppendVertex(a, color, stream);
    AppendVertex(b, color, stream);
    AppendVertex(c, color, stream);
    stream.RestartStrip();
}

void EmitQuad(
    float3 center,
    float3 right,
    float3 up,
    float halfW,
    float halfH,
    fixed4 color,
    inout TriangleStream<g2f> stream)
{
    float3 p00 = center - right * halfW - up * halfH;
    float3 p10 = center + right * halfW - up * halfH;
    float3 p11 = center + right * halfW + up * halfH;
    float3 p01 = center - right * halfW + up * halfH;

    EmitTri(p00, p10, p11, color, stream);
    EmitTri(p00, p11, p01, color, stream);
}

[maxvertexcount(126)]
void geom_particles(
    triangle v2g IN[3],
    uint primID : SV_PrimitiveID,
    inout TriangleStream<g2f> stream)
{
    const int MAX_SLOTS = 21;
    float expectedPerTri = clamp(_ParticlesPerTriangle, 0.0, (float)MAX_SLOTS);
    float keepProb = saturate((expectedPerTri / (float)MAX_SLOTS) * saturate(_SpawnChance));

    float3 size = max(_VolumeSize.xyz, float3(1e-3, 1e-3, 1e-3));
    float3 halfSize = size * 0.5;
    float3 volumeMin = _VolumeCenter.xyz - halfSize;

    float3 flowDir = SafeNormalize(
        _FlowDirection.xyz,
        normalize(float3(1.0, 0.0, 1.0))
    );
    float span = max(dot(abs(flowDir), halfSize) * 2.0, 1e-4);

    float3 camLocal = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;

    [unroll]
    for (int k = 0; k < 21; k++)
    {
        int pid = (int)primID * MAX_SLOTS + k;

        uint rng = InitRng((uint)pid, 1u);
        float slotKeep = NextRand01(rng);
        if (slotKeep > keepProb) continue;

        float pidf = (float)(pid + 1);
        float3 cpRot = float3(NextRand01(rng), NextRand01(rng), NextRand01(rng));
        float3 r2 = frac(pidf * float3(0.754877666, 0.569840296, 0.438289127) + cpRot);
        float3 jitterRand = float3(NextRand01(rng), NextRand01(rng), NextRand01(rng));
        float3 pos01 = frac(r2 + (jitterRand - 0.5) * 0.24);

        float3 basePos = volumeMin + pos01 * size;

        float coord01 = (dot(basePos - _VolumeCenter.xyz, flowDir) + 0.5 * span) / span;
        coord01 = saturate(coord01);

        float jitter = (NextRand01(rng) * 2.0 - 1.0) * _FlowJitter;

        float phase = frac(_Time.y * _FlowSpeed - coord01 * _FlowSpatialScale + jitter);
        float gate = DirectionalGate(phase);
        if (gate < 0.5) continue;

        float activeWindow = min(saturate(_FlowHeadWidth) + max(_FlowTailLength, 1e-4), 0.999);
        float phase01 = saturate(phase / activeWindow);
        float easedPhase = EvaMorphEase(phase01, _MorphElasticity) * activeWindow;

        float drift = (1.0 - easedPhase) * _DriftDistance;
        float bob = sin((easedPhase + coord01 * 0.7 + jitter) * 6.28318530718) * _VerticalBob;

        float3 center = basePos + flowDir * drift;
        center.y += bob;

        float wr = NextRand01(rng);
        float hr = NextRand01(rng);
        float halfW = 0.5 * lerp(_ParticleWidthRange.x, _ParticleWidthRange.y, wr);
        float halfH = 0.5 * lerp(_ParticleHeightRange.x, _ParticleHeightRange.y, hr);

        float3 toCam = camLocal - center;
        float3 forward = SafeNormalize(toCam, float3(0.0, 0.0, 1.0));
        float3 right = SafeNormalize(cross(float3(0.0, 1.0, 0.0), forward), float3(1.0, 0.0, 0.0));
        float3 up = SafeNormalize(cross(forward, right), float3(0.0, 1.0, 0.0));

        float choose = NextRand01(rng);
        fixed4 col = (choose < saturate(_ColorAProbability)) ? _ColorA : _ColorB;
        if (col.a <= 1e-4) continue;

        EmitQuad(center, right, up, halfW, halfH, col, stream);
    }
}

fixed4 frag(g2f i) : SV_Target
{
    return i.color;
}

#endif
