#ifndef AMBIENTOCCLUSION_INCLUDED
#define AMBIENTOCCLUSION_INCLUDED

#define QUALITYBOOST 1
#define Radius 0.2875
#define Intensity 1.575
#define Distance 2.5
#define Bias 0.375

float3 ViewSpacePosition(float2 coords, sampler2D depthTex, float4x4 InverseProj)
{
	float depth = LinearEyeDepth(tex2D(depthTex, coords).x);
	float4 pos = float4((coords.x - 0.5) * 2.0, (0.5 - coords.y) * -2.0, 1.0, 1.0);
	float4 ray = mul(pos, InverseProj);
	return ray.xyz * depth;
}

float AO(float2 coords, float2 uv, float3 p, float3 n, sampler2D depth, float4x4 ip)
{
	float3 diff = ViewSpacePosition(coords + uv, depth, ip) - p;
	float3 v = normalize(diff);
	float d = length(diff) * Distance;
	float f = (1.0 / (1.0 + d));
	return  f * Intensity * max(0.0, (dot(n, v) - Bias) / (1.0 - Bias));
}

float SSAO(float2 uv, float3 N, sampler2D depthTex, sampler2D jitter, float4x4 inverseProj)
{

	const float2 Kernel[4] = { float2(1.0, 0.0), float2(-1.0, 0.0), float2(0.0, 1.0), float2(0.0, -1.0) };
	
	float3 position = ViewSpacePosition(uv, depthTex, inverseProj);
	float3 normal = N;
	
	float ao = 0.0f;
	float radius = Radius / position.z;
	float2 random = normalize(tex2D(jitter, _ScreenParams.xy * uv / 1024.0).rg * 2.0 - 1.0);
	
	for (int j = 0; j < 4 * QUALITYBOOST; j++)
	{
		float2 coord1;

		coord1 = reflect(Kernel[j], random) * radius;
		float2 coord2 = coord1 * 0.707;
		coord2 = float2(coord2.x - coord2.y, coord2.x + coord2.y);

		ao += AO(uv, coord1 * 0.25, position, normal, depthTex, inverseProj);
		ao += AO(uv, coord2 * 0.50, position, normal, depthTex, inverseProj);
		ao += AO(uv, coord1 * 0.75, position, normal, depthTex, inverseProj);
		ao += AO(uv, coord2 * 1.00, position, normal, depthTex, inverseProj);
	}
	
	ao /= (16.0 * QUALITYBOOST);
	ao = 1.0f - ao;
	
	return ao;
}