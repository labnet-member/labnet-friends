struct v2f_outline
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;

    UNITY_FOG_COORDS(1)

    UNITY_VERTEX_OUTPUT_STEREO
    VRCHAT_ATLAS_VERTEX_OUTPUT
};

VRCHAT_DEFINE_ATLAS_PROPERTY(half, _OutlineThickness);
VRCHAT_DEFINE_ATLAS_PROPERTY(half3, _OutlineColor);
VRCHAT_DEFINE_ATLAS_PROPERTY(half, _OutlineFromAlbedo);

sampler2D _OutlineMask;
VRCHAT_DEFINE_ATLAS_PROPERTY(half4, _OutlineMask_ST);
VRCHAT_DEFINE_ATLAS_PROPERTY(uint, _OutlineMaskChannel);
VRCHAT_DEFINE_ATLAS_TEXTUREMODE(_OutlineMask);

v2f_outline vert_outline (appdata v)
{
    v2f_outline o = (v2f_outline)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    VRCHAT_ATLAS_INITIALIZE_VERTEX_OUTPUT(v, o);
    VRCHAT_SETUP_ATLAS_INDEX_POST_VERTEX(o);

    uint maskChannel = VRCHAT_GET_ATLAS_PROPERTY(_OutlineMaskChannel);
    float mask = tex2Dlod(_OutlineMask, half4(v.uv, 0, 0))[maskChannel];
    float thickness = VRCHAT_GET_ATLAS_PROPERTY(_OutlineThickness);

    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
    worldPos += worldNormal * thickness * mask * 0.01;
    
    o.pos = UnityWorldToClipPos(float4(worldPos, 1));
    o.uv = v.uv;

    UNITY_TRANSFER_FOG(o, o.pos);

    return o;
}

half4 frag_outline (v2f_outline i) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    VRCHAT_SETUP_ATLAS_INDEX_POST_VERTEX(i);

    half3 outlineColor = VRCHAT_GET_ATLAS_PROPERTY(_OutlineColor);
    half outlineFromAlbedo = VRCHAT_GET_ATLAS_PROPERTY(_OutlineFromAlbedo);

    half3 color = outlineColor;

    UNITY_BRANCH if (outlineFromAlbedo)
    {
        color = lerp(color, tex2D(_MainTex, VRCHAT_TRANSFORM_ATLAS_TEX_MODE(i.uv, _MainTex)).rgb, outlineFromAlbedo);
    }

    half4 finalColor = half4(color, 1);
    UNITY_APPLY_FOG(i.fogCoord, finalColor);
    return finalColor;
}