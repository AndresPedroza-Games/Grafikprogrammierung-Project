    float Lambert(float3 n, float3 lightDir)
    {
        return saturate(dot(lightDir,n));
    }

    float Phong(float3 normal, float3 lightDir,float3 viewDir, float power)
    {
        float3 halfV = normalize(lightDir + viewDir);
        return pow(saturate(dot(normal,halfV)), power);
    }

    float Fresnel(float3 normal, float3 viewDir, float power)
    {
        return pow(1 - saturate(dot(normal,viewDir)),power);
    }

    