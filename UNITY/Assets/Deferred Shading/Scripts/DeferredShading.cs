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
	public Color SkyColor = Color.blue;
	public Color GroundColor = Color.white;
	public Texture2D JitterTex;
	private RenderBuffer[] colorBuffers;
	private RenderBuffer depthBuffer;
	private Material DirectionalLightMaterial;
	private Material GBufferMat;
	public bool ShowRTs = false; 
	
	void Awake()
	{
		originalCamera = camera;
	}
	
	void Start()
	{
		
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) 
	{
		if(!GBufferMat)
		{
			GBufferMat = new Material(GBufferShader);
			
			Shader.SetGlobalTexture("_MainTex", RTs[0]);
			Shader.SetGlobalTexture("_NormalTexture", RTs[1]);
			Shader.SetGlobalTexture("_DepthTexture", RTs[1]);
			Shader.SetGlobalTexture("_SpecularColor", RTs[2]);

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
		if(ShowRTs)
		{
			Vector2 size = new Vector2 (240, 120);
			float margin = 20;
			GUI.DrawTexture (new Rect (margin, Screen.height - (size.y + margin), size.x, size.y), RTs[0], ScaleMode.StretchToFill, false, 1);
			GUI.DrawTexture (new Rect (margin + margin + size.x, Screen.height - (size.y + margin), size.x, size.y), RTs[1], ScaleMode.StretchToFill, false, 1);
			GUI.DrawTexture (new Rect (margin + margin + margin + size.x + size.x, Screen.height - (size.y + margin), size.x, size.y), RTs[2], ScaleMode.StretchToFill, false, 1);
		}
		
	}
	
	public void DirectionalLighting (RenderTexture Input, RenderTexture Output)
	{
		//MainLight.transform.eulerAngles = new Vector3(MainLight.transform.eulerAngles.x - 10.0f, MainLight.transform.eulerAngles.y, MainLight.transform.eulerAngles.z);
		DirectionalLightMaterial.SetFloat("_LightIntensity", LightIntensity);
		DirectionalLightMaterial.SetColor("_LightColor", LightColor);
		DirectionalLightMaterial.SetColor("_SkyColor", SkyColor);
		DirectionalLightMaterial.SetColor("_GroundColor", GroundColor);
		DirectionalLightMaterial.SetVector("_LightDirection", MainLight.transform.forward);
		DirectionalLightMaterial.SetTexture("_MainTex", RTs[0]);
		DirectionalLightMaterial.SetTexture("_NormalTexture", RTs[1]);
		DirectionalLightMaterial.SetTexture("_DepthTexture", RTs[1]);
		DirectionalLightMaterial.SetTexture("_Jitter", JitterTex);
		DirectionalLightMaterial.SetMatrix("_InverseProj", renderingCamera.projectionMatrix.inverse);
		DirectionalLightMaterial.SetVector("_CameraWS", renderingCamera.transform.position);
		FrustumCorners();
		Graphics.Blit(Input, Output, DirectionalLightMaterial);
	}

	void ReformCameras()
	{
		renderingCamera = new GameObject("RenderingCamera").AddComponent<Camera>();
		renderingCamera.depthTextureMode |= DepthTextureMode.Depth;
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
	
	public void FrustumCorners()
	{
		float CAMERA_NEAR = 0.5f;
		float CAMERA_FAR = 50.0f;
		float CAMERA_FOV = 60.0f;	
		float CAMERA_ASPECT_RATIO = 1.333333f;

		CAMERA_NEAR = renderingCamera.nearClipPlane;
		CAMERA_FAR = renderingCamera.farClipPlane;
		CAMERA_FOV = renderingCamera.fieldOfView;
		CAMERA_ASPECT_RATIO = renderingCamera.aspect;
		
		Matrix4x4 frustumCorners = Matrix4x4.identity;
		
		float fovWHalf = CAMERA_FOV * 0.5f;
		
		Vector3 toRight = renderingCamera.transform.right * CAMERA_NEAR * Mathf.Tan (fovWHalf * Mathf.Deg2Rad) * CAMERA_ASPECT_RATIO;
		Vector3 toTop = renderingCamera.transform.up * CAMERA_NEAR * Mathf.Tan (fovWHalf * Mathf.Deg2Rad);
		
		Vector3 topLeft = (renderingCamera.transform.forward * CAMERA_NEAR - toRight + toTop);
		float CAMERA_SCALE = topLeft.magnitude * CAMERA_FAR/CAMERA_NEAR;	
		
		topLeft.Normalize();
		topLeft *= CAMERA_SCALE;
		
		Vector3 topRight = (renderingCamera.transform.forward * CAMERA_NEAR + toRight + toTop);
		topRight.Normalize();
		topRight *= CAMERA_SCALE;
		
		Vector3 bottomRight = (renderingCamera.transform.forward * CAMERA_NEAR + toRight - toTop);
		bottomRight.Normalize();
		bottomRight *= CAMERA_SCALE;
		
		Vector3 bottomLeft = (renderingCamera.transform.forward * CAMERA_NEAR - toRight - toTop);
		bottomLeft.Normalize();
		bottomLeft *= CAMERA_SCALE;
		
		frustumCorners.SetRow (0, topLeft); 
		frustumCorners.SetRow (1, topRight);		
		frustumCorners.SetRow (2, bottomRight);
		frustumCorners.SetRow (3, bottomLeft);
		
		DirectionalLightMaterial.SetMatrix ("_FrustumCornersWS", frustumCorners);
	}

	void OnDisable()
	{
		Destroy(renderingCamera.gameObject);
	}
}
