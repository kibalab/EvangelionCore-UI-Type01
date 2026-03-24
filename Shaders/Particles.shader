Shader "EvangelionCore/Particles"
{
    Properties
    {
        [Header(Color)]
        _ColorA ("Particle Color A", Color) = (1.0, 0.52, 0.10, 1.0)
        _ColorB ("Particle Color B", Color) = (0.10, 0.72, 1.00, 1.0)
        _ColorAProbability ("Color A Probability", Range(0, 1)) = 0.5

        [Header(Volume)]
        _ParticlesPerTriangle ("Particles Per Triangle (Expected)", Range(0, 21)) = 8
        _SpawnChance ("Spawn Chance", Range(0, 1)) = 1.0
        _VolumeCenter ("Volume Center XYZ", Vector) = (0.0, 1.4, 0.0, 0.0)
        _VolumeSize ("Volume Size XYZ", Vector) = (9.0, 3.0, 9.0, 0.0)
        _ParticleWidthRange ("Particle Width Min/Max", Vector) = (0.08, 0.22, 0, 0)
        _ParticleHeightRange ("Particle Height Min/Max", Vector) = (0.16, 0.52, 0, 0)

        [Header(Flow Wash)]
        _FlowDirection ("Flow Direction XYZ", Vector) = (1.0, 0.0, 1.0, 0.0)
        _FlowSpeed ("Flow Speed (cycles/sec)", Float) = 0.75
        _FlowSpatialScale ("Flow Spatial Scale", Float) = 1.35
        _MorphElasticity ("Morph Quint Blend", Range(0, 1)) = 0.90
        _FlowHeadWidth ("Flow Head Width", Range(0.01, 0.35)) = 0.08
        _FlowTailLength ("Flow Tail Length", Range(0.02, 0.95)) = 0.42
        _FlowJitter ("Flow Time Jitter", Range(0, 0.35)) = 0.08
        _DriftDistance ("Drift Distance", Float) = 0.42
        _VerticalBob ("Vertical Bob", Float) = 0.16

        [Header(Random)]
        _Seed ("Random Seed", Float) = 0.0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 260
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Particles"

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma geometry geom_particles
            #pragma fragment frag
            #include "cginc/ParticlesCore.cginc"
            ENDCG
        }
    }

    FallBack Off
}
