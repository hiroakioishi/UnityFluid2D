Shader "Hidden/GPGPU/FluidParticle/Kernel" {
	Properties {
		_MainTex ("-", 2D) = "" {}
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	
	uniform sampler2D _MainTex;
	
	uniform sampler2D _PositionTex;
	uniform sampler2D _VelocityTex;
	uniform sampler2D _FlowVelocityFieldTex;
	
	uniform float  _DragCoefficient;
	uniform float2 _FlowScale;
	
	uniform float _LifeTimeMin;
	uniform float _LifeTimeMax;
	uniform float _Throttle;
	uniform float _RandomSeed;
	uniform float _dT;
	
	float nrand(float2 uv, float salt)
    {
        uv += float2(salt, _RandomSeed);
        return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    }
    
    float4 newPosition (float2 uv) {
    	float t = _Time.y;
    	
    	float3 p = float3(nrand(uv, t), nrand(uv, t + 1), nrand(uv, t + 2));
       	p = (p - (float3) 0.5);
		p.z = 0.0;
		
        float4 offs = float4(1e8, 1e8, 1e8, -1) * (uv.x > _Throttle.x);

        return float4(p, 0.5) + offs;
    }
    
    float4 initPosition (v2f_img i) : SV_Target
    {
    	return newPosition (i.uv.xy);
    }
    
    float4 updateVelocity (v2f_img i) : SV_Target
    {
    	float2 pos = tex2D(_PositionTex, i.uv).xy;
   		float2 vel = tex2D(_VelocityTex, i.uv).xy;
		float2 vf  = tex2D(_FlowVelocityFieldTex, pos + float2(0.5, 0.5)).xy * _FlowScale;//(converts clip-space p to texel coordinates)
		vel += (vf - vel) * _DragCoefficient;
    	return float4(vel.x, vel.y, 0.0, 1.0);
    }
    
    
    float4 updatePosition (v2f_img i) : SV_Target
    {
    	float4 pos = tex2D(_PositionTex, i.uv);
    	
		float dt = _dT;
		pos.w -= lerp(_LifeTimeMin, _LifeTimeMax, nrand(i.uv, 12)) * dt;

		if (pos.w > -0.5)
		{
			float2 vel = tex2D(_VelocityTex, i.uv).xy;
			pos.xy += _dT * vel;
			return pos;
		}
		else
		{
			float4 newPos = newPosition(i.uv);
			return newPos;
		}
  
    }
	ENDCG
	
	SubShader {
		// Pass 0: initPosition
		Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment initPosition
            ENDCG
        }
        // Pass 1: updateVelocity
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment updateVelocity
            ENDCG
        }
        // Pass 2: updatePosition
		Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment updatePosition
            ENDCG
        }
        
	}
	FallBack "Diffuse"
}