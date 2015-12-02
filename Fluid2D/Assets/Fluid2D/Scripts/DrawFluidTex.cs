using UnityEngine;
using System.Collections;

public class DrawFluidTex : MonoBehaviour {

	public Fluid2D Fluid2D;

	Material _mat;

	void Start () {

		_mat = GetComponent <Renderer> ().material;

	}
	
	void Update () {

		_mat.mainTexture = Fluid2D.GetFluidTex ();

	}
}
