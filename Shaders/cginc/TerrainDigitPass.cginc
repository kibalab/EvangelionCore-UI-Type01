#ifndef EVANGELIONCORE_TERRAIN_DIGIT_PASS_INCLUDED
#define EVANGELIONCORE_TERRAIN_DIGIT_PASS_INCLUDED

struct appdata_digits
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2g_digits
{
    float3 localPos : TEXCOORD0;
    float2 uv : TEXCOORD1;
};

struct g2f_digits
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

v2g_digits vert_digits(appdata_digits v)
{
    v2g_digits o;
    o.localPos = v.vertex.xyz;
    o.uv = v.uv;
    return o;
}

void AppendDigitVertex(
    float3 worldPos,
    float2 uv,
    inout TriangleStream<g2f_digits> stream)
{
    g2f_digits o;
    o.pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
    o.uv = uv;
    stream.Append(o);
}

void EmitDigitQuad(
    float3 anchor,
    float digit,
    inout TriangleStream<g2f_digits> stream)
{
    EvaDigitBillboardQuad q = EvaBuildVerticalDigitBillboardQuad(
        anchor,
        _WorldSpaceCameraPos,
        _DigitPlaneWidth,
        _DigitPlaneHeight,
        digit
    );

    AppendDigitVertex(q.p0, q.uv0, stream);
    AppendDigitVertex(q.p1, q.uv1, stream);
    AppendDigitVertex(q.p2, q.uv2, stream);
    stream.RestartStrip();

    AppendDigitVertex(q.p0, q.uv0, stream);
    AppendDigitVertex(q.p2, q.uv2, stream);
    AppendDigitVertex(q.p3, q.uv3, stream);
    stream.RestartStrip();
}

[maxvertexcount(168)]
void geom_digits(
    triangle v2g_digits IN[3],
    inout TriangleStream<g2f_digits> stream)
{
    float res = max(1.0, round(_GridResolution));

    float2 uv0 = IN[0].uv;
    float2 uv1 = IN[1].uv;
    float2 uv2 = IN[2].uv;

    float h01v0;
    float h01v1;
    float h01v2;
    float h0 = GetHeight(round(uv0 * res), h01v0);
    float h1 = GetHeight(round(uv1 * res), h01v1);
    float h2 = GetHeight(round(uv2 * res), h01v2);

    float2 guv0 = uv0 * res;
    float2 guv1 = uv1 * res;
    float2 guv2 = uv2 * res;

    float minGX = min(guv0.x, min(guv1.x, guv2.x));
    float maxGX = max(guv0.x, max(guv1.x, guv2.x));
    float minGY = min(guv0.y, min(guv1.y, guv2.y));
    float maxGY = max(guv0.y, max(guv1.y, guv2.y));

    int startX = (int)ceil(minGX - 1e-4);
    int endX = (int)floor(maxGX + 1e-4);
    int startY = (int)ceil(minGY - 1e-4);
    int endY = (int)floor(maxGY + 1e-4);

    const float insideEps = -1e-4;
    const int maxQuadsPerTri = 28;
    int emittedQuads = 0;

    [loop]
    for (int y = startY; y <= endY; y++)
    {
        [loop]
        for (int x = startX; x <= endX; x++)
        {
            if (emittedQuads >= maxQuadsPerTri)
            {
                return;
            }

            float2 pUV = float2((float)x, (float)y) / res;
            float3 bary;
            if (!EvaComputeBarycentricUV(pUV, uv0, uv1, uv2, bary))
            {
                return;
            }

            if (min(bary.x, min(bary.y, bary.z)) < insideEps)
            {
                continue;
            }

            float3 localPos =
                IN[0].localPos * bary.x +
                IN[1].localPos * bary.y +
                IN[2].localPos * bary.z;

            float triSurfaceY =
                (IN[0].localPos.y + h0) * bary.x +
                (IN[1].localPos.y + h1) * bary.y +
                (IN[2].localPos.y + h2) * bary.z;

            float2 cell = float2((float)x, (float)y);
            float height01;
            float height = GetHeight(cell, height01);
            localPos.y = max(localPos.y + height, triSurfaceY) + _DigitFloatOffset + 0.002;

            float3 worldPos = mul(unity_ObjectToWorld, float4(localPos, 1.0)).xyz;
            float digit = floor(saturate(height01) * 9.9999);
            EmitDigitQuad(worldPos, digit, stream);
            emittedQuads++;
        }
    }
}

fixed4 frag_digits(g2f_digits i) : SV_Target
{
    float2 sheetUV = EvaDigitSheetUV(i.uv, _DigitCount);
    fixed4 texel = tex2D(_DigitTex, sheetUV);
    float mask = EvaDigitMaskFromTexel(texel, _DigitMaskSource);
    clip(mask - _DigitAlphaCutoff);

    return fixed4(_DigitColor.rgb, 1.0);
}

#endif
