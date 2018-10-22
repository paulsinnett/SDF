// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Modified to support SDF

Shader "UI/Textured3x3Slice"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _LeftRightTex ("Left and Right sides", 2D) = "white" {}
        _FillTex ("Fill Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Widths ("Widths", Vector) = (0.1,0.1,0.1,0.1) 
        // width of border on source texture in U, 
        // height of border on source texture in V, 
        // widths of borders on screen as a fraction of the image, 
        // heights of borders on screen as a fraction of the image
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
            sampler2D _LeftRightTex;
            sampler2D _FillTex;
            fixed4 _Color;
            float4 _ClipRect;
            float4 _Slices;
            float4 _Widths;
            float4 _MainTex_ST;
            float4 _FillTex_ST;

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

            float ilerp(float a, float b, float x)
            {
                return saturate((x - a) / (b - a));
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float sides[4] = 
                {
                    tex2D(_LeftRightTex, float2(ilerp(0, _Widths[2], IN.texcoord[0]) * _Widths[0], IN.texcoord[1])).a,
                    tex2D(_MainTex, float2(IN.texcoord[0], (1 - (1 - ilerp(1 - _Widths[3], 1, IN.texcoord[1])) * _Widths[1]))).a,
                    tex2D(_LeftRightTex, float2(1 - (1 - ilerp(1 - _Widths[2], 1, IN.texcoord[0])) * (1 - _Widths[0]), IN.texcoord[1])).a,
                    tex2D(_MainTex, float2(IN.texcoord[0], ilerp(0, _Widths[3], IN.texcoord[1]) * (1 - _Widths[1]))).a
                };
                fixed4 color = tex2D(_FillTex, IN.texcoord2);
                color.a = sides[0] * sides[1] * sides[2] * sides[3];
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
