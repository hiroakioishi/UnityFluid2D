Shader "Hidden/GPGPU/Fluid2DParticle" {
	Properties {
		_MainTex ("-", 2D) = "" {}
		_PositionTex ("Position Tex", 2D) = "" {}
		_Color ("Particle Color", Color) = (1,1,1,1)
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	uniform sampler2D _MainTex;
	uniform sampler2D _PositionTex;
	
	float4 _PositionTex_TexelSize;
	
	uniform float4 _Color;
	
	struct appdata
	{
		float4 vertex   : POSITION;
		fixed4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};
	
	struct v2f
	{
		float4 vertex   : POSITION;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD1;
	};
	
	v2f vert (appdata v)
	{
		v2f o;
		
		float2 uv  = v.texcoord.xy + _PositionTex_TexelSize / 2;
		fixed4 pos = tex2Dlod(_PositionTex, float4(uv, 0, 0));
		
		v.vertex.x = pos.x;
		v.vertex.y = pos.y;
		v.vertex.z = pos.z;
		
		o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
		o.color  = _Color;
		
		return o;
	}
	
	float4 frag (v2f i) : SV_Target
	{	
		return i.color;
	}
	
	ENDCG
	
	
	SubShader {
		
		Pass {
			Fog { Mode off }
			CGPROGRAM
			#pragma target 3.0
			#pragma glsl
			#pragma vertex   vert
			#pragma fragment frag
			ENDCG
		} 
	}
	FallBack "Diffuse"
}