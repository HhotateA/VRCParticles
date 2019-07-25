Shader "Quantum/GPU Particles/SimPos_v4"
{
	Properties
	{
		_PosTex ("Position", 2D) = "white" {}
		_DirTex ("Direction", 2D) = "white" {}
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

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(unity_ObjectToWorld,v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvPos = TRANSFORM_TEX(v.uv, _PosTex);
				o.uvDir = TRANSFORM_TEX(v.uv, _DirTex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 oldPos = tex2Dlod(_PosTex, float4(i.uvPos, 0.0, 0.0));
				float4 oldDir = tex2Dlod(_DirTex, float4(i.uvDir, 0.0, 0.0));
				if(oldDir.x == 0.0 && oldDir.y == 0.0 && oldDir.z == 0.0){
					float p = i.uvPos.x + i.uvPos.y*_PosTex_TexelSize.z + _Time.y;
					float3 r = frac(sin(float3(dot(p,512.4), dot(p,628.4), dot(p,927.4)))*43758.5453);
					float3 pos = float3(float2(cos(r.x*6.28318531), sin(r.x*6.28318531))*cos(r.y*6.28318531), sin(r.y*6.28318531));
					return float4(i.pos + pos.xzy*r.z*0.1, 1.0);
				}else{
					return oldPos + oldDir;
				}
			}
			ENDCG
		}
	}
}
