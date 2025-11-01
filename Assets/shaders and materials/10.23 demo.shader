Shader "Custom/10.23demo"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _CutOutLocation("CutOut Location", Vector) = (0,0,0,0)
        _CutOutRadius("CutOut Radius", Float) = 1
    }

    SubShader
    {
        // Tags identify the shader purpose and where and when it should run, these are required for URP
        Tags {
            "RenderType" = "Opaque" // Shader sequencing (sort of)
            "RenderPipeline" = "UniversalPipeline" //shader is targeted for URP
            "LightMode" = "UniversalForward"
        }

        // Run once per object
        Pass
        {
            // Inside here is entirely HLSL Code
            HLSLPROGRAM

            // Preprocessor directives to define the vertex and fragment functions
            #pragma vertex vert 
            #pragma fragment frag

            // Multi compile directives to enbable lighting and shadow functions within URP
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            // Preprocessor directions to include additional libraries. These basically copy and paste code from the files here
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/JasonNoise.hlsl"

            // Properties used for the shader. Notice that they match the ones in the Properties block above
            // They *must* be declared here again to be used in the shader code
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float4 _CutOutLocation;
            float _CutOutRadius;
            float4 _BaseColor;

            
            // This comes from outside of the shader
            // The allcaps term after the : is called a SEMANTIC, which tells the GPU what variables to put into the shader
            struct Attributes
            {
                // Position object space positionOS
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            // This is calculated in the shader's vertex function and passed to the fragment function
            // The term varyings is used because they vary per pixel and also change between the vertex and fragment stages
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // This is a unique semantic for the final vertex position in Homogeneous Clip Space
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); //transform the vertex's object space position to homogeneous clip space (screen)
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz); // transform the vertex's object space position to world space

                OUT.uv = IN.uv;
                return OUT; //return an instance of the Varyings struct
            }

            // You might see something called v2f (now varyings) in built in shaders
            half4 frag(Varyings IN) : SV_Target //note that this *function* has a SV_Target semantic, meaning it is the final output color of the pixel
            {
                half3 color = _BaseColor.rgb;
                float dist = distance(IN.worldPos.xyz, _CutOutLocation.xyz);
                float angle = atan2(IN.worldPos.z - _CutOutLocation.z, IN.worldPos.x - _CutOutLocation.x);
                float2 noiseCoord = float2(sin(angle + _Time.y), dist);
                float2 noiseCoord2 = float2(cos(angle - _Time.y), dist+362);
                dist += fBM(noiseCoord) * 0.3 - fBM(noiseCoord2) * 0.3;
                
                if (dist < _CutOutRadius) clip (-1);
                float cutOutRing = _CutOutRadius + 0.25;
                float ringFade = smoothstep(_CutOutRadius, cutOutRing, dist);
                color = lerp(half3(3,1.5, 0.5), color, ringFade);

                return half4(color, 1);
            }
            ENDHLSL
        }

        // Shadows require an additional pass, which writes data to a shadow map which the shader samples in the above pass
        // This is a copy-pase of the one from the documentation
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
 