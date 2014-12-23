Shader "Hidden/L-Buffer" 
{
    Properties 
    {
        _MainTex ("Albedo (sRGB)", 2D) = "black" {}
    }

            CGINCLUDE
            #include "UnityCG.cginc"
            #include "GBufferPacking.cginc"

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
				
				//Material.Depth = LinearDepth(GBuffer.LinearDepth);
                
				float3 lightDir = -normalize(_LightDirection.xyz);
				
                //Calculate Diffuse Lighting w/o shadows
                float3 diffuse =  ((dot( Material.Normal.rgb, lightDir) * Material.Albedo.rgb) * _LightColor) * _LightIntensity;
                
                
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				float3 halfDir = (lightDir - viewDir);
				
				float3 reflection = normalize( reflect(lightDir, Material.Normal.rgb) );
				float3 specular = (pow(dot(reflection, viewDir), 50.0) * _LightColor) * 5.0f;
				float3 skycol = pow(float3(0.35, 0.5, 0.7), 1.0);
				float3 up = float3(0.0,1.0,0.0);
				float3 ambient1 = dot( Material.Normal.rgb * 0.5 + 0.25, up ) * Material.Albedo.rgb * (skycol);
				float3 ambient2 = dot( Material.Normal.rgb * 0.5 + 0.25, -up ) * Material.Albedo.rgb * (1.0 - skycol) * 0.5;
				//ambient1 = max(0.0, ambient1);
				//ambient2 = max(0.0, ambient2);
				diffuse = max(0.0, diffuse) * _LightColor;
                //If we return this, we will see diffuse + textures
				//return float4(Material.Depth, Material.Depth, Material.Depth, 1.0);
                return float4(diffuse + ambient1 + specular, 1.0f);
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