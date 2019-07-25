Shader "Quantum/GPU Particles/SimParticles_v4"
{
	Properties
	{
		_PosTex1 ("Position", 2D) = "Black" {}
		_VelTex1 ("Position", 2D) = "Black" {}
		_AxisTex ("AxisTex", 2D) = "White" {}
		_timescale ("TimeScale", Range(0.0001, 1)) = 0.001
		_Size ("Size", Range(0.0001, 0.01)) = 0.001
		_outline ("outline", Range(0.0001, 0.01)) = 0.001
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader
	{
		Tags { "Lightmode" = "Forwardbase" "Queue" = "Transparent+1" "RenderType" = "Transparent" }
		LOD 100

		Pass
		{
			Tags { "Lightmode" = "Forwardbase" "Queue" = "Transparent+1" "RenderType" = "Transparent" }
			ZWrite Off
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2g
			{
				float4 pos : POSITION;
				float2 uvTex : TEXCOORD0;
				float2 uvVel : TEXCOORD1;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float4 wPos : NORMAL;
				float4 col : COLOR0;
			};

			sampler2D _PosTex1;
			float4 _PosTex1_ST;
			float4 _PosTex1_TexelSize;
			sampler2D _VelTex1;
			sampler2D _AxisTex; float4 _AxisTex_ST;
			float4 _VelTex1_ST;
			float _timescale;
			float _outline;

			v2g vert (appdata v)
			{
				v2g o;
				o.pos = v.pos;
				o.uvTex = TRANSFORM_TEX(v.uv, _PosTex1);
				o.uvVel = TRANSFORM_TEX(v.uv, _VelTex1);
				return o;
			}

			float _Size;
			float4 _Color;
			#define SQRT3 1.7320508075688772935274463415059

			//頂点inputをvert分平行移動
			            float3 translation(float4 input, float3 vect)
			            {
			                float4x4 motion = float4x4(
			                    1, 0, 0, vect.x,
			                    0, 1, 0, vect.y,
			                    0, 0, 1, vect.z,
			                    0, 0, 0, 1
			                );
			                float4 output = mul(motion,input);
			                output /= output.w;
			                return float3(output.x,output.y,output.z);
			            }
			//頂点inputをaxis軸でangle度分回転
			            float3 rotate(float3 input, float angle, float3 axis){
			                axis = normalize(axis);
							if(length(axis) <= 0){axis=float3(1,0,0);}
			                float3x3 rotation = float3x3(
			                    cos(angle)+axis.x*axis.x*(1-cos(angle)),
			                    axis.x*axis.y*(1-cos(angle))+axis.z*sin(angle),
			                    axis.z*axis.x*(1-cos(angle))-axis.y*sin(angle),

			                    axis.x*axis.y*(1-cos(angle))-axis.z*sin(angle),
			                    cos(angle)+axis.y*axis.y*(1-cos(angle)),
			                    axis.y*axis.z*(1-cos(angle))+axis.x*sin(angle),

			                    axis.z*axis.x*(1-cos(angle))+axis.y*sin(angle),
			                    axis.y*axis.z*(1-cos(angle))-axis.x*sin(angle),
			                    cos(angle)+axis.z*axis.z*(1-cos(angle))
			                );
			                float3 output = mul(rotation,input);
			                return output;
			            }
			//頂点inputをzeroを原点、axisを軸として、angle度分回転
			            float3 rotation(float3 input, float3 zero, float angle, float3 axis){
			                float3 output = translation(float4(input,1),-zero);
			                output = rotate(output,angle,axis);
			                output = translation(float4(output,1),zero);
			                return output;
			            }

			[maxvertexcount(72)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream){
                g2f o;
				float4 c = float4(tex2Dlod(_PosTex1, float4((IN[0].uvTex + IN[1].uvTex + IN[2].uvTex)/4, 0.0, 0.0)).xyz, 1.0);
				float4 col = float4(tex2Dlod(_VelTex1, float4((IN[0].uvVel + IN[1].uvVel + IN[2].uvVel)/3.0, 0.0, 0.0)).xyz*100.0, 1.0);
				float3 axis = tex2Dlod(_AxisTex,float4(frac(_Time.y*_timescale*IN[0].uvTex.x),frac(sin(_Time.y*_timescale*IN[0].uvVel.x)),0,0));
				float angle = 6*cos(_Time.y);
				g2f cash[8];
				cash[0].wPos = float4(rotation(float3(-_Size, -_Size, -_Size),float3(0,0,0),angle,axis),0); cash[0].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[0].wPos); cash[0].col = col*2;
				cash[1].wPos = float4(rotation(float3( _Size, -_Size, -_Size),float3(0,0,0),angle,axis),0); cash[1].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[1].wPos); cash[1].col = col*2;
				cash[2].wPos = float4(rotation(float3(-_Size,  _Size, -_Size),float3(0,0,0),angle,axis),0); cash[2].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[2].wPos); cash[2].col = col*2;
				cash[3].wPos = float4(rotation(float3( _Size,  _Size, -_Size),float3(0,0,0),angle,axis),0); cash[3].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[3].wPos); cash[3].col = col*2;
				cash[4].wPos = float4(rotation(float3(-_Size, -_Size,  _Size),float3(0,0,0),angle,axis),0); cash[4].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[4].wPos); cash[4].col = col*5;
				cash[5].wPos = float4(rotation(float3( _Size, -_Size,  _Size),float3(0,0,0),angle,axis),0); cash[5].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[5].wPos); cash[5].col = col*5;
				cash[6].wPos = float4(rotation(float3(-_Size,  _Size,  _Size),float3(0,0,0),angle,axis),0); cash[6].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[6].wPos); cash[6].col = col*10;
				cash[7].wPos = float4(rotation(float3( _Size,  _Size,  _Size),float3(0,0,0),angle,axis),0); cash[7].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[7].wPos); cash[7].col = col*10;
				//1
				tristream.Append(cash[0]); tristream.Append(cash[1]); tristream.Append(cash[2]); tristream.Append(cash[3]); tristream.RestartStrip();
				tristream.Append(cash[1]); tristream.Append(cash[5]); tristream.Append(cash[3]); tristream.Append(cash[7]); tristream.RestartStrip();
				tristream.Append(cash[5]); tristream.Append(cash[4]); tristream.Append(cash[7]); tristream.Append(cash[6]); tristream.RestartStrip();
				tristream.Append(cash[3]); tristream.Append(cash[0]); tristream.Append(cash[6]); tristream.Append(cash[2]); tristream.RestartStrip();
				tristream.Append(cash[2]); tristream.Append(cash[3]); tristream.Append(cash[6]); tristream.Append(cash[7]); tristream.RestartStrip();
				tristream.Append(cash[1]); tristream.Append(cash[0]); tristream.Append(cash[5]); tristream.Append(cash[4]); tristream.RestartStrip();
				//outline
				/*
				cash[0].wPos = float4(rotation(float3(-_Size*(1+_outline), -_Size*(1+_outline), -_Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[0].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[0].wPos); cash[0].col = col*0;
				cash[1].wPos = float4(rotation(float3( _Size*(1+_outline), -_Size*(1+_outline), -_Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[1].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[1].wPos); cash[1].col = col*0;
				cash[2].wPos = float4(rotation(float3(-_Size*(1+_outline),  _Size*(1+_outline), -_Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[2].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[2].wPos); cash[2].col = col*0;
				cash[3].wPos = float4(rotation(float3( _Size*(1+_outline),  _Size*(1+_outline), -_Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[3].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[3].wPos); cash[3].col = col*0;
				cash[4].wPos = float4(rotation(float3(-_Size*(1+_outline), -_Size*(1+_outline),  _Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[4].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[4].wPos); cash[4].col = col*0;
				cash[5].wPos = float4(rotation(float3( _Size*(1+_outline), -_Size*(1+_outline),  _Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[5].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[5].wPos); cash[5].col = col*0;
				cash[6].wPos = float4(rotation(float3(-_Size*(1+_outline),  _Size*(1+_outline),  _Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[6].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[6].wPos); cash[6].col = col*0;
				cash[7].wPos = float4(rotation(float3( _Size*(1+_outline),  _Size*(1+_outline),  _Size*(1+_outline)),float3(0,0,0),angle,axis),0); cash[7].pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + cash[7].wPos); cash[7].col = col*0;
				//1
				
				tristream.Append(cash[0]); tristream.Append(cash[1]); tristream.Append(cash[2]); tristream.Append(cash[3]); tristream.RestartStrip();
				tristream.Append(cash[5]); tristream.Append(cash[1]); tristream.Append(cash[7]); tristream.Append(cash[3]); tristream.RestartStrip();
				tristream.Append(cash[4]); tristream.Append(cash[5]); tristream.Append(cash[6]); tristream.Append(cash[7]); tristream.RestartStrip();
				tristream.Append(cash[0]); tristream.Append(cash[3]); tristream.Append(cash[2]); tristream.Append(cash[6]); tristream.RestartStrip();
				tristream.Append(cash[3]); tristream.Append(cash[2]); tristream.Append(cash[7]); tristream.Append(cash[6]); tristream.RestartStrip();
				tristream.Append(cash[0]); tristream.Append(cash[1]); tristream.Append(cash[4]); tristream.Append(cash[5]); tristream.RestartStrip();
				*/
				
            }

			fixed4 frag (g2f i) : SV_Target
			{
				//float d = length(i.wPos.xy)/_Size;
				return float4(normalize(abs(i.col.rgb))*2,1);
				//clamp(0.5 - d*d, 0.0, 1.0));
			}
			ENDCG
		}
	}
}
