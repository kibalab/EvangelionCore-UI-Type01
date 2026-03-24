Shader "EvangelionCore/Terrain"
{
    Properties
    {
        [Header(Grid)]
        _GridColor ("Grid Line Color", Color) = (0.10, 0.45, 1.00, 1.00)
        _GridResolution ("Grid Resolution", Float) = 10
        _LineWidth ("Grid Line Width", Range(0.002, 0.2)) = 0.035
        _HeightMin ("Grid Height Min", Float) = 0.0
        _HeightMax ("Grid Height Max", Float) = 1.4

        [Header(Timing)]
        _MorphDuration ("Morph Duration (sec)", Float) = 1.0
        _HoldDuration ("Hold Duration (sec)", Float) = 3.0
        _MorphElasticity ("Morph Quint Blend", Range(0, 1)) = 0.92
        _NoiseSeed ("Noise Seed", Float) = 0.0
        _TerrainFrequency ("Terrain Frequency", Float) = 0.22
        _TerrainWarp ("Terrain Warp", Float) = 1.30
        _TerrainContrast ("Terrain Contrast", Range(0.2, 3.0)) = 1.35
        _TerrainBiasJitter ("Terrain Bias Jitter", Range(0, 0.5)) = 0.18

        [Header(Digits)]
        _DigitTex ("Digit Sheet (0-9 Horizontal)", 2D) = "white" {}
        _DigitColor ("Digit Color", Color) = (1, 1, 1, 1)
        _DigitPlaneWidth ("Digit Plane Width", Float) = 0.28
        _DigitPlaneHeight ("Digit Plane Height", Float) = 0.48
        _DigitFloatOffset ("Digit Float Offset", Float) = 0.10
        [Enum(Auto,0,Alpha,1,Luminance,2,InvertedLuminance,3)] _DigitMaskSource ("Digit Mask Source", Float) = 0
        _DigitAlphaCutoff ("Digit Alpha Cutoff", Range(0, 1)) = 0.01
        _DigitCount ("Digit Count In Sheet", Float) = 10
    }

    SubShader
    {
        Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" }
        Cull Off
        LOD 200

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "cginc/MorphEasing.cginc"
        #include "cginc/DigitSheet.cginc"

        fixed4 _GridColor;
        float _GridResolution;
        float _LineWidth;
        float _HeightMin;
        float _HeightMax;
        float _MorphDuration;
        float _HoldDuration;
        float _MorphElasticity;
        float _NoiseSeed;
        float _TerrainFrequency;
        float _TerrainWarp;
        float _TerrainContrast;
        float _TerrainBiasJitter;

        sampler2D _DigitTex;
        fixed4 _DigitColor;
        float _DigitPlaneWidth;
        float _DigitPlaneHeight;
        float _DigitFloatOffset;
        float _DigitMaskSource;
        float _DigitAlphaCutoff;
        float _DigitCount;

        #include "cginc/TerrainCore.cginc"
        ENDCG

        Pass
        {
            Name "GridWire"
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_grid
            #pragma fragment frag_grid
            #include "cginc/TerrainGridPass.cginc"
            ENDCG
        }

        Pass
        {
            Name "DigitPlanes"
            ZWrite On
            Offset -1, -1

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert_digits
            #pragma geometry geom_digits
            #pragma fragment frag_digits
            #include "cginc/TerrainDigitPass.cginc"
            ENDCG
        }
    }

    FallBack Off
}
