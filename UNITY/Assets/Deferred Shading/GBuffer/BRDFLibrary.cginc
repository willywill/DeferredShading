#ifndef BRDFLIBRARY_INCLUDED
#define BRDFLIBRARY_INCLUDED

#define PI 3.14159265359

struct SurfaceParams
{
	float NdotL;
	float NdotH;
	float NdotV;
	float HdotV;
	float HdotL;
	float Roughness;
	float F0;
	float Alpha;
	float3 SpecularAlbedo;
};

float3 Lambert(float NdotL, float3 Albedo, float3 LightColor, float3 LightIntensity)
{
	Albedo *= (1.0 / 2.2);
	return (max(0.0, NdotL) * Albedo) * LightColor * LightIntensity;
}

float3 DiffuseBurley(float NdotL, float NdotV, float HdotV, float3 Albedo, float3 LightColor, float3 LightIntensity, float Roughness)
{
	float3 diff = NdotL * Albedo;
	float FD90 = 0.5 + 2.0 * HdotV * HdotV * Roughness; 
	float FdotV = 1 + (FD90 - 1) * exp2( (-5.55473 * NdotV - 6.98316) * NdotV );
	float FdotL = 1 + (FD90 - 1) * exp2( (-5.55473 * NdotL - 6.98316) * NdotL );
	return diff * FdotV * FdotL * LightColor * LightIntensity;
}

float FresnelSchlick( float HdotV, float F0 )
{
	return F0 + ( 1.0f - F0 ) * exp2((-5.55473f * HdotV - 6.98316f) * HdotV);
}

float GGXVisibility(float NdotL, float NdotV, float alpha )
{
    float v1 = 1.0f / (NdotL + sqrt(alpha + (1 - alpha) * NdotL * NdotL));
	float v2 = 1.0f / (NdotV + sqrt(alpha + (1 - alpha) * NdotV * NdotV));
	return v1 * v2;
}

float GGXTrowbridgeReitz(float NdotH, float alpha)
{
	return alpha / (PI * pow(NdotH * NdotH * (alpha - 1) + 1, 2.0f));
}

float SpecularOcclusion(float NdotV, float AO, float alpha)
{
	float specAO = saturate((NdotV + AO) * (NdotV + AO) * (1.0 - alpha) - 1.0 + AO );
	return lerp(0.0, specAO, 0.999);
}

float SunSpot(float3 vec1, float3 vec2, float iLight)
{
	float3 delta = vec1 - vec2;
	float dist = length(delta);
	float spot = 1.0 - smoothstep(0.0, 20.0 * iLight, dist);
	return spot * spot;
}

SurfaceParams PBR(float3 N, float3 L, float3 V, float3 H, float R)
{
	SurfaceParams Surface;
	
	Surface.NdotL = dot(N, L);
	Surface.NdotH = dot(N, H);
	Surface.NdotV = dot(N, V);
	Surface.HdotV = dot(H, V);
	Surface.HdotL = dot(H, L);
	
	Surface.Roughness = R;
	Surface.Alpha = R * R;
	Surface.F0 = 0.3;
	Surface.SpecularAlbedo = 1.0f;
	
	return Surface;

}

float3 BRDF(float HdotV, float F0, float NdotL, float NdotV, float R, float NdotH, float A, float3 cLight, float iLight, float3 Albedo, float AO)
{
	//float3 diffuse = DiffuseBurley(NdotL, NdotV, HdotV, Albedo, cLight, iLight, 1.0 - R );
	float3 diffuse = Lambert(NdotL, Albedo, cLight, iLight);
	float specF = FresnelSchlick(HdotV, F0);
	float specG = GGXVisibility(NdotL, NdotV, A);
	float specD = GGXTrowbridgeReitz(NdotH, A);
	float specAO = SpecularOcclusion(NdotV, AO, A);
	float3 specular = ((specF * specG * specD * specAO) * NdotL * cLight);
	
	//Energy conservation
	diffuse *= (1.0 - specF);
	
	float3 brdf = specular + diffuse * (1.0 / PI);
	return brdf;
}

float3 CalculateBRDF(float3 N, float3 L, float3 V, float3 H, float3 cLight, float iLight, float3 Albedo, float R, float AO)
{
	SurfaceParams Surface = PBR(N, L, V, H, R);

	float3 final = BRDF(Surface.HdotV, Surface.F0, Surface.NdotL, Surface.NdotV, Surface.Roughness, Surface.NdotH, Surface.Alpha, cLight, iLight, Albedo, AO);

	return final;
}