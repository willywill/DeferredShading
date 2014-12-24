#ifndef GBUFFFERUTILITIES_INCLUDED
#define GBUFFFERUTILITIES_INCLUDED


//
//  The following funtions are for use in the G-Buffer Inputs and Outputs
//

inline float2 EncodeSphereNormals( float3 n )
{
	float p = sqrt(n.z*8+8);
    return n.xy/p + 0.5;
}

inline float3 DecodeSphereNormals( float2 enc )
{
	float2 fenc = enc * 4 - 2;
    float f = dot(fenc, fenc);
    float g = sqrt(1 - f / 4);
    float3 n;
    n.xy = fenc * g;
    n.z = 1 - f / 2;
    n.z = n.z;
    return n;
}

inline float2 EncodeDepth(float x)
{
	float bits = 256.0;
	float2 encode = frac( float2(x, x * bits));
	return encode;
}

inline float DecodeDepth(float2 x)
{
	float2 bits = float2(1.0, 1.0/256.0);
	float depth = dot(x, bits);
	return depth;
}

#endif