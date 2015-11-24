Shader "Hidden/GPGPU/Fluid2D/UpdateDye" {
	Properties {
		_MainTex ("-", 2D) = "" {}
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	uniform float _Fluid2D_AspectRatio;
	
	uniform sampler2D _MainTex;
	float2 _MainTex_TexelSize;
	
	uniform sampler2D _Dye;
	uniform float     _Dt;
	uniform bool      _IsMouseDown;
	uniform float2    _MouseClipSpace;
	uniform float2    _LastMouseClipSpace;
	
	float2 clipToSimSpace(float2 clipSpace){
    	return  float2(clipSpace.x * _Fluid2D_AspectRatio, clipSpace.y);
	}
	
	//Segment
	float distanceToSegment(float2 a, float2 b, float2 p, out float fp){
		float2 d = p - a;
		float2 x = b - a;

		fp = 0.0; //fractional projection, 0 - 1 in the length of vec2(b - a)
		float lx = length(x);
		
		if(lx <= 0.0001) return length(d);//#! needs improving; hot fix for normalization of 0 vector

		float projection = dot(d, x / lx); //projection in pixel units

		fp = projection / lx;

		if(projection < 0.0)            return length(d);
		else if(projection > length(x)) return length(p - b);
		return sqrt(abs(dot(d, d) - projection * projection));
	}
	
	float distanceToSegment(float2 a, float2 b, float2 p){
		float fp;
		return distanceToSegment(a, b, p, fp);
	}
	
	float4 frag (v2f_img i) : SV_Target
	{
		float4 color = tex2D (_Dye, i.uv.xy);

		color.r *= (0.9797);
		color.g *= (0.9494);
		color.b *= (0.9696);
		
		if(_IsMouseDown){			
			float2 mouse     = clipToSimSpace(_MouseClipSpace);
			float2 lastMouse = clipToSimSpace(_LastMouseClipSpace);
			float2 mouseVelocity = -(lastMouse - mouse) / _Dt;
			
			//compute tapered distance to mouse line segment
			float fp;//fractional projection
			float l = distanceToSegment(mouse, lastMouse, i.uv.xy, fp);
			float taperFactor = 0.6;
			float projectedFraction = 1.0 - clamp(fp, 0.0, 1.0) * taperFactor;

			float R = 0.025;
			float m = exp(-l/R);
			
 			float speed = length(mouseVelocity);
			float x = clamp((speed * speed * 0.02 - l * 5.0) * projectedFraction, 0., 1.);
			color.rgb += m * (lerp(float3(2.4, 0, 5.9) / 60.0, float3(0.2, 51.8, 100) / 30.0, x) + (float3(100) / 100.0) * pow(x, 9.0));
		}

		float4 result = color;
		
		return result;
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
