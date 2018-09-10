// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AS Occlusion Probes HDRP Debug"
{
    Properties
    {
		[HideInInspector] _tex3coord( "", 2D ) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline"="HDRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		Blend One Zero
		Cull Back
		ZTest LEqual
		ZWrite On
		Offset 0 , 0

		HLSLINCLUDE
		#pragma target 4.5
		#pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
		ENDHLSL

		
        Pass
        {
			
			Name "Depth prepass"
			Tags { "LightMode"="DepthForwardOnly" }

			ColorMask 0
			
            HLSLPROGRAM
        
            #pragma vertex Vert
            #pragma fragment Frag
        
			

            #define UNITY_MATERIAL_UNLIT
        
            #include "CoreRP/ShaderLibrary/Common.hlsl"
            #include "HDRP/ShaderPass/FragInputs.hlsl"
        
			#define SHADERPASS SHADERPASS_DEPTH_ONLY
            
		    #include "ShaderGraphLibrary/Functions.hlsl"
            #include "HDRP/ShaderVariables.hlsl"
        		
			#include "HDRP/Material/Material.hlsl"
           
			
            struct AttributesMesh
			{
                float4 positionOS : POSITION;
				float4 normalOS : NORMAL;
				
            };
           
			struct PackedVaryingsToPS
			{
				float4 positionCS : SV_Position;
				
			};

			struct SurfaceDescription
            {
                float Alpha;
                float AlphaClipThreshold;
            };
            

			PackedVaryingsToPS Vert( AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS outputPackedVaryingsToPS;

				UNITY_SETUP_INSTANCE_ID ( inputMesh );
				UNITY_TRANSFER_INSTANCE_ID ( inputMesh, outputVaryingsMeshToPS );
				
				
				inputMesh.positionOS.xyz +=  float3( 0, 0, 0 ) ;
				inputMesh.normalOS =  inputMesh.normalOS ;
				
				float3 positionRWS = TransformObjectToWorld ( inputMesh.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip ( positionRWS );
				outputPackedVaryingsToPS.positionCS = positionCS;
				return outputPackedVaryingsToPS;
			}

			void Frag ( PackedVaryingsToPS packedInput , out float4 outColor : SV_Target )
			{
				FragInputs input;
				ZERO_INITIALIZE ( FragInputs, input );
				input.worldToTangent = k_identity3x3;
				input.positionSS = packedInput.positionCS;
				
				PositionInputs posInput = GetPositionInput ( input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS );
				SurfaceData surfaceData;
				
				SurfaceDescription surfaceDescription = ( SurfaceDescription ) 0;
				
				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold =  0;

				ZERO_INITIALIZE ( SurfaceData, surfaceData );
				
				BuiltinData builtinData;
				ZERO_INITIALIZE ( BuiltinData, builtinData );
				builtinData.opacity = surfaceDescription.Alpha;
				builtinData.bakeDiffuseLighting = float3( 0.0, 0.0, 0.0 );
				builtinData.velocity = float2( 0.0, 0.0 );
				builtinData.shadowMask0 = 0.0;
				builtinData.shadowMask1 = 0.0;
				builtinData.shadowMask2 = 0.0;
				builtinData.shadowMask3 = 0.0;
				builtinData.distortion = float2( 0.0, 0.0 );
				builtinData.distortionBlur = 0.0;
				builtinData.depthOffset = 0.0;

				outColor = float4( 0.0, 0.0, 0.0, 0.0 );
			}
        
            ENDHLSL
        }
		
        Pass
        {
			
            Name "Forward Unlit"
            Tags { "LightMode"="ForwardOnly" }
        
			ColorMask RGBA

			
            HLSLPROGRAM
        
            #pragma vertex Vert
            #pragma fragment Frag
        
			

            #define UNITY_MATERIAL_UNLIT
        
            #include "CoreRP/ShaderLibrary/Common.hlsl"
            #include "HDRP/ShaderPass/FragInputs.hlsl"
        
            #define SHADERPASS SHADERPASS_FORWARD_UNLIT
            
		    #include "ShaderGraphLibrary/Functions.hlsl"
            #include "HDRP/ShaderVariables.hlsl"
        		
			#include "HDRP/Material/Material.hlsl"
           
			uniform float4x4 _OcclusionProbesWorldToLocal;
			uniform sampler3D _OcclusionProbes;
			uniform float4 _OcclusionProbes_ST;
			float SampleOcclusionProbes3_g3( float3 positionWS , float4x4 OcclusionProbesWorldToLocal , float OcclusionProbes )
			{
				float occlusionProbes = 1;
				float3 pos = mul(_OcclusionProbesWorldToLocal, float4(positionWS, 1)).xyz;
				occlusionProbes = tex3D(_OcclusionProbes, pos).a;
				return occlusionProbes;
			}
			

            struct AttributesMesh
			{
                float4 positionOS : POSITION;
				float4 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
            };
           
			struct PackedVaryingsToPS
			{
				float4 positionCS : SV_Position;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
			};

			struct SurfaceDescription
            {
                float3 Color;
                float Alpha;
                float AlphaClipThreshold;
            };
            
			PackedVaryingsToPS Vert( AttributesMesh inputMesh  )
			{
				PackedVaryingsToPS outputPackedVaryingsToPS;

				UNITY_SETUP_INSTANCE_ID ( inputMesh );
				UNITY_TRANSFER_INSTANCE_ID ( inputMesh, outputVaryingsMeshToPS );
				
				float3 ase_worldPos = GetAbsolutePositionWS( mul( GetObjectToWorldMatrix(), inputMesh.positionOS).xyz );
				outputPackedVaryingsToPS.ase_texcoord.xyz = ase_worldPos;
				
				outputPackedVaryingsToPS.ase_texcoord1.xyz = inputMesh.ase_texcoord.xyz;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				outputPackedVaryingsToPS.ase_texcoord.w = 0;
				outputPackedVaryingsToPS.ase_texcoord1.w = 0;
				inputMesh.positionOS.xyz +=  float3( 0, 0, 0 ) ;
				inputMesh.normalOS =  inputMesh.normalOS ;

				float3 positionRWS = TransformObjectToWorld ( inputMesh.positionOS.xyz );
				float4 positionCS = TransformWorldToHClip ( positionRWS );
				outputPackedVaryingsToPS.positionCS = positionCS;
				return outputPackedVaryingsToPS;
			}

			float4 Frag ( PackedVaryingsToPS packedInput ) : SV_Target
			{
				FragInputs input;
				ZERO_INITIALIZE ( FragInputs, input );
				input.worldToTangent = k_identity3x3;
				input.positionSS = packedInput.positionCS;
				
				PositionInputs posInput = GetPositionInput ( input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS );
				SurfaceData surfaceData;
				
				SurfaceDescription surfaceDescription = ( SurfaceDescription ) 0;
				float3 ase_worldPos = packedInput.ase_texcoord.xyz;
				float3 positionWS3_g3 = ase_worldPos;
				float4x4 OcclusionProbesWorldToLocal3_g3 = _OcclusionProbesWorldToLocal;
				float3 uv_OcclusionProbes3 = packedInput.ase_texcoord1.xyz;
				uv_OcclusionProbes3.xy = packedInput.ase_texcoord1.xyz.xy * _OcclusionProbes_ST.xy + _OcclusionProbes_ST.zw;
				float OcclusionProbes3_g3 = tex3D( _OcclusionProbes, uv_OcclusionProbes3 ).r;
				float localSampleOcclusionProbes3_g3 = SampleOcclusionProbes3_g3( positionWS3_g3 , OcclusionProbesWorldToLocal3_g3 , OcclusionProbes3_g3 );
				float lerpResult1_g3 = lerp( 1.0 , localSampleOcclusionProbes3_g3 , 1.0);
				float3 temp_cast_1 = (lerpResult1_g3).xxx;
				
				surfaceDescription.Color =  temp_cast_1;
				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold =  0;

				ZERO_INITIALIZE ( SurfaceData, surfaceData );
				surfaceData.color = surfaceDescription.Color;
				
				BuiltinData builtinData;
				ZERO_INITIALIZE ( BuiltinData, builtinData );
				builtinData.opacity = surfaceDescription.Alpha;
				builtinData.bakeDiffuseLighting = float3( 0.0, 0.0, 0.0 );
				builtinData.velocity = float2( 0.0, 0.0 );
				builtinData.shadowMask0 = 0.0;
				builtinData.shadowMask1 = 0.0;
				builtinData.shadowMask2 = 0.0;
				builtinData.shadowMask3 = 0.0;
				builtinData.distortion = float2( 0.0, 0.0 );
				builtinData.distortionBlur = 0.0;
				builtinData.depthOffset = 0.0;

				BSDFData bsdfData = ConvertSurfaceDataToBSDFData ( input.positionSS.xy, surfaceData );
				float4 outColor = ApplyBlendMode ( bsdfData.color + builtinData.emissiveColor, builtinData.opacity );
				outColor = EvaluateAtmosphericScattering ( posInput, outColor );
				return outColor;
			}
        
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
	
	CustomEditor "ASEMaterialInspector"
	
}
/*ASEBEGIN
Version=15600
1927;29;1906;968;953;484;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;4;-458,1;Float;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;5;-298,7;Float;False;ASF Sample Occlusion Probes;0;;3;1a84485513afd974d8889913fb2a879f;0;1;7;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;16,2;Float;False;True;2;Float;ASEMaterialInspector;0;3;AS Occlusion Probes HDRP Debug;dfe2f27ac20b08c469b2f95c236be0c3;0;1;Forward Unlit;5;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;True;0;False;-1;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque;Queue=Geometry;True;5;0;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;True;1;LightMode=ForwardOnly;False;0;;0;0;Standard;0;5;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;2;Float;ASEMaterialInspector;0;1;ASETemplateShaders/HDSRPUnlit;dfe2f27ac20b08c469b2f95c236be0c3;0;0;Depth prepass;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;True;0;False;-1;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;3;RenderPipeline=HDRenderPipeline;RenderType=Opaque;Queue=Geometry;True;5;0;False;False;False;True;False;False;False;False;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;False;False;True;1;LightMode=DepthForwardOnly;False;0;;0;0;Standard;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;0
WireConnection;5;7;4;0
WireConnection;1;0;5;0
ASEEND*/
//CHKSM=7711D26C4F8AF29DC21E04F53B930B2B93BED837