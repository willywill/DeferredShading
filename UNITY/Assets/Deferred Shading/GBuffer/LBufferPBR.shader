Shader "Hidden/L-BufferPhysical" 
{
    Properties 
    {
        _MainTex ("Albedo (sRGB)", 2D) = "black" {}
    }

            CGINCLUDE
            #include "UnityCG.cginc"
            #include "GBufferPacking.cginc"
			#include "BRDFLibrary.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _NormalTexture;
            uniform sampler2D _DepthTexture;
            uniform float4 _LightDirection;
			uniform float4 _LightColor;
			uniform float _LightIntensity;

            struct v2f 
            { 
                float4 pos : POSITION;
				float4 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                float4 pos = mul( UNITY_MATRIX_MVP, v.vertex );
                o.pos = pos;
				o.worldPos = mul( _Object2World, v.vertex );
                o.uv = v.texcoord.xy;
                return o;
            }
 
			float LinearDepth(float depth)
			{
				return (2.0f * _ProjectionParams.y) / (_ProjectionParams.z + _ProjectionParams.y - depth * (_ProjectionParams.z - _ProjectionParams.y));
			}
 
            float4 CalculateLighting ( v2f i ) : COLOR
            {   
                //Collect all the information in the G-Buffer
                SurfaceProperties GBuffer = UnpackGBuffer(i.uv, _DepthTexture, _MainTex, _NormalTexture);
                
                //Assign the G-Buffer info to something local in the shader here
                MaterialProperties Material;
                
                //Grab the Albedo from the GBuffer
                Material.Albedo.rgb = GBuffer.Color;
                
                //Grab the Normals from the GBuffer
                Material.Normal.rgb = GBuffer.Normal;
				
				//Grab the depth
				Material.Depth = LinearDepth(GBuffer.LinearDepth);
				
				//Get the light direction
				float3 lightDir = -normalize(_LightDirection.xyz);
				
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfDir = (lightDir - viewDir);	
				
				float4 res;	
				
				float3 up = float3(0.0,1.0,0.0);
				float3 skycol = float3(0.35, 0.5, 0.7);
				float3 ambient = dot( Material.Normal.rgb * 0.485 + 0.008, up ) * Material.Albedo.rgb * (skycol) * 0.311;
				
				float roughness = 0.575;
				float3 brdf = CalculateBRDF(Material.Normal.rgb, lightDir, viewDir, halfDir, _LightColor, _LightIntensity, Material.Albedo.rgb, roughness);
				res.xyz = saturate(brdf) + ambient;
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
                #pragma vertex vert
                #pragma fragment CalculateLighting
                ENDCG
        }
  
  }

        Fallback off

}