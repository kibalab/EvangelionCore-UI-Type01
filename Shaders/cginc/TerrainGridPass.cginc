#ifndef EVANGELIONCORE_TERRAIN_GRID_PASS_INCLUDED
#define EVANGELIONCORE_TERRAIN_GRID_PASS_INCLUDED

struct appdata_grid
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f_grid
{
    float4 pos : SV_POSITION;
    float2 gridCoord : TEXCOORD0;
};

v2f_grid vert_grid(appdata_grid v)
{
    v2f_grid o;

    float2 gridCoord = v.uv * _GridResolution;
    float2 cell = round(gridCoord);

    float height01;
    float height = GetHeight(cell, height01);

    float3 localPos = v.vertex.xyz;
    localPos.y += height;

    o.pos = UnityObjectToClipPos(float4(localPos, 1.0));
    o.gridCoord = gridCoord;
    return o;
}

fixed4 frag_grid(v2f_grid i) : SV_Target
{
    float2 f = frac(i.gridCoord);
    float2 edge = min(f, 1.0 - f);
    float lineDist = min(edge.x, edge.y);
    float aa = fwidth(lineDist) + 1e-5;

    float lineMask = 1.0 - smoothstep(_LineWidth, _LineWidth + aa, lineDist);
    clip(lineMask - 0.001);

    return fixed4(_GridColor.rgb, _GridColor.a * lineMask);
}

#endif
