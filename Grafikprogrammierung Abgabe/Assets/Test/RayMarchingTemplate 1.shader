Shader "Lennard/RayMarchingTemplate"
{
    Properties
    {
        [Header(Ray Marcher Settings)]
        [Space(5)]
        _RayThreshhold("Ray Contact Threshhold", Float) = 0.001
        _RayMaxSteps("Max Ray Steps", Integer) = 258
        _RayMaxDistance("Max Ray Distance", Float) = 500
        
        [Header(Lighting Settings)]
        [Space(5)]
        _NormalDis("Normal Vector Sample Distance", Range(0.0, 0.01)) = 0.0001


        [Header(Material Settings)]
        [Space(5)]
        _MaterialColor("MaterialColor", Color) = (0,0,0,0)
        _AmbientColor("AmbientColor", Color) = (0,0,0,0)

    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"   
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Abgabe/Shader/RayMarchingLib.hlsl"   

            struct Attributes
            {
                uint vertexID : SV_VertexID;
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 viewVector : TEXCOORD1;
                float3 posWS : TEXCOORD2;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                
                float4 pos = GetFullScreenTriangleVertexPosition(IN.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(IN.vertexID);

                float3 posWS = mul(unity_ObjectToWorld, IN.positionOS).xyz;     
                OUT.posWS = posWS;

                OUT.positionCS = pos;
                OUT.uv = uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(uv * 2 - 1, 0, -1));
                OUT.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return OUT;
            }

            TEXTURE2D(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            CBUFFER_START(UnityPerMaterial)
            float _RayThreshhold;
            float _RayMaxDistance;
            int _RayMaxSteps;

            float3 _MaterialColor;
            float3 _AmbientColor;
            CBUFFER_END

            float Lambert(float3 n, float3 lightDir)
            {
                return saturate(dot(lightDir,n));
            }

            float sdBoxFrame( float3 p, float3 b, float e )
            {
                p = abs(p  )-b;
                float3 q = abs(p+e)-e;
                return min(min(
                length(max(float3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
                length(max(float3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
                length(max(float3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
            }

            float map(float3 pos)
            {
                //return sdBoxFrame(pos, float3(0.5,0.3,0.5), 0.025 );
                return sdf_Sphere(pos, 2);
            }      


            float3 calcNormal(float3 p)
            {
                const float eps = 0.01;
                return normalize(float3(
                        map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
                    ));
            }
   

            float4 rayMarch(float3 rayO, float3 rayDir, float maxD, float3 worldPos)
            {
               float distance = 0;
               Light mainLight = GetMainLight(TransformWorldToShadowCoord(worldPos));

               for(float i = 0; i < _RayMaxSteps && distance < maxD; i++)
               {
                    float sdfDistance = map(rayO + rayDir * distance); 

                    if(sdfDistance < _RayThreshhold)
                    {
                        float3 radiance = mainLight.color * Lambert(calcNormal(rayO + rayDir * distance), normalize(mainLight.direction)) * mainLight.shadowAttenuation;
                        float3 ambient = _AmbientColor.xyz * _MaterialColor.xyz;
                        float4 col = float4(_MaterialColor.xyz * radiance, 1);
                        col.xyz += ambient;
                        
                        return col;
                    }

                    distance += sdfDistance;
               }

               return float4(1, 1, 1, 1);
            }


            float4 frag (Varyings i) : SV_Target
            {

                float3 rayDir = normalize(i.viewVector);
                float3 rayPos = _WorldSpaceCameraPos;
                
                float4 col = rayMarch(rayPos, rayDir, _RayMaxDistance, i.posWS);

                return  col.xyzz;
            }
            ENDHLSL
        }
    }
}
