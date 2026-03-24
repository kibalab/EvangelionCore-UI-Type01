Shader "EvangelionCore/UI"
{
    Properties
    {
        [Header(Color)]
        _BackgroundColor ("Background Color", Color) = (0, 0, 0, 0)
        _StrokeColor ("Stroke Box Color", Color) = (0.95, 0.45, 0.08, 1)
        _LineColor ("Inner Line Color", Color) = (1.00, 0.62, 0.16, 1)
        _MarkerColor ("Inner Box Color", Color) = (1.00, 0.72, 0.20, 1)

        [Header(Layout)]
        _ElementCount ("N (Lines/Boxes)", Range(1, 32)) = 10
        _SideMargin ("Side Margin", Range(0, 0.45)) = 0.05
        _StrokeBoxWidth ("Stroke Box Width", Range(0.02, 0.45)) = 0.12
        _VerticalInset ("Vertical Inset", Range(0, 0.3)) = 0.02
        _StrokeThickness ("Stroke Thickness", Range(0.001, 0.04)) = 0.004
        _InnerPadding ("Inner Padding", Range(0, 0.1)) = 0.01
        _LineThickness ("Line Thickness", Range(0.001, 0.03)) = 0.003
        _OutsideGap ("Outside Gap", Range(0, 0.06)) = 0.004
        _SquareSize ("Square Size", Range(0.008, 0.12)) = 0.045
        _SquareOnProbability ("Square On Probability", Range(0, 1)) = 0.85
        _SquareScaleFade ("Square Scale Fade (Morph Ratio)", Range(0.005, 0.12)) = 0.03
        _SquareSwitchGap ("Square Switch Gap (Morph Ratio)", Range(0.02, 0.25)) = 0.10
        _VerticalJitter ("Vertical Jitter", Range(0, 1)) = 0.9
        [Header(Mini Stack Line)]
        _MiniStrokeColor ("Mini Stroke Color", Color) = (1.0, 0.72, 0.20, 1)
        _MiniRectWidthScale ("Mini Width Scale", Range(0.1, 0.95)) = 0.42
        _MiniRectHeightScale ("Mini Height Scale", Range(0.1, 0.95)) = 0.30
        _MiniRectSpacing ("Mini Rect Spacing", Range(0, 0.04)) = 0.006
        _MiniLineGap ("Mini Line Gap From Square", Range(0, 0.05)) = 0.006
        _MiniStrokeThickness ("Mini Stroke Thickness", Range(0.0005, 0.02)) = 0.002
        _MiniLineCount ("Mini Stack Line Count", Range(1, 32)) = 10
        _MiniStackMin ("Mini Stack Min Count", Range(0, 12)) = 1
        _MiniStackMax ("Mini Stack Max Count", Range(0, 12)) = 4

        [Header(Timing)]
        _MorphDuration ("Morph Duration (sec)", Float) = 1.0
        _HoldDuration ("Hold Duration (sec)", Float) = 3.0
        _MorphElasticity ("Morph Quint Blend", Range(0, 1)) = 0.92
        _RandomSeed ("Random Seed", Float) = 0.0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Main"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "cginc/UICore.cginc"
            ENDCG
        }
    }

    FallBack Off
}
