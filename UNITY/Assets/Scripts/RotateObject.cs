using UnityEngine;
using System.Collections;

public class RotateObject : MonoBehaviour 
{
	public float speed = 15.0f;
	
	// Update is called once per frame
	void Update () 
	{
		transform.Rotate(0.0f, 0.0f, speed * Time.deltaTime);
	}
}
