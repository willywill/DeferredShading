#ifdef BRDFLIBRARY_INCLUDED
#define BRDFLIBRARY_INCLUDED

#define PI 3.14159265359

struct Vectors
{
	float NdotL;
	float NdotH;
	float NdotV;
	float HdotV;
	float HdotL;
};

struct Surface
{
	float roughness;
	float absorption;
	float reflectance;
	float refraction;
};