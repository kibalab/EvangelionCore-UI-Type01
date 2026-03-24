#ifndef EVANGELIONCORE_NODE_GRAPH_CORE_INCLUDED
#define EVANGELIONCORE_NODE_GRAPH_CORE_INCLUDED

uint HashU32(uint x)
{
    x ^= (x >> 16);
    x *= 0x7feb352du;
    x ^= (x >> 15);
    x *= 0x846ca68bu;
    x ^= (x >> 16);
    return x;
}

uint MixSeed(uint seed, uint value)
{
    return HashU32(seed ^ (value + 0x9e3779b9u + (seed << 6) + (seed >> 2)));
}

uint BuildSeed4U(uint a, uint b, uint c, uint d)
{
    uint s = 0x811c9dc5u;
    s = MixSeed(s, a);
    s = MixSeed(s, b);
    s = MixSeed(s, c);
    s = MixSeed(s, d);
    return s;
}

uint UserSeedU()
{
    float seedValue = _RandomSeed;
    uint baseSeed = (uint)floor(abs(seedValue) * 4096.0 + 0.5);
    if (seedValue < 0.0)
    {
        baseSeed ^= 0x9e3779b9u;
    }
    return HashU32(baseSeed ^ 0xa511e9b3u);
}

float Hash01(uint seed)
{
    uint h = HashU32(seed);
    return (h & 0x00ffffffu) * (1.0 / 16777216.0);
}

float2 Hash02(uint seed)
{
    uint h0 = HashU32(seed);
    uint h1 = HashU32(h0 ^ 0x68bc21ebu);
    float inv = 1.0 / 16777216.0;
    return float2((h0 & 0x00ffffffu) * inv, (h1 & 0x00ffffffu) * inv);
}

float2 Rotate2D(float2 p, float rad)
{
    float s = sin(rad);
    float c = cos(rad);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void GetCycleState(out int stateIndex, out float phase, out float morphDuration)
{
    EvaGetCyclePhase(
        _Time.y + _LeadOffset,
        _MorphDuration,
        _HoldDuration,
        stateIndex,
        phase,
        morphDuration
    );
}

float MorphBlendForCube(int layer, int idx, float phase, float morphDuration)
{
    float staggerSec = saturate(_MorphStagger) * morphDuration;
    float delay = Hash01(BuildSeed4U(
        (uint)layer,
        (uint)idx,
        UserSeedU(),
        0xd37au
    )) * staggerSec;

    float localPhase = phase - delay;
    float blend01 = saturate(localPhase / morphDuration);
    blend01 = EvaMorphEase(blend01, _MorphElasticity);
    if (localPhase >= morphDuration)
    {
        blend01 = 1.0;
    }
    return blend01;
}

int GetLayerCount(int layer)
{
    int c = 0;
    if (layer == 0) c = (int)round(_Layer0Count);
    else if (layer == 1) c = (int)round(_Layer1Count);
    else c = (int)round(_Layer2Count);
    return clamp(c, 0, 24);
}

int GetLinksPerCube()
{
    return clamp((int)round(_LinksPerCube), 1, 3);
}

float LayerY(int layer)
{
    return _BaseHeight + (float)layer * _LayerSpacing;
}

float LayerAngleAtState(int layer, int stateIndex)
{
    uint userSeed = UserSeedU();
    float amount01 = Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x1657u
    ));
    float maxDeg = clamp(_MaxLayerRotation, 0.0, 45.0);
    float minDeg = clamp(_MinLayerRotation, 0.0, maxDeg);
    float magDeg = lerp(minDeg, maxDeg, amount01);
    float signPick = Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)(layer + 17),
        userSeed,
        0x3a29u
    ));
    float dir = (signPick < 0.5) ? -1.0 : 1.0;
    return radians(magDeg * dir);
}

float LerpAngleRad(float a, float b, float t)
{
    float delta = atan2(sin(b - a), cos(b - a));
    return a + delta * saturate(t);
}

void LayerGridSize(int count, out int nx, out int nz)
{
    float sx = max(_AreaSize.x, 1e-4);
    float sz = max(_AreaSize.y, 1e-4);
    float aspect = sx / sz;

    int safeCount = max(count, 1);
    nx = max(1, (int)ceil(sqrt((float)safeCount * aspect)));
    nz = max(1, (int)ceil((float)safeCount / (float)nx));
}

float2 LayerLocalXZAtState(int layer, int idx, int stateIndex)
{
    int count = GetLayerCount(layer);
    int nx;
    int nz;
    LayerGridSize(count, nx, nz);
    int slotCount = nx * nz;
    uint userSeed = UserSeedU();

    int offset = (int)floor(Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x4df3u
    )) * slotCount);

    // Bijective slot permutation for deterministic random layout.
    int p = (offset + (slotCount - 1 - (idx % slotCount))) % slotCount;
    int ix = p % nx;
    int iz = p / nx;

    int shear = (int)floor(Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x8c11u
    )) * nx);
    if (nx > 1)
    {
        ix = (ix + iz * shear) % nx;
    }

    int shiftX = (int)floor(Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x13a1u
    )) * nx);
    int shiftZ = (int)floor(Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x6b27u
    )) * nz);
    if (nx > 1) ix = (ix + shiftX) % nx;
    if (nz > 1) iz = (iz + shiftZ) % nz;

    if (Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0x91c7u
    )) > 0.5)
    {
        ix = (nx - 1) - ix;
    }
    if (Hash01(BuildSeed4U(
        (uint)stateIndex,
        (uint)layer,
        userSeed,
        0xc72du
    )) > 0.5)
    {
        iz = (nz - 1) - iz;
    }

    float2 cells = float2((float)nx, (float)nz);
    float2 cellSize = _AreaSize.xy / cells;
    float2 randomXZ = (float2((float)ix + 0.5, (float)iz + 0.5) / cells - 0.5) * _AreaSize.xy;
    int baseIx = idx % nx;
    int baseIz = idx / nx;
    float2 baseXZ = (float2((float)baseIx + 0.5, (float)baseIz + 0.5) / cells - 0.5) * _AreaSize.xy;
    float2 centerXZ = lerp(baseXZ, randomXZ, saturate(_LayoutRandomness));

    float2 jitter = Hash02(BuildSeed4U(
        (uint)idx,
        (uint)layer,
        (uint)stateIndex,
        userSeed ^ 0x2f15u
    )) * 2.0 - 1.0;
    centerXZ += jitter * (cellSize * (clamp(_SpacingJitter, 0.0, 0.45) * 0.5));

    return centerXZ;
}

float3 CubeCenter(int layer, int idx)
{
    int stateIndex;
    float phase;
    float morphDuration;
    GetCycleState(stateIndex, phase, morphDuration);
    float blend01 = MorphBlendForCube(layer, idx, phase, morphDuration);

    float2 xz0 = LayerLocalXZAtState(layer, idx, stateIndex);
    float2 xz1 = LayerLocalXZAtState(layer, idx, stateIndex + 1);
    float2 localXZ = lerp(xz0, xz1, blend01);

    float angle0 = LayerAngleAtState(layer, stateIndex);
    float angle1 = LayerAngleAtState(layer, stateIndex + 1);
    float angle = LerpAngleRad(angle0, angle1, blend01);

    float2 rotatedXZ = Rotate2D(localXZ, angle);
    return float3(rotatedXZ.x, LayerY(layer), rotatedXZ.y);
}

float3 CurvePointInOutCubic(float3 a, float3 b, float t)
{
    float txz = 0.0;
    float3 delta = b - a;
    float deltaLenSq = dot(delta, delta);
    float verticality = (deltaLenSq > 1e-8) ? saturate(abs(delta.y) * rsqrt(deltaLenSq)) : 1.0;
    // For strongly horizontal links (high spacing jitter), reduce endpoint lock so
    // the curve departs immediately instead of appearing detached near cube edges.
    float lockScale = lerp(0.2, 1.0, verticality);
    float lockT = min(saturate(_CurveEndpointLock) * lockScale, 0.49);
    if (lockT <= 1e-4)
    {
        txz = EvaEaseInOutCubic(t);
    }
    else if (t <= lockT)
    {
        txz = 0.0;
    }
    else if (t >= 1.0 - lockT)
    {
        txz = 1.0;
    }
    else
    {
        float u = (t - lockT) / max(1.0 - 2.0 * lockT, 1e-4);
        txz = EvaEaseInOutCubic(u);
    }

    return float3(
        lerp(a.x, b.x, txz),
        lerp(a.y, b.y, t),
        lerp(a.z, b.z, txz)
    );
}

int ConnectionTargetIndex(int fromLayer, int toLayer, int fromIdx, int linkIdx, int toCount)
{
    int safeToCount = max(toCount, 1);
    int links = GetLinksPerCube();
    int baseOffset = (int)floor(Hash01(BuildSeed4U(
        (uint)fromLayer,
        (uint)toLayer,
        UserSeedU(),
        0x7b91u
    )) * safeToCount);
    int stride = max(1, safeToCount / max(links, 1));
    int idx = (baseOffset + fromIdx + linkIdx * stride + linkIdx * linkIdx) % safeToCount;
    return idx;
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

void EmitCube(float3 center, float size, fixed4 color, inout TriangleStream<g2f> stream)
{
    float h = size * 0.5;

    float3 p000 = center + float3(-h, -h, -h);
    float3 p001 = center + float3(-h, -h,  h);
    float3 p010 = center + float3(-h,  h, -h);
    float3 p011 = center + float3(-h,  h,  h);
    float3 p100 = center + float3( h, -h, -h);
    float3 p101 = center + float3( h, -h,  h);
    float3 p110 = center + float3( h,  h, -h);
    float3 p111 = center + float3( h,  h,  h);

    EmitTri(p001, p101, p111, color, stream);
    EmitTri(p001, p111, p011, color, stream);

    EmitTri(p100, p000, p010, color, stream);
    EmitTri(p100, p010, p110, color, stream);

    EmitTri(p000, p001, p011, color, stream);
    EmitTri(p000, p011, p010, color, stream);

    EmitTri(p101, p100, p110, color, stream);
    EmitTri(p101, p110, p111, color, stream);

    EmitTri(p010, p011, p111, color, stream);
    EmitTri(p010, p111, p110, color, stream);

    EmitTri(p000, p100, p101, color, stream);
    EmitTri(p000, p101, p001, color, stream);
}

void BuildAnchoredConnection(
    float3 centerA,
    float3 centerB,
    out float3 anchorA,
    out float3 anchorB,
    out float3 connDir)
{
    float halfSize = max(_CubeSize * 0.5, 1e-4);
    float3 delta = centerB - centerA;
    float lenSq = dot(delta, delta);
    connDir = (lenSq > 1e-8) ? (delta * rsqrt(lenSq)) : float3(0.0, 1.0, 0.0);

    float maxComp = max(max(abs(connDir.x), abs(connDir.y)), abs(connDir.z));
    float t = halfSize / max(maxComp, 1e-4);

    anchorA = centerA + connDir * t;
    anchorB = centerB - connDir * t;
}

void EmitCurveSegment(
    float3 p0,
    float3 p1,
    float3 referenceDir,
    float thickness,
    fixed4 color,
    inout TriangleStream<g2f> stream)
{
    float3 seg = p1 - p0;
    float segLenSq = dot(seg, seg);
    float3 dir = (segLenSq > 1e-8) ? (seg * rsqrt(segLenSq)) : referenceDir;

    float3 up = (abs(dir.y) < 0.95) ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
    float3 n = cross(up, dir);
    float nLenSq = dot(n, n);
    if (nLenSq <= 1e-8)
    {
        n = float3(0.0, 0.0, 1.0);
    }
    else
    {
        n *= rsqrt(nLenSq);
    }
    float3 b = normalize(cross(dir, n));

    float r = max(thickness, 0.0025) * 0.5;
    float3 nr = n * r;
    float3 br = b * r;

    float3 a0 = p0 - nr - br;
    float3 a1 = p0 + nr - br;
    float3 a2 = p0 + nr + br;
    float3 a3 = p0 - nr + br;

    float3 c0 = p1 - nr - br;
    float3 c1 = p1 + nr - br;
    float3 c2 = p1 + nr + br;
    float3 c3 = p1 - nr + br;

    // Side faces.
    EmitTri(a0, a1, c1, color, stream);
    EmitTri(a0, c1, c0, color, stream);
    EmitTri(a1, a2, c2, color, stream);
    EmitTri(a1, c2, c1, color, stream);
    EmitTri(a2, a3, c3, color, stream);
    EmitTri(a2, c3, c2, color, stream);
    EmitTri(a3, a0, c0, color, stream);
    EmitTri(a3, c0, c3, color, stream);

    // End caps to guarantee visible contact with cubes.
    EmitTri(a0, a3, a2, color, stream);
    EmitTri(a0, a2, a1, color, stream);
    EmitTri(c0, c1, c2, color, stream);
    EmitTri(c0, c2, c3, color, stream);
}

[maxvertexcount(108)]
void geom_cubes(
    triangle v2g IN[3],
    uint primID : SV_PrimitiveID,
    inout TriangleStream<g2f> stream)
{
    int c0 = GetLayerCount(0);
    int c1 = GetLayerCount(1);
    int c2 = GetLayerCount(2);
    int total = c0 + c1 + c2;

    const int TASKS_PER_PRIM = 3;
    int baseTask = (int)primID * TASKS_PER_PRIM;
    [unroll]
    for (int localTask = 0; localTask < TASKS_PER_PRIM; localTask++)
    {
        int task = baseTask + localTask;
        if (task >= total) break;

        int layer = 0;
        int idx = task;
        if (task >= c0 + c1)
        {
            layer = 2;
            idx = task - (c0 + c1);
        }
        else if (task >= c0)
        {
            layer = 1;
            idx = task - c0;
        }

        float3 center = CubeCenter(layer, idx);
        EmitCube(center, _CubeSize, _CubeColor, stream);
    }
}

[maxvertexcount(108)]
void geom_curve01(
    triangle v2g IN[3],
    uint primID : SV_PrimitiveID,
    inout TriangleStream<g2f> stream)
{
    int c0 = GetLayerCount(0);
    int c1 = GetLayerCount(1);
    if (c0 <= 0 || c1 <= 0) return;

    int links = GetLinksPerCube();
    int pairCount = c0 * links;
    int segCount = clamp((int)round(_CurveSegments), 2, 8);
    int totalTasks = pairCount * segCount;

    const int TASKS_PER_PRIM = 3;
    int baseTask = (int)primID * TASKS_PER_PRIM;
    [unroll]
    for (int localTask = 0; localTask < TASKS_PER_PRIM; localTask++)
    {
        int task = baseTask + localTask;
        if (task >= totalTasks) break;

        int connectionIdx = task / segCount;
        int segIdx = task - connectionIdx * segCount;
        int fromIdx = connectionIdx / links;
        int linkIdx = connectionIdx - fromIdx * links;

        float t0 = segIdx / (float)segCount;
        float t1 = (segIdx + 1) / (float)segCount;

        int toIdx = ConnectionTargetIndex(0, 1, fromIdx, linkIdx, c1);
        float3 centerA = CubeCenter(0, fromIdx);
        float3 centerB = CubeCenter(1, toIdx);
        float3 a;
        float3 b;
        float3 connDir;
        BuildAnchoredConnection(centerA, centerB, a, b, connDir);

        float3 p0 = (segIdx == 0) ? a : CurvePointInOutCubic(a, b, t0);
        float3 p1 = (segIdx == segCount - 1) ? b : CurvePointInOutCubic(a, b, t1);
        float3 segDelta = p1 - p0;
        float3 segDir = (dot(segDelta, segDelta) > 1e-8) ? normalize(segDelta) : connDir;
        EmitCurveSegment(p0, p1, segDir, _CurveThickness, _LineColor, stream);
    }
}

[maxvertexcount(108)]
void geom_curve12(
    triangle v2g IN[3],
    uint primID : SV_PrimitiveID,
    inout TriangleStream<g2f> stream)
{
    int c1 = GetLayerCount(1);
    int c2 = GetLayerCount(2);
    if (c1 <= 0 || c2 <= 0) return;

    int links = GetLinksPerCube();
    int pairCount = c1 * links;
    int segCount = clamp((int)round(_CurveSegments), 2, 8);
    int totalTasks = pairCount * segCount;

    const int TASKS_PER_PRIM = 3;
    int baseTask = (int)primID * TASKS_PER_PRIM;
    [unroll]
    for (int localTask = 0; localTask < TASKS_PER_PRIM; localTask++)
    {
        int task = baseTask + localTask;
        if (task >= totalTasks) break;

        int connectionIdx = task / segCount;
        int segIdx = task - connectionIdx * segCount;
        int fromIdx = connectionIdx / links;
        int linkIdx = connectionIdx - fromIdx * links;

        float t0 = segIdx / (float)segCount;
        float t1 = (segIdx + 1) / (float)segCount;

        int toIdx = ConnectionTargetIndex(1, 2, fromIdx, linkIdx, c2);
        float3 centerA = CubeCenter(1, fromIdx);
        float3 centerB = CubeCenter(2, toIdx);
        float3 a;
        float3 b;
        float3 connDir;
        BuildAnchoredConnection(centerA, centerB, a, b, connDir);

        float3 p0 = (segIdx == 0) ? a : CurvePointInOutCubic(a, b, t0);
        float3 p1 = (segIdx == segCount - 1) ? b : CurvePointInOutCubic(a, b, t1);
        float3 segDelta = p1 - p0;
        float3 segDir = (dot(segDelta, segDelta) > 1e-8) ? normalize(segDelta) : connDir;
        EmitCurveSegment(p0, p1, segDir, _CurveThickness, _LineColor, stream);
    }
}

#endif
