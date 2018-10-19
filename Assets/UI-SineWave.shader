// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Modified to support SDF

Shader "UI/SineWave"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _FillTex ("Fill Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _T("Times", Vector) = (1,1,1,1)
        _A("Amplitudes", Vector) = (1,1,1,1)
        _Aspect("Aspect", Float) = 1.777
        _SoftEdge("Soft edge", Float) = 0.99
        _WaveWidth("Wave width", Range(0, 0.1)) = 0.98

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float2 texcoord2 : TEXCOORD1;
                float4 worldPosition : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _FillTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float4 _FillTex_ST;
            float4 _T;
            float4 _A;
            float _Aspect;
            float _SoftEdge;
            float _WaveWidth;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                OUT.texcoord2 = TRANSFORM_TEX(v.texcoord, _FillTex);
                OUT.color = v.color * _Color;
                return OUT;
            }

            float wave(float t1, float t2, float a1, float a2, float scale)
            {
                return (sin(t1) * a1 + sin(t2) * a2) * scale;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color = tex2D(_FillTex, IN.texcoord2);
                float waveScaleY = _WaveWidth / (_A.x + _A.y);
                float waveScaleX = waveScaleY / _Aspect;
                float top = 1.0 + wave(IN.texcoord.x * _T.x * _Aspect, IN.texcoord.x * _T.y * _Aspect, _A.x, _A.y, waveScaleY) - _WaveWidth;
                float bottom = -1.0 + wave((IN.texcoord.x + 2.0) * _T.x * _Aspect, (IN.texcoord.x + 2.0) * _T.y * _Aspect, _A.x, _A.y, waveScaleY) + _WaveWidth;
                float left = -1.0 + wave((IN.texcoord.y + 3.0) * _T.x, (IN.texcoord.y + 3.0) * _T.y, _A.x, _A.y, waveScaleX) + _WaveWidth / _Aspect;
                float right = 1.0 + wave((IN.texcoord.y + 1.0) * _T.x, (IN.texcoord.y + 1.0) * _T.y, _A.x, _A.y, waveScaleX) - _WaveWidth / _Aspect;
                fixed c1 = smoothstep(0.0, _SoftEdge, top - IN.texcoord.y);
                fixed c2 = smoothstep(0.0, _SoftEdge, IN.texcoord.y - bottom);
                fixed c3 = smoothstep(0.0, _SoftEdge, right - IN.texcoord.x);
                fixed c4 = smoothstep(0.0, _SoftEdge, IN.texcoord.x - left);
                color.a = (c1 * c2 * c3 * c4);
                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }
        ENDCG
        }
    }
}
