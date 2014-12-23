using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof (Light))]
public class DirectionalLight : MonoBehaviour 
{

	[Range(0, 10)]
	public float LightIntensity = 1.0f;
	public Color LightColor = Color.white;
	public Shader DirectionalLightShader;
	private Camera CameraMain;
	private Material DirectionalLightMaterial;
	
	public void Start ()
	{
		CameraMain = Camera.main;
		DirectionalLightShader = Shader.Find("Hidden/L-Buffer");
	}
	
	public void DirectionalLighting (RenderTexture Input, RenderTexture Output)
	{
		DirectionalLightMaterial.SetFloat("_LightIntensity", LightIntensity);
		DirectionalLightMaterial.SetColor("_LightColor", LightColor);
		DirectionalLightMaterial.SetVector("_LightDirection", this.gameObject.transform.forward * -1.0f);
		DirectionalLightMaterial.SetTexture("_MainTex", DeferredShading.RTs[0]);
		Graphics.Blit(Input, Output, DirectionalLightMaterial);
	}
	
	public void OnRenderImage(RenderTexture source, RenderTexture destination) 
	{
		if(!DirectionalLightMaterial)
		{
			DirectionalLightMaterial = new Material(DirectionalLightShader);
			DirectionalLighting(source, destination);
		}
	}
	
	public void OnDisable ()
	{
		if(DirectionalLightMaterial)
			DestroyImmediate(DirectionalLightMaterial);
	}
}
