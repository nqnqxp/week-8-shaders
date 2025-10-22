Shader "Custom/shader3UsingWorldPos"
{
    Properties
    {
        // [Attribute] _PropertyName("Display Name", Type) = DefaultValue
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white"
        _Target ("TargetPosition", Vector) = (0,0,0,0)
        _Intensity ("Intensity", Float) = 1
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

            // Properties used for the shader. Notice that they match the ones in the Properties block above
            // They *must* be declared here again to be used in the shader code
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float4 _Target;
            float _Intensity;

            
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
                float3 worldNormal : TEXCOORD2;
            };

            // You might see something called appdata (now Attributes) in built in shaders
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); //transform the vertex's object space position to homogeneous clip space (screen)
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz); // transform the vertex's object space position to world space
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normalOS); // transform the vertex's object space normal to world space

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap); // transform the uv based on tiling and offset values
                return OUT; //return an instance of the Varyings struct
            }

            float hash21(float2 v){
              return frac(23425.32 * sin(v.x*542.02 + v.y * 456.834));
            }

            float noise21(float2 uv){
  
              float2 scaleUV = floor(uv);
              float2 unitUV = frac(uv);
  
              float2 noiseUV = scaleUV;
  
              float value1 = hash21(noiseUV);
              float value2 = hash21(noiseUV + float2(1.,0.));
              float value3 = hash21(noiseUV + float2(0.,1.));
              float value4 = hash21(noiseUV + float2(1.,1.));
  
              unitUV = smoothstep(float2(0., 0.),float2(1., 1.),unitUV);
  
              float bresult = lerp(value1,value2,unitUV.x);
              float tresult = lerp(value3,value4,unitUV.x);
  
              return lerp(bresult,tresult,unitUV.y);
            }

            float fBM(float2 uv){
              float result = 0.;
              for(int i = 0; i <  8; i++){
                result = result + (noise21(uv * pow(2.,float(i))) / pow(2.,float(i)+1.));
              }
  
              return result;
            }

            // You might see something called v2f (now varyings) in built in shaders
            half4 frag(Varyings IN) : SV_Target 
            {
                
                float distance = 1.-length(IN.worldPos - _Target.xyz);
                half4 col = _BaseColor * (distance+ _Intensity); 

                //This is basic Lambertian diffuse shading https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/diffuse-lambertian-shading.html
                float3 LightDirection = GetMainLight().direction;
                float3 Normal = normalize(IN.worldNormal);
                float NdotL = saturate(dot(Normal, LightDirection)); // Dot product is a Vector projection clamped between 0 and 1
                float mlShadowAttenuation = MainLightRealtimeShadow(TransformWorldToShadowCoord(IN.worldPos)); // get the shadow attenuation from the Unity function using a shadow map
                float3 litColor = GetMainLight().color.rgb * NdotL * mlShadowAttenuation; // multiplies the light according to Lambertian diffuse model

                float3 worldNorm = IN.worldPos * 20.;

                float r = 0.5 + 0.5 * sin(worldNorm.x);
                float g = 0.5 + 0.5 * sin(worldNorm.y);
                float b = 0.5 + 0.5 * sin(worldNorm.z);

                float3 worldColor = float3(r, g, b);

                float3 finalColor = worldColor * litColor;

                return half4(finalColor, 1.0);
                
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