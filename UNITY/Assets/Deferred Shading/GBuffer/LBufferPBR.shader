Shader "Hidden/L-Buffer-Physical" 
{
    Properties 
    {
        _MainTex ("Albedo (sRGB)", 2D) = "black" {}
    } 

            CGINCLUDE
            #include "UnityCG.cginc"
            #include "GBufferPacking.cginc"
			#include "BRDFLibrary.cginc"
			#include "AmbientOcclusion.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _NormalTexture;
            uniform sampler2D _DepthTexture;
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _Jitter;
            uniform float4 _LightDirection;
			uniform float4 _LightColor;
			uniform float4 _SkyColor;
			uniform float4 _GroundColor;
			uniform float _LightIntensity;
			uniform float4x4 _InverseProj;
			
			uniform float4x4 _FrustumCornersWS;
			uniform float4 _CameraWS;

            struct v2f 
            { 
                float4 pos : POSITION;
				float4 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
				float index = v.vertex.z;
                float4 pos = mul( UNITY_MATRIX_MVP, v.vertex );
                o.pos = pos;
				o.worldPos = mul( _Object2World, v.vertex );
                o.uv = v.texcoord.xy;
				o.interpolatedRay = _FrustumCornersWS[(int)index];
				o.interpolatedRay.w = index;
                return o;
            }
 
			float LinearDepth(float depth)
			{
				return (2.0f * _ProjectionParams.y) / (_ProjectionParams.z + _ProjectionParams.y - depth * (_ProjectionParams.z - _ProjectionParams.y));
			}
			
			float SchlickPhase(float cosTheta, float g)
			{
				float k = (1.55 * g) - (5.55 * (g * g * g));
				return (1.0 / (4.0 * PI)) * ((1.0 - (k * k)) / ( pow( 1.0 + k * cosTheta, 2.0)));
			}
			
			float3 ComputeSkyGradient(float depth, float cosTheta, float g, float3 worldPos, float3 skyColor, float3 horizonColor)
			{
				if(depth > 0.99)
				{
					float curve = 2.0;
					float gradient = pow(worldPos.y * 0.5 + 0.5, curve);
					float3 gradient3 = float3(gradient, gradient, gradient);
					float3 sun = SchlickPhase(cosTheta, g) * _LightColor;
					float3 sky = lerp(horizonColor, skyColor, gradient3);
					return (sky + sun) * 1.2;
				}
				
				return 0.0;
			}
			
			float3 ComputeFogGradient(float3 dir, float3 horizonColor, float3 skyColor, float depth, float cosTheta, float g)
			{
				if(depth < 0.99)
				{
					float curve = 1.0;
					float gradient = pow(dir.y * 0.5 + 0.5, curve);
					float3 gradient3 = float3(gradient, gradient, gradient);
					float3 sun = SchlickPhase(cosTheta, g) * _LightColor; 
					float3 sky = lerp(horizonColor, skyColor, gradient3);
					return (sky + sun)  * 1.5;
				}
				
				return 0.0;
			}
			
			float3 CalculateFogDensity(float3 col, float cosTheta, float g, float3 skyColor, float3 groundColor, float3 rayDist, float3 worldPos, float fogDensity, float depth)
			{
				float density = exp( rayDist.y * -fogDensity);
				float3 fog = ComputeFogGradient(worldPos, groundColor, skyColor, depth, cosTheta, g);
				if(depth < 0.9)
				{
					col = lerp(fog, col, density);
				}
				
				else
				{
					col = col;
				}
				
				return col;
			}
 
            float4 CalculateLighting ( v2f i ) : COLOR
            {   
                //Collect all the information in the G-Buffer
                SurfaceProperties GBuffer = UnpackGBuffer(i.uv, _CameraDepthTexture, _MainTex, _NormalTexture);
                
                //Assign the G-Buffer info to something local in the shader here
                MaterialProperties Material;
                
                //Grab the Albedo from the GBuffer
                Material.Albedo.rgb = GBuffer.Color;
				
                
                //Grab the Normals from the GBuffer
                Material.Normal.rgb = GBuffer.Normal;
				
				//Grab the depth
				Material.Depth = LinearDepth(GBuffer.LinearDepth);
				
				//Calculate subsurface scattering in both directions
				//float3 sss = float3(0,0,0);
				//float2 dir = float2(1.0, 0.0);
				//sss += SSS(dir, i.uv, _CameraDepthTexture, _MainTex);
				//dir = float2(0.0, 1.0);
				//sss += SSS(dir, i.uv, _CameraDepthTexture, _MainTex);
				//Material.Albedo.rgb = lerp(Material.Albedo.rgb, sss * 0.5, 1.0);
				
				//Get the light direction
				float3 lightDir = _LightDirection;
				
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfDir = (lightDir - viewDir);	
				
				float4 res;	
				
				float4 rayDir = Material.Depth * i.interpolatedRay;
				float cosTheta = dot(rayDir, lightDir);
				float g = 0.999f;
				
				float3 sky = ComputeSkyGradient(Material.Depth, cosTheta, g, i.worldPos, _SkyColor, _GroundColor);
				
				float gradient = Material.Normal.y * 0.5 + 0.5;
				float3 ambientColor = lerp(_GroundColor, _SkyColor, gradient);
				
				float3 ao = SSAO(i.uv, Material.Normal.rgb, _CameraDepthTexture, _Jitter, _InverseProj);
				
				float3 ambientDiffuse = ao * ao * ao * ao * ao * ambientColor;
				float3 ambientSpec = 0.0;
				
				float3 ambient = ambientDiffuse + ambientSpec;
				
				float roughness = 0.64875;
				float3 brdf = CalculateBRDF(Material.Normal.rgb, lightDir, viewDir, halfDir, _LightColor, _LightIntensity, Material.Albedo.rgb, roughness, ao.x);
				
				float3 final = saturate(brdf) + ambient;
				final *= Material.Albedo.rgb;
				float fogDensity = 0.1;
				if(fogDensity > 0.0)
					final = CalculateFogDensity(final, cosTheta, g, _SkyColor, _GroundColor, rayDir, i.worldPos, fogDensity, Material.Depth);
				
				res.xyz = final + sky;
				res.w = 1.0;
								
                return res;
            }
         
            ENDCG

 Subshader 
 {
        ZTest Off
        Cull Off
        ZWrite Off
        Fog { Mode off }
  
        //Pass 0 CalculateLighting
        
        Pass 
        {
            Name "CalculateLighting"
        
                CGPROGRAM
                #pragma target 3.0
				#pragma glsl
                #pragma vertex vert
                #pragma fragment CalculateLighting
                ENDCG
        }
  
  }

        Fallback off

}