#ifndef EVANGELIONCORE_MORPH_EASING_INCLUDED
#define EVANGELIONCORE_MORPH_EASING_INCLUDED

float EvaEaseInOutCubic(float t)
{
    t = saturate(t);
    if (t < 0.5) return 4.0 * t * t * t;
    float u = -2.0 * t + 2.0;
    return 1.0 - (u * u * u) * 0.5;
}

float EvaEaseInOutQuint(float t)
{
    t = saturate(t);
    if (t < 0.5) return 16.0 * t * t * t * t * t;
    float u = -2.0 * t + 2.0;
    return 1.0 - 0.5 * (u * u * u * u * u);
}

float EvaMorphEase(float t, float quintBlend)
{
    float base = EvaEaseInOutCubic(t);
    float quint = EvaEaseInOutQuint(t);
    return lerp(base, quint, saturate(quintBlend));
}

void EvaGetCycleState(
    float localTime,
    float morphDuration,
    float holdDuration,
    float quintBlend,
    out float stateIndex,
    out float blend01)
{
    float cycleLen = max(morphDuration + holdDuration, 1e-4);
    stateIndex = floor(localTime / cycleLen);

    float phase = frac(localTime / cycleLen) * cycleLen;
    float morphLen = max(morphDuration, 1e-4);
    blend01 = saturate(phase / morphLen);
    blend01 = EvaMorphEase(blend01, quintBlend);

    if (phase >= morphDuration)
    {
        blend01 = 1.0;
    }
}

void EvaGetCyclePhase(
    float localTime,
    float morphDuration,
    float holdDuration,
    out int stateIndex,
    out float phase,
    out float safeMorphDuration)
{
    float cycleLen = max(morphDuration + holdDuration, 1e-4);
    stateIndex = (int)floor(localTime / cycleLen);
    phase = frac(localTime / cycleLen) * cycleLen;
    safeMorphDuration = max(morphDuration, 1e-4);
}

#endif
