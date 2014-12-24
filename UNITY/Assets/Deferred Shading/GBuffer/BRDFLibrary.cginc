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
	return (max(0.0, NdotL) * Albedo) * LightColor * LightIntensity;
}

float3 Diffuse_Burley( float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH )
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * exp2( (-5.55473 * NoV - 6.98316) * NoV );
	float FdL = 1 + (FD90 - 1) * exp2( (-5.55473 * NoL - 6.98316) * NoL );
	return DiffuseColor / PI * FdV * FdL;
}

float3 DiffuseBurley(float NdotL, float NdotV, float HdotV, float3 Albedo, float3 LightColor, float3 LightIntensity, float Roughness)
{
	float3 diff = (max(0.0, NdotL) * Albedo) * LightColor * LightIntensity;
	float FD90 = 0.5 + 2.0 * HdotV * HdotV * Roughness; 
	float FdotV = 1 + (FD90 - 1) * exp2( (-5.55473 * NdotV - 6.98316) * NdotV );
	float FdotL = 1 + (FD90 - 1) * exp2( (-5.55473 * NdotL - 6.98316) * NdotL );
	return diff * FdotV * FdotL;
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
	Surface.F0 = 0.75;
	Surface.SpecularAlbedo = 1.0f;
	
	return Surface;

}

float3 BRDF(float HdotV, float F0, float NdotL, float NdotV, float R, float NdotH, float A, float3 cLight, float iLight, float3 Albedo)
{
	float3 diffuse = DiffuseBurley(NdotL, NdotV, HdotV, Albedo, cLight, iLight, (1.0 - R) );

	float specF = FresnelSchlick(HdotV, F0);
	float specG = GGXVisibility(NdotL, NdotV, A);
	float specD = GGXTrowbridgeReitz(NdotH, A);
	float3 specular = ((specF * specG * specD * NdotL) * cLight);
	
	diffuse *= (1.0 - specF);
	
	float3 brdf = specular + diffuse * (1.0 / PI);
	return brdf;
}

float3 CalculateBRDF(float3 N, float3 L, float3 V, float3 H, float3 cLight, float iLight, float3 Albedo, float R)
{
	SurfaceParams Surface = PBR(N, L, V, H, R);

	float3 final = BRDF(Surface.HdotV, Surface.F0, Surface.NdotL, Surface.NdotV, Surface.Roughness, Surface.NdotH, Surface.Alpha, cLight, iLight, Albedo);

	return final;
}