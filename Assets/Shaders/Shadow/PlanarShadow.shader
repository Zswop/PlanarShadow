Shader "Picoverse/PlanarShadow"
{
    Properties
    {
        _ShadowColor("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowPlaneNormal("Shadow Plane Normal(xyz)", Vector) = (0, 1, 0, 0)
        _ShadowPlanePosition("Shadow Plane Position(xyz)", Vector) = (0, 0, 0, 0)
        _ShadowFadeScale("Shadow Fade Scale", Float) = 0
        
        [Toggle(_HEIGHTMAP)]  _EnableHeightMap("Enable Height", Float) = 0
        _HeightMap("Height Map", 2D) = "black" {}
        _MaxHeight("Max Height", Range(0, 10)) = 0.5
        
        [Toggle(_VERTICALOFFSET)]  _VerticalOffset("Vertical Offset", Float) = 0
        _HorizontalBias("Horizontal Bias", Range(0.0, 4.0)) = 0
        
        _ShadowStencil("Planar Shadow Stencil Value", Float) = 15
    }

    SubShader
    {
        Tags {"RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "PlanarShadow"
            Tags{"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha
            Zwrite Off
            Cull Front
            Stencil 
            {
                Ref [_ShadowStencil]
                Comp NotEqual
                Pass Replace
                Fail Keep
            }
            
            // Sets the depth offset for this geometry so that the GPU draws this geometry closer to the camera
            // You would typically do this to avoid z-fighting
            Offset -1, -1

            HLSLPROGRAM

            #pragma multi_compile_vertex _ _HEIGHTMAP
            #pragma multi_compile_vertex _ _VERTICALOFFSET
           
            #pragma vertex PlanarShadowVertex
            #pragma fragment PlanarShadowFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _HeightMap_ST;
                half4 _ShadowColor;
                float4 _ShadowPlaneNormal;
                float4 _ShadowPlanePosition;
                float _ShadowFadeScale;
                float _HorizontalBias;
                float _MaxHeight;
            CBUFFER_END

            //float4 _MainLightPosition;
            
            #include "PlanarShadowPass.hlsl"
            
            ENDHLSL
        }
    }
}