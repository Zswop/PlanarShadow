#ifndef PICOVERSE_PLANAR_SHADOW_PASS_INCLUDED
#define PICOVERSE_PLANAR_SHADOW_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_HeightMap); SAMPLER(sampler_HeightMap);

struct Attributes
{
    float4 positionOS   : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    half4 shadowColor   : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
};

float3 GetShadowPositionWS(float3 positionOS, float offset)
{
    float3 shadowProjDir = _MainLightPosition.xyz;
    float3 planePositionWS = _ShadowPlanePosition.xyz;
    float3 planeNormalWS = _ShadowPlaneNormal.xyz;
    
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);
    planePositionWS += offset * planeNormalWS;
    
    float d1 = dot(shadowProjDir, planeNormalWS);
    float d2 = dot(planePositionWS - positionWS, planeNormalWS);
    return positionWS + shadowProjDir * (d2 /d1);
}

half GetShadowFade(float3 positionWS)
{
    float3 pivot = float3(GetObjectToWorldMatrix()._14_24_34);
    float3 pivotToShadow = positionWS - pivot;
    //pivotToShadow.y = 0;
    
    float fadeScale = _ShadowFadeScale;
    float distanceFade = sqrt(dot(pivotToShadow, pivotToShadow)) * fadeScale;
    
    float fade = smoothstep(1, 0, saturate(distanceFade));
    return fade;
}

float GetHeight(float3 positionWS)
{
    float offset = 0;
#if defined(_HEIGHTMAP)
    float2 uv = positionWS.xz * _HeightMap_ST.xy + _HeightMap_ST.zw;
    float height = _HeightMap.SampleLevel(sampler_HeightMap, uv, 0).x;
    return height * _MaxHeight;
    /*
    if (height > 0.75) offset += 0.5;
    else if (height > 0.7) offset += 0.25;
    else if (height > 0.55) offset += 0.10;
    else offset += 0; */
#endif   
    return offset;
}

float3 ApplyHeightOffset(float3 pos, float offset)
{
#ifndef _VERTICALOFFSET
    float3 dir = _MainLightPosition.xyz;
    float delta = offset / dot(float3(0.0, 1.0, 0.0), dir);
    return pos + delta * dir;
#else
    float3 dir = _MainLightPosition.xyz;
    float3 finalOffset = float3(0.0, offset, 0.0);
    finalOffset += _HorizontalBias * float3(dir.x, 0, dir.z);
    return pos + finalOffset;
#endif
}

Varyings PlanarShadowVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

#if defined(_HEIGHTMAP)
    float planeHeight = GetHeight(GetObjectToWorldMatrix()._14_24_34);
    float3 positionWS = GetShadowPositionWS(input.positionOS.xyz, planeHeight);

    float shadowHeight = GetHeight(positionWS);
    positionWS = ApplyHeightOffset(positionWS, shadowHeight - planeHeight);
    
#else
    float3 positionWS = GetShadowPositionWS(input.positionOS.xyz, 0.0);
#endif
    
    output.positionCS = TransformWorldToHClip(positionWS);
    output.shadowColor = _ShadowColor;
    output.shadowColor.a *= GetShadowFade(positionWS);
    
    return output;
}

half4 PlanarShadowFragment(Varyings input) : SV_TARGET
{
    // TODO: Alpha Clipping
    half4 color = input.shadowColor;
    return color;
}

#endif