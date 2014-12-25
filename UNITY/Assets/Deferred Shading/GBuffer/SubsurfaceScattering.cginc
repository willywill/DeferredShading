#ifndef SUBSURFACESCATTERING_INCLUDED
#define SUBSURFACESCATTERING_INCLUDED

#include "UnityCG.cginc"

#define SSS_Strength 1.2
#define Blur_Width 2.75

float Linearize(float depth)
{
	return (2.0f * _ProjectionParams.y) / (_ProjectionParams.z + _ProjectionParams.y - depth * (_ProjectionParams.z - _ProjectionParams.y));
}

float3 SSS(float2 dir, float2 uv, sampler2D depthMap, sampler2D albedoMap)
{
	float2 texel = float2(1.0 / _ScreenParams.xy);
	float2 step = SSS_Strength * Blur_Width * texel * dir;

	float weight[6] = {0.006, 0.061, 0.0242, 0.242, 0.061, 0.006};
	float sample[6] = {-1.0, -0.6667, -0.3333, 0.3333, 0.6667, 1.0};

	float3 albedo = tex2D(albedoMap, uv);
	float blend = 0.05;
	float depth = Linearize(tex2D(depthMap, uv));
	
	float3 colorFinal = albedo;
	colorFinal.rgb *= 0.382;
	
	float3 colorWeight1 = float3(1.0, 0.0, 0.0);
	float3 colorWeight2 = float3(1.0, 1.0, 0.5);
	float3 colorWeight3 = float3(0.0, 0.2, 1.0);
	
	float2 direction = blend * step / depth;

	for(int i = 0; i < 6; i++)
	{
		float2 offset = uv + sample[i] * direction;
		float3 color = tex2D(albedoMap, offset);
		float3 sampleDepth = Linearize(tex2D(depthMap, offset));
		
		float scatter = min(0.0125 * abs(depth - sampleDepth), 1.0);
		color = lerp(color, albedo, scatter);
		
		colorFinal.rgb += weight[i] * color * (colorWeight1 + colorWeight2 + colorWeight3);
	}
	
	return colorFinal;
}