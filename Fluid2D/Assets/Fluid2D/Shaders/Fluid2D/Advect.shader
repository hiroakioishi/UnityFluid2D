Shader "Hidden/GPGPU/Fluid2D/Advect" {
	Properties {
		_MainTex ("-", 2D) = "" {}
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	uniform float  _Fluid2D_AspectRatio;
	uniform float2 _Invresolution;
	
	uniform sampler2D _MainTex;
	uniform float2    _MainTex_TexelSize;
	
	uniform sampler2D _Velocity;
	uniform sampler2D _Target;
	
	uniform float  _Dt;
	uniform float  _RDX; // reciprocal of grid scale, used to scale velocity int simulation domain
	
	
	float2 simToTexelSpace(float2 simSpace){
    	return float2(simSpace.x / _Fluid2D_AspectRatio + 1.0 , simSpace.y + 1.0) * 0.5;
	}
	
	float4 frag (v2f_img i) : SV_Target
	{
	
		float2 u = tex2D (_Velocity, i.uv.xy).xy;
		float2 tracedPos = i.uv.xy - (u * _Invresolution * _Dt);
		float4 result    = 0.999 * tex2D (_Target, tracedPos.xy);
		
		return float4(result.xyz, 1.0);
		/*
		//texelCoord refers to the center of the texel! Not a corner!
  		
  		float2 tracedPos = i.uv.xy - _Dt * _RDX * tex2D (_Velocity, i.uv.xy).xy;

		//Bilinear Interpolation of the target field value at tracedPos 
		//tracedPos = simToTexelSpace(tracedPos) / _Invresolution; // texel coordinates

		float4 st;
		st.xy = floor(tracedPos - 0.5) + 0.5; //left & bottom cell centers
		st.zw = st.xy + 1.0;               //right & top centers

		float2 t = tracedPos - st.xy;

		st *= _Invresolution.xyxy; //to unitary coords

		float4 tex11 = tex2D (_Target, st.xy);
		float4 tex21 = tex2D (_Target, st.zy);
		float4 tex12 = tex2D (_Target, st.xw);
		float4 tex22 = tex2D (_Target, st.zw);

		//need to bilerp this result
		float4 result = lerp(lerp(tex11, tex21, t.x), lerp(tex12, tex22, t.x), t.y);
	
		return result;
		*/
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
