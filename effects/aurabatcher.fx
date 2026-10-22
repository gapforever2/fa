// Dedicated terrain-aware material for native aura radius geometry.
//
// This intentionally lives in its own effect file.  The retail effects.scd also
// supplies primbatcher.fx and can win the virtual-file lookup, hiding techniques
// added to FAF's file under the same path.

float4x4 CompositeMatrix;
texture Texture1;
float AlphaMultiplier = 1.0;

sampler LinearSampler = sampler_state
{
    Texture = (Texture1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_OUTPUT
{
    float4 Pos : POSITION;
    float4 Color : COLOR0;
    float2 Tex1 : TEXCOORD0;
};

VS_OUTPUT AuraTerrainVS(
    float3 Pos : POSITION,
    float4 Color : COLOR0,
    float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out;
    CompatSwizzle(Color);

    Out.Pos = mul(float4(Pos, 1), CompositeMatrix);
    // Keep terrain-following strips visible despite terrain LOD differences.
    Out.Pos.z -= 0.0001f * Out.Pos.w;
    Out.Color = Color;
    Out.Tex1 = Tex;
    return Out;
}

float4 AuraTerrainPS(
    float4 Pos : POSITION,
    float4 Diff : COLOR0,
    float2 Tex1 : TEXCOORD0) : COLOR
{
    float4 color = tex2D(LinearSampler, Tex1) * Diff;
    color.a *= AlphaMultiplier;
    return color;
}

technique TAuraTerrain
{
    pass P0
    {
        AlphaState( AlphaBlend_SrcAlpha_InvSrcAlpha_Write_RGB )
        DepthState( Depth_Enable_LessEqual_Write_None )
        RasterizerState( Rasterizer_Cull_None )

#ifndef DIRECT3D10
        AlphaTestEnable = true;
        AlphaRef = 0;
        AlphaFunc = Greater;
#endif

        VertexShader = compile vs_1_1 AuraTerrainVS();
        PixelShader = compile ps_2_0 AuraTerrainPS();
    }
}
