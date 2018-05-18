Shader "SeparableSubsurfaceScatter" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _SSS ("SSS", Range(0, 10)) = 0
    }
CGINCLUDE
#include "UnityCG.cginc"
#define Sample 16
#define distanceToProjectionWindow 5.671281819617709
            uniform sampler2D _CameraDepthTexture;
            uniform sampler2D _MainTex; uniform float4 _MainTex_TexelSize;
            uniform float _SSSScale;
            uniform float4 kernel[Sample];
            sampler2D _CameraGBufferTexture2;

            
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 SSS( float DepthColor, float4 colorM , float2 UV , float2 dir , float sssWidth ){
              float scale = distanceToProjectionWindow / DepthColor;
              float2 finalStep = sssWidth * scale * dir;
              float4 colorBlurred = colorM;
              colorBlurred.rgb *= kernel[0].rgb;
                                    
              float2 offset = 0;
              float4 color = 0;
              float depth = 0;
              float s = 0;
              for (int i = 1; i < Sample; i++){
                 offset = UV + kernel[i].a * finalStep;
                 color = tex2D(_MainTex, offset);
                 depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, offset)) - _ProjectionParams.g;
                        					
                 s = saturate(1701.3845458853127 * sssWidth * abs(DepthColor - depth));
                 color.rgb = lerp(color.rgb, colorM.rgb, s);
                 colorBlurred.rgb += kernel[i].rgb * color.rgb;
              }
            return colorBlurred;
            }
ENDCG
    SubShader {
        ZTest Always
        ZWrite Off
		Cull off
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            float4 frag(VertexOutput i) : COLOR {
                float SceneDepth_Sorce = max(1e-5, LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv0)) - _ProjectionParams.g);
				float4 colorM = tex2D(_MainTex, i.uv0);
				float tp = step(0.1, tex2D(_CameraGBufferTexture2, i.uv0).a);
                float3 XBlur = SSS( SceneDepth_Sorce , colorM, i.uv0 , float2(0.3333333333333,0) , _SSSScale * _MainTex_TexelSize.x).rgb;
				return lerp(colorM, float4(XBlur, 1), tp);
            }
            ENDCG
        }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            float4 frag(VertexOutput i) : COLOR {
                float SceneDepth_Sorce = max(1e-5, LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv0)) - _ProjectionParams.g);
				float4 colorM = tex2D(_MainTex, i.uv0);
				float tp = step(0.1, tex2D(_CameraGBufferTexture2, i.uv0).a);
                float3 YBlur = SSS( SceneDepth_Sorce , colorM, i.uv0 , float2(0,0.3333333333333) , _SSSScale * _MainTex_TexelSize.y).rgb;
				return lerp(colorM, float4(YBlur,1), tp);
            }
            ENDCG
        }
    }
}
