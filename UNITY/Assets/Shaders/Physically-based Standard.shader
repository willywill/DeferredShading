Shader "Custom/Physically-based Standard" 
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (sRGB)", 2D) = "white" {}
		_SpecularColor ("Specular Color (sRGB)", 2D) = "white" {}
		_Roughness ("Roughness (Linear)", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		
		CGPROGRAM
		#pragma surface surf Lambert

		sampler2D _MainTex;
		sampler2D _Roughness;
		sampler2D _SpecularColor;
		fixed4 _Color;

		struct Input 
		{
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			half r = tex2D (_Roughness, IN.uv_MainTex);
			half4 s = tex2D(_SpecularColor, IN.uv_MainTex)* _Color;
			o.Albedo = s;
			o.Alpha = 0;
		}
		ENDCG
	} 
	
	Fallback "VertexLit"
}
