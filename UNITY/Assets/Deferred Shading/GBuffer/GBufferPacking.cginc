#ifndef GBUFFFERPACKING_INCLUDED
#define GBUFFFERPACKING_INCLUDED

#include "GBufferUtilities.cginc"

struct MaterialProperties
{
	float4 Albedo;
	float3 Normal;
	float Depth;
	float MatID;
};

struct SurfaceProperties
{
	float LinearDepth;
	float3 Color;
	float3 Normal;
};
	
SurfaceProperties UnpackGBuffer(float2 coords, sampler2D depth, sampler2D albedo, sampler2D normals)
{
	SurfaceProperties output;
	
 	output.LinearDepth = tex2D(depth, coords).z;
 	output.Color = tex2D(albedo, coords);
 	output.Normal = DecodeSphereNormals(tex2D(normals, coords).rg) * 0.5f + 0.25f;
 	
 	return output;
}

#endif
