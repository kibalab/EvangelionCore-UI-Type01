Shader "EvangelionCore/NodeGraph"
{
    Properties
    {
        [Header(Color)]
        _CubeColor ("Cube Color", Color) = (1.0, 0.46, 0.05, 1.0)
        _LineColor ("Curve Color", Color) = (1.0, 0.52, 0.08, 1.0)

        [Header(Counts)]
        _Layer0Count ("Layer 0 Cube Count", Range(0, 24)) = 10
        _Layer1Count ("Layer 1 Cube Count", Range(0, 24)) = 10
        _Layer2Count ("Layer 2 Cube Count", Range(0, 24)) = 10

        [Header(Layout)]
        _BaseHeight ("Layer 0 Height", Float) = 0.4
        _LayerSpacing ("Layer Spacing", Float) = 0.95
        _AreaSize ("Spawn Area Size XZ", Vector) = (6.0, 6.0, 0, 0)
        _CubeSize ("Cube Size", Float) = 0.16
        _SpacingJitter ("Spacing Jitter", Range(0, 0.45)) = 0.12
        _CurveThickness ("Curve Thickness", Float) = 0.05
        _CurveSegments ("Curve Segments", Range(2, 8)) = 6
        _LinksPerCube ("Links Per Cube", Range(1, 3)) = 2
        _CurveEndpointLock ("Curve Endpoint Lock", Range(0, 0.35)) = 0.18
        _LayoutRandomness ("Layout Randomness", Range(0, 1)) = 0.65
        _MinLayerRotation ("Min Layer Rotation (deg)", Range(0, 45)) = 12
        _MaxLayerRotation ("Max Layer Rotation (deg)", Range(0, 45)) = 45

        [Header(Timing)]
        _MorphDuration ("Morph Duration (sec)", Float) = 1.0
        _HoldDuration ("Hold Duration (sec)", Float) = 3.0
        _LeadOffset ("Lead Offset (sec)", Float) = 0.5
        _MorphStagger ("Morph Stagger", Range(0, 0.6)) = 0.18
        _MorphElasticity ("Morph Quint Blend", Range(0, 1)) = 0.90
        _RandomSeed ("Random Seed", Float) = 0.0
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }
        LOD 300

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "cginc/MorphEasing.cginc"

        fixed4 _CubeColor;
        fixed4 _LineColor;

        float _Layer0Count;
        float _Layer1Count;
        float _Layer2Count;

        float _BaseHeight;
        float _LayerSpacing;
        float4 _AreaSize;
        float _CubeSize;
        float _SpacingJitter;
        float _CurveThickness;
        float _CurveSegments;
        float _LinksPerCube;
        float _CurveEndpointLock;
        float _LayoutRandomness;
        float _MinLayerRotation;
        float _MaxLayerRotation;

        float _MorphDuration;
        float _HoldDuration;
        float _LeadOffset;
        float _MorphStagger;
        float _MorphElasticity;
        float _RandomSeed;

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

        fixed4 frag(g2f i) : SV_Target
        {
            return i.color;
        }

        #include "cginc/NodeGraphCore.cginc"
        ENDCG

        Pass
        {
            Name "Cubes"
            Cull Off
            ZWrite On

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma geometry geom_cubes
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            Name "Curves01"
            Cull Off
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma geometry geom_curve01
            #pragma fragment frag
            ENDCG
        }

        Pass
        {
            Name "Curves12"
            Cull Off
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma geometry geom_curve12
            #pragma fragment frag
            ENDCG
        }
    }

    FallBack Off
}
