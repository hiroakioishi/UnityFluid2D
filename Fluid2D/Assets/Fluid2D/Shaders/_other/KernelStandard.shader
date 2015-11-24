Shader "Hidden/GPGPU/Kernel" {
	Properties {
		_MainTex ("-", 2D) = "" {}
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	uniform sampler2D _MainTex;
	
	float4 frag (v2f_img i) : SV_Target
	{
		return float4(0,0,0,0);
	}
	
	ENDCG
	
	
	SubShader {
		
		Pass {
			Fog { Mode off }
			CGPROGRAM
			#pragma target 3.0
			#pragma glsl
			#pragma vertex   vert_img
			#pragma fragment frag
			ENDCG
		} 
	}
	FallBack "Diffuse"
}
