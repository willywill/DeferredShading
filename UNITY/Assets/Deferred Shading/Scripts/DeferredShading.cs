using UnityEngine;
using System.Collections;

public class DeferredShading : MonoBehaviour 
{

	Camera originalCamera;
	Camera renderingCamera;
	public static RenderTexture[] RTs;
	public Shader GBufferShader;
	public Shader DirectionalLightShader;
	public Light MainLight;
	public float LightIntensity = 1.0f;
	public Color LightColor = Color.white;
	private RenderBuffer[] colorBuffers;
	private RenderBuffer depthBuffer;
	private Material DirectionalLightMaterial;
	private Material GBufferMat;
	
	void Awake()
	{
		originalCamera = camera;
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) 
	{
		if(!GBufferMat)
		{
			GBufferMat = new Material(GBufferShader);
			GBufferMat.SetTexture("_MainTex", RTs[0]);
			GBufferMat.SetTexture("_NormalTexture", RTs[1]);
			GBufferMat.SetTexture("_DepthTexture", RTs[1]);
			GBufferMat.SetTexture("_SpecColor", RTs[2]);

			source = RTs[0];
			
			Graphics.Blit(RTs[0], destination, GBufferMat);
			Graphics.Blit(RTs[1], destination, GBufferMat);
			Graphics.Blit(RTs[2], destination, GBufferMat);
			
		}
		
		if(!DirectionalLightMaterial)
		{
			DirectionalLightMaterial = new Material(DirectionalLightShader);
			DirectionalLighting(source, destination);
		}
	}

	void OnEnable()
	{
		CreateCamera();
	}
	
	void CreateCamera() 
	{
		ReformCameras();
		CreateBuffers();
	}
	
	void OnPostRender()
	{
		renderingCamera.SetTargetBuffers(colorBuffers, depthBuffer);
		renderingCamera.RenderWithShader(GBufferShader, "");
	}
	
	void OnGUI()
	{
		//GUI.DrawTexture(new Rect(0, 0, RTs[0].width, RTs[0].height), RTs[0], ScaleMode.StretchToFill, false);
	}
	
	public void DirectionalLighting (RenderTexture Input, RenderTexture Output)
	{
		MainLight.transform.eulerAngles = new Vector3(MainLight.transform.eulerAngles.x, MainLight.transform.eulerAngles.y * -1.0f, MainLight.transform.eulerAngles.z);
		DirectionalLightMaterial.SetFloat("_LightIntensity", LightIntensity);
		DirectionalLightMaterial.SetColor("_LightColor", LightColor);
		DirectionalLightMaterial.SetVector("_LightDirection", MainLight.transform.forward * 1.0f);
		DirectionalLightMaterial.SetTexture("_MainTex", RTs[0]);
		DirectionalLightMaterial.SetTexture("_NormalTexture", RTs[1]);
		DirectionalLightMaterial.SetTexture("_DepthTexture", RTs[1]);
		Graphics.Blit(Input, Output, DirectionalLightMaterial);
	}

	void ReformCameras()
	{
		renderingCamera = new GameObject("RenderingCamera").AddComponent<Camera>();
		
		renderingCamera.enabled = false;
		
		renderingCamera.transform.parent = transform;
		renderingCamera.transform.localPosition = Vector3.zero;
		renderingCamera.transform.localRotation = Quaternion.identity;
		
		originalCamera.renderingPath = RenderingPath.VertexLit;
		originalCamera.cullingMask = 0;
		originalCamera.clearFlags = CameraClearFlags.Depth;
		originalCamera.backgroundColor = Color.black;
		
		renderingCamera.renderingPath = RenderingPath.VertexLit;
		renderingCamera.clearFlags = CameraClearFlags.SolidColor;
		renderingCamera.farClipPlane = originalCamera.farClipPlane;
		renderingCamera.fieldOfView = originalCamera.fieldOfView;
	}
	
	void CreateBuffers ()
	{
		RTs = new RenderTexture[] { 
			RenderTexture.GetTemporary(Screen.width, Screen.height, 32, RenderTextureFormat.Default),
			RenderTexture.GetTemporary(Screen.width, Screen.height, 32, RenderTextureFormat.Default),
			RenderTexture.GetTemporary(Screen.width, Screen.height, 32, RenderTextureFormat.Default),
			};
		
		colorBuffers = new RenderBuffer[] { RTs[0].colorBuffer, RTs[1].colorBuffer, RTs[2].colorBuffer };
		depthBuffer = RTs[1].depthBuffer;
	}

	void OnDisable()
	{
		Destroy(renderingCamera.gameObject);
	}
}
