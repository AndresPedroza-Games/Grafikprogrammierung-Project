Shader "Andres/R2D2"
{
    Properties
    {
        [Space(10)]
        _CharacterColor("Character Color", Color) = (1,1,1,1)
        _FloorColor("Floor Color", Color) = (1,1,1,1)
        [HDR] _PlanetsColor("Planets Color", Color) = (1,1,1,1)
        _AsteroidsColor("Asteroids Color", Color) = (1,1,1,1)
        _StarsColor("Stars Color", Color) = (1,1,1,1)

        [Space(10)]
        _AmbientColor("Ambient Color", Color) = (1, 1, 1, 1)
        _BackgroundColor("Background Color", Color) = (1, 1, 1, 1)

        [Space(10)]
        _RayThreshhold("Ray Contact Threshhold", Float) = 0.001
        _RayMaxSteps("Max Ray Steps", Integer) = 258
        _RayMaxDistance("Max Ray Distance", Float) = 500

        [Space(10)]
        _ShadowMaxDistance("Max Shadow Distance", Float) = 500
        _ShadowMinDistance("Min Shadow Distance", Float) = 0
        _ShadowPenumbra("Shadow Penumbra", Float) = 0
        _ShadowPow("Shadow Power",Float) = 5

        [Space(10)]
        _SpecularInt("Specular Intensity", Range(0.0,1.0)) = 0.5
        _SpecularPow("Specular Power", Float) = 64
        _FresnelInt("Fresnel Intensity", Range(0.0,1.0)) = 0.5
        _FresnelPow("Fresnel Power", Float) = 5

        [Space(10)]
        _AnimationBaseX("Animation Base X Axis",Range(-1.0,1)) = 0
        _AnimationJump("Animation Jump",Range(-1.0,1)) = 0
        _AnimationZ("Animation Z Axis",Float) = 0
        _AnimationAsteroids("Animation Asteroids",Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "R2D2Lib.hlsl" 
            #include "ShadingLib.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD3;  
                float3 viewVector : TEXCOORD1;
                float3 posWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _CharacterColor;
                half4 _FloorColor;
                half4 _PlanetsColor;
                half4 _AsteroidsColor;
                half4 _StarsColor;
                half4 _AmbientColor;
                half4 _BackgroundColor;
                float _RayThreshhold;
                int _RayMaxSteps;
                float _RayMaxDistance;
                float _ShadowMaxDistance;
                float _ShadowMinDistance;
                float _ShadowPenumbra;
                float _ShadowPow;
                float _SpecularInt;
                float _SpecularPow;
                float _FresnelInt;
                float _FresnelPow;
                float _AnimationBaseX;
                float _AnimationJump;
                float _AnimationZ;
                float _AnimationAsteroids;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                float4 pos = GetFullScreenTriangleVertexPosition(IN.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(IN.vertexID);

                float3 posWS = mul(unity_ObjectToWorld, IN.positionOS).xyz;     
                OUT.posWS = posWS;

                OUT.positionHCS = pos;
                OUT.uv = uv;

                OUT.viewDir = GetWorldSpaceViewDir(mul(unity_ObjectToWorld,IN.positionOS).xyz);

                float3 viewVector = mul(unity_CameraInvProjection, float4(uv * 2 - 1, 0, -1));
                OUT.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));

                return OUT;
            }

            float4 BG(){
                
                float4 result = _BackgroundColor;

                return result;
            }

            float2 FinalMap(float3 pos)
            {                
                float2 character = float2(Character(float3(pos.x - _AnimationBaseX,pos.y + 1.3,pos.z + _AnimationZ),_AnimationJump),0);
                
                float2 base = float2(Base(float3(pos.x - _AnimationBaseX,pos.y,pos.z + _AnimationZ)),1);

                float2 character_Base = cm(base,character);

                float2 Bg = float2(Planets(pos - float3(0,0,_AnimationZ)),2);

                float2 asteroids = float2(Asteroids(pos - float3(0,0,_AnimationAsteroids)),3);

                float2 result = cm(character_Base,Bg);

                result = cm(result,asteroids);

                float2 star = float2(Stars(pos - float3(-20,0,100)),4);

                result = cm(result,star);

                return result;
            }   

            float softshadow(float3 rayO, float3 lightDir, float minD, float maxT, float penumbra )
            {
                float result = 1.0;
                float distance = minD;

                for( int i = 0; i < 256 && distance < maxT; i++ )
                {
                    float shadowD = FinalMap(rayO +  lightDir * distance);

                    if( shadowD < 0.001 )
                        return 0.0;

                    result = min( result, penumbra * shadowD / distance );

                    distance += shadowD;
                }
                return result;
            }

            float3 calcNormal(float3 p)
            {
                const float eps = 0.01;
                return normalize(float3(
                    FinalMap(p + float3(eps, 0, 0)).x - FinalMap(p - float3(eps, 0, 0)).x,
                    FinalMap(p + float3(0, eps, 0)).x - FinalMap(p - float3(0, eps, 0)).x,
                    FinalMap(p + float3(0, 0, eps)).x - FinalMap(p - float3(0, 0, eps)).x
                ));
            }

            // float4 BoxMapping(sampler2D sample, float3 pos, float3 normal, float k)
            // {
            //     float4 xAxis = texture(sample, pos.yz);
            //     float4 yAxis = texture(sample, pos.xz);
            //     float4 zAxis = texture(sample, pos.xy);    

            //     float3 weight = pow(abs(normal), float3(k));

            //     return (xAxis * weight.x + yAxis * weight.y + zAxis * weight.z) / (weight.x + weight.y + weight.z);
            // }

            float3 RayMarchingHit(float mat)
            {
                float3 color;

                if(mat == 0){
                    color = _CharacterColor;
                }
                else if(mat == 1){
                    color = _FloorColor;
                }
                else if(mat == 2){
                    color = _PlanetsColor;
                }
                else if(mat == 3){
                    color = _AsteroidsColor;
                }
                else{
                    color = _StarsColor;
                }

                return color;
            }

            float4 rayMarching(float3 rayO, float3 rayDir, float maxD, float3 worldPos, float3 viewDir)
            {
                float distance = 0;              
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(worldPos));

                for(int i = 0; i < _RayMaxSteps && distance < maxD; i++)
               {
                    float3 origin = rayO + rayDir * distance;
                    float2 sdfDistance = FinalMap(origin); 

                    if(sdfDistance.x < _RayThreshhold)
                    {
                        float3 normal = calcNormal(rayO + rayDir * distance);
                        float3 diffuse = RayMarchingHit(sdfDistance.y);

                        float3 radiance = mainLight.color * Lambert(normal, normalize(mainLight.direction)) * mainLight.shadowAttenuation;
                        float3 ambient = _AmbientColor.xyz * diffuse;
                        
                        float specular = _SpecularInt * Phong(normal,normalize(mainLight.direction),normalize(viewDir),_SpecularPow);
                        float fresnel = _FresnelInt * Fresnel(normal,normalize(viewDir),_FresnelPow);

                        float4 result = float4(diffuse * radiance, 1); 
                        result.xyz += ambient;

                        result.xyz = (diffuse + specular) * radiance + ambient + fresnel;

                        float4 resultShadow = softshadow(origin, normalize(mainLight.direction),_ShadowMinDistance,_ShadowMaxDistance, _ShadowPenumbra) * 0.5 + 0.5;
                        resultShadow = max(0.0,pow(resultShadow,_ShadowPow));

                        result *= resultShadow;

                        return result;
                    }

                    distance += sdfDistance;
               }

               return BG();
            }

            half4 frag(Varyings IN) : SV_Target
            {
                
                float3 rayDir = normalize(IN.viewVector);
                float3 rayPos = _WorldSpaceCameraPos;
                
                float4 result = rayMarching(rayPos, rayDir, _RayMaxDistance,IN.posWS,IN.viewDir);

                return  result.xyzz;
            }
            ENDHLSL
        }
    }
}
