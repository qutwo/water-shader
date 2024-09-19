Shader "Unlit/NewUnlitShader"
{
    Properties
    {
  
        _Color ("color",Color) = (1,1,1,1)
        _freq("frequency",float) = 0
        _amp("amp",float) = 0
        _speed("speed",float) = 0
        _waves("waves",float) = 0
        _specularPower("specular",float) = 0
        _sky("sky", Cube) = ""{} 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
       

        Pass
        {
          
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _freq;
            float _amp;
            float _speed;
            float _specularPower;
            samplerCUBE _sky;
            float _waves;
           
            


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normals:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normals : TEXCOORD1;
                float3  wPos : TEXCOORD2;
             
            };
            float random (float2 uv)
            {
                return frac(sin(dot(uv,float2(12.9898,78.233)))*43758.5453123);
            }
            float3 expSin(float2 vertex, float frequency, float amplitude, float speed,float xMultiplier, float yMultiplier,float2 prev)
            {
                float vertexValue = (xMultiplier*vertex.x + yMultiplier*vertex.y) + prev;
                return float3(exp(sin(vertexValue*frequency + _Time.y*speed)*amplitude),exp(sin(vertexValue*frequency + _Time.y*speed)*amplitude)*cos(vertexValue*frequency + _Time.y*speed)*amplitude*frequency*xMultiplier,exp(sin(vertexValue*frequency + _Time.y*speed)*amplitude)*cos(vertexValue*frequency + _Time.y*speed)*amplitude*frequency*yMultiplier);
            }
            float3 fractionalBrownian(float2 vertex)
            {
                float delFreq = 1.18;
                float delAmp = 0.82;
                float freq = _freq;
                float amp = _amp;
                float3 sum = float3(0,0,0);
                float2 prev = float2(0,0);
                for(int i = 0; i<_waves; i++)
                {
                    
                    float3 current = expSin(vertex ,freq,amp,_speed,(random(float2(delAmp,i))*2)-1,(random(float2(delAmp,delFreq))*2)-1,prev);                    
                    sum += current;
                    prev += current.yz;
                    freq *= delFreq;
                    amp *= delAmp;
                }
                return sum;
            }
            v2f vert (appdata v)
            {
                v2f o;
              
                float wave = fractionalBrownian(v.vertex.xy).x ;
                v.vertex.z += wave;
                float3 binormal = float3(1,0,fractionalBrownian(v.vertex.xy).y );
                float3 tangent = float3(0,1,fractionalBrownian(v.vertex.xy).z);
                v.normals = cross(binormal,tangent);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normals = UnityObjectToWorldNormal(v.normals);
                o.wPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.uv;
                return o;
               
            }

            float4 frag (v2f i) : SV_Target
            {
               
                
                float3 N = normalize(i.normals);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - i.wPos);
                float3 H = normalize(L+V);
                float3 R = normalize(reflect(-V,N));
                float3 sky = texCUBE(_sky,R).rgb; 
                float3 diffuseLight = saturate(dot(L,N))*_LightColor0.xyz;
                float2 uv = i.uv ;
                float3 specularLight = pow(saturate(dot(H,N))  ,_specularPower)*_LightColor0.xyz;
                
                return float4(saturate(diffuseLight*0.3 + specularLight + _Color.xyz*0.2 +sky*0.3) ,1);
                
               
            }
            ENDCG
        }
    }
}
