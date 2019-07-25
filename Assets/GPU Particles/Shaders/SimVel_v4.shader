Shader "Quantum/GPU Particles/SimVel_v4"
{
	Properties
	{
		_PosTex ("Position", 2D) = "white" {}
		_DirTex ("Direction", 2D) = "white" {}
		_Attraction ("Attraction", Range(-1.0, 100.0)) = 0.01
		_MaxAttraction ("Max Attraction", Range(0.0, 100.0)) = 0.01
		_MaxSpeed ("Max Speed", Range(0.0, 10.0)) = 0.01
		_SpeedRetained ("Speed Retained", Range(0.0, 10.0)) = 0.99
		_at ("at", Range(0.0, 10.0)) = 0.99
	}
	SubShader
	{
		Tags { "Lightmode" = "Forwardbase"}
		LOD 100

		Pass
		{
			Tags { "Lightmode" = "Forwardbase"}
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uvPos : TEXCOORD0;
				float2 uvDir : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float4 pos : NORMAL;
			};

			sampler2D_float _PosTex;
			float4 _PosTex_ST;
			uniform float4 _PosTex_TexelSize;
			sampler2D_float _DirTex;
			float4 _DirTex_ST;
			float _at;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(unity_ObjectToWorld,v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvPos = TRANSFORM_TEX(v.uv, _PosTex);
				o.uvDir = TRANSFORM_TEX(v.uv, _DirTex);
				return o;
			}

			float _Attraction;
			float _SpeedRetained;
			float _MaxSpeed;
			float _MaxAttraction;

			float4 frag (v2f i) : SV_Target
			{
				float4 oldPos = tex2Dlod(_PosTex, float4(i.uvPos, 0.0, 0.0));
				float4 oldDir = tex2Dlod(_DirTex, float4(i.uvDir, 0.0, 0.0));
				if(oldDir.w == 0.0){
					return float4(0.0, 0.0, 0.0, 1.0);
				}else{
					float dist = length(i.pos.xyz - oldPos.xyz);
					float3 dir = normalize(i.pos.xyz - oldPos.xyz);
					float f =_at/(dist*dist);
					if(f > _MaxAttraction) f = _MaxAttraction;
					oldDir.xyz = oldDir.xyz*_SpeedRetained + dir * f * _Attraction;
					if(length(oldDir.xyz) > _MaxSpeed) oldDir.xyz = normalize(oldDir.xyz)*_MaxSpeed;
					return float4(oldDir.xyz, 1.0);
				}
			}
			ENDCG
		}
	}
}
