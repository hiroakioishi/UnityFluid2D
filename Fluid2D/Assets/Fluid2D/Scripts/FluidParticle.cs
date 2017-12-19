using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class FluidParticle : MonoBehaviour {

	public Fluid2D Fluid2D;

	public int ParticleNum = 120000;
	
	private const int PARTICLES_MAX_NUM = 65535; 
	
	public Shader KernelShader;
	
	private Material _kernelMat;
	public  Material RenderMat;

	private RenderTexture[] _positionBuffer;
	private RenderTexture[] _velocityBuffer;

	private List <Material> _matList = new List <Material> ();
	
	private int _bufferSizeWidth  = 1;
	private int _bufferSizeHeight = 1;
	
	[Range (0.0f, 1.0f)]
	public float Throttle = 1.0f;
	
	public float RandomSeed = 0.0f;
	
	public float LifeTimeMin = 1.0f;
	public float LifeTimeMax = 5.0f;
	
	public Color ParticleColor = Color.white;
	
	
	void Start () {
		
		Setup ();
		
	}
	
	void Update () {
		
		Step ();
		Render ();
		
	}
	
	
	public void Setup () {
		
		_createMesh ();
		_createBuffers ();
		_resetBuffers ();
		_createMaterials ();
		
		// init
		RandomSeed = Random.value;
		_kernelMat.SetFloat ("_RandomSeed", RandomSeed);
		_kernelMat.SetFloat ("_Throttle",   Throttle);  
		Graphics.Blit (null, _positionBuffer [0], _kernelMat, 0);
		Graphics.Blit (_positionBuffer [0], _positionBuffer [1]);

	}
	
	public void Step () {

		_kernelMat.SetVector ("_FlowScale", new Vector2 (1.0f / Fluid2D.BufferSizeWidth, 1.0f / Fluid2D.BufferSizeHeight));
		_kernelMat.SetFloat ("_DragCoefficient", 0.5f);
		_kernelMat.SetTexture ("_PositionTex", _positionBuffer [0]);
		_kernelMat.SetTexture ("_VelocityTex", _velocityBuffer [0]);
		_kernelMat.SetTexture ("_FlowVelocityFieldTex", Fluid2D.GetFlowVelocityFieldTex ());
		Graphics.Blit (null, _velocityBuffer [1], _kernelMat, 1);
		_swapBuffer (_velocityBuffer);
		
		_kernelMat.SetFloat ("_RandomSeed", RandomSeed);
		_kernelMat.SetFloat ("_Throttle", Throttle);
		_kernelMat.SetFloat ("_LifeTimeMin", 1.0f / LifeTimeMin);
		_kernelMat.SetFloat ("_LifeTimeMax", 1.0f / LifeTimeMax);
		_kernelMat.SetFloat ("_dT", Time.deltaTime);
		_kernelMat.SetTexture ("_PositionTex", _positionBuffer [0]);
		Graphics.Blit (null, _positionBuffer [1], _kernelMat, 2);
		_swapBuffer (_positionBuffer);
		
	}
	
	public void Render () {
		
		foreach (Material m in _matList) {
			m.SetColor ("_Color", ParticleColor);
			m.SetTexture ("_PositionTex", _positionBuffer [0]);
		}
		
	}
	
	void _createMesh () {
		
		_bufferSizeWidth  = Mathf.FloorToInt (Mathf.Sqrt (ParticleNum));
		_bufferSizeHeight = _bufferSizeWidth;
		ParticleNum = _bufferSizeWidth * _bufferSizeHeight;
		
		int meshNum = Mathf.CeilToInt(ParticleNum / (PARTICLES_MAX_NUM * 1.0f));
		Debug.Log (meshNum);
		
		int totalVertices    = ParticleNum;
		int startVertexIndex = 0;
		int goIndex = 0;
		while (totalVertices > 0) {
			
			int vertCount = Mathf.Min (PARTICLES_MAX_NUM, totalVertices);
			
			GameObject go = new GameObject (
				"Mesh_" + goIndex,
				new System.Type [] {
				typeof (MeshFilter),
				typeof (MeshRenderer)}
			);
			go.transform.parent = transform;
			
			Vector3 [] vertices  = new Vector3 [vertCount];
			Vector2 [] uvs       = new Vector2 [vertCount];
			int []     indices   = new int [vertCount];
			
			for (int i = 0; i < vertCount; i++) {
				int ii = startVertexIndex + i;
				float tx = 1.0f * (ii % _bufferSizeWidth ) / (_bufferSizeWidth  * 1.0f);
				float ty = 1.0f * (ii / _bufferSizeHeight) / (_bufferSizeHeight * 1.0f);
				vertices [i] = Random.insideUnitSphere;
				uvs      [i] = new Vector2 (tx, ty);
				indices  [i] = i;
			}
			
			Mesh mesh     = new Mesh ();
			mesh.name     = vertCount.ToString ("0000000");
			mesh.vertices = vertices;
			mesh.uv       = uvs;
			mesh.SetIndices (indices, MeshTopology.Points, 0);
			mesh.RecalculateBounds ();
			mesh.UploadMeshData (true);
			
			go.GetComponent <Renderer> ().material = RenderMat;
			go.GetComponent <MeshFilter> ().mesh = mesh;
			
			_matList.Add (go.GetComponent <Renderer> ().material);

			totalVertices    -= vertCount;
			startVertexIndex += vertCount;
			
			goIndex++;
			
		}
		
		Debug.Log (ParticleNum);
		
	}
	
	void _createBuffers () {
		
		_createBuffer (ref _positionBuffer, _bufferSizeWidth, _bufferSizeHeight);
		_createBuffer (ref _velocityBuffer, _bufferSizeWidth, _bufferSizeHeight);

	}
	
	void _resetBuffers () {
		
		_resetBuffer (ref _positionBuffer);
		_resetBuffer (ref _velocityBuffer);

	}
	
	void _destroyBuffers () {
		
		_destroyBuffer (ref _positionBuffer);
		_destroyBuffer (ref _velocityBuffer);
		
	}
	
	void _createMaterials () {
		
		_createMaterial (ref _kernelMat, KernelShader);

	}
	
	void _destroyMaterials () {
		
		_destroyMaterial (ref _kernelMat);
	
	}
	
	void _createBuffer (ref RenderTexture[] rt_, int bufferWidth_, int bufferHeight_) {
		
		rt_ = new RenderTexture[2];
		rt_ [0] = new RenderTexture (bufferWidth_, bufferHeight_, 0, RenderTextureFormat.ARGBHalf);
		rt_ [0].filterMode   = FilterMode.Bilinear;
		rt_ [0].wrapMode     = TextureWrapMode.Clamp;
		rt_ [0].hideFlags    = HideFlags.DontSave;
		rt_ [0].generateMips = false;
		rt_ [0].Create ();
		rt_ [1] = new RenderTexture (bufferWidth_, bufferHeight_, 0, RenderTextureFormat.ARGBHalf);
		rt_ [1].filterMode   = FilterMode.Bilinear;
		rt_ [1].wrapMode     = TextureWrapMode.Clamp;
		rt_ [1].hideFlags    = HideFlags.DontSave;
		rt_ [1].generateMips = false;
		rt_ [1].Create ();
		
	}
	
	void _createBuffer (ref RenderTexture rt_, int bufferWidth_, int bufferHeight_) {
		
		rt_ = new RenderTexture (bufferWidth_, bufferHeight_, 0, RenderTextureFormat.ARGBHalf);
		rt_.filterMode = FilterMode.Bilinear;
		rt_.wrapMode   = TextureWrapMode.Clamp;
		rt_.hideFlags  = HideFlags.DontSave;
		rt_.Create ();
		
	}
	
	void _resetBuffer (ref RenderTexture[] rt_) {
		
		Graphics.SetRenderTarget (rt_ [0]);
		GL.Clear (false, true, Color.black);
		Graphics.SetRenderTarget (null);
		
		Graphics.SetRenderTarget (rt_ [1]);
		GL.Clear (false, true, Color.black);
		Graphics.SetRenderTarget (null);
		
	}
	
	void _resetBuffer (ref RenderTexture rt_) {
		
		Graphics.SetRenderTarget (rt_);
		GL.Clear (false, true, Color.black);
		Graphics.SetRenderTarget (null);
		
	}
	
	void _destroyBuffer (ref RenderTexture[] buffer_) {
		
		if (buffer_ != null && buffer_.Length > 0) {
			for (int i = 0; i < buffer_.Length; i++) {
				DestroyImmediate (buffer_ [i]);
			}
		}
		
	}
	
	void _destroyBuffer (ref RenderTexture buffer_) {
		
		if (buffer_ != null) {
			DestroyImmediate (buffer_);
		}
		
	}
	
	void _swapBuffer (RenderTexture[] buffer_) {
		
		RenderTexture temp = buffer_ [0];
		buffer_ [0] = buffer_ [1];
		buffer_ [1] = temp;
		
	}
	
	void _createMaterial (ref Material mat_, Shader shader_) {
		
		if (mat_ == null) mat_ = new Material (shader_);
		
	}
	
	void _destroyMaterial (ref Material mat_) {
		
		if (mat_ != null) DestroyImmediate (mat_);
		
	}
	
	void OnGUI () {

		int  size = 64;
		Rect r02  = new Rect (size * 0, size * 2, size, size);
		Rect r12  = new Rect (size * 1, size * 2, size, size);
		Rect r03  = new Rect (size * 0, size * 3, size, size);
		Rect r13  = new Rect (size * 1, size * 3, size, size);
		
		GUI.DrawTexture (r02, _positionBuffer [0]);
		GUI.Label (r02, "_positionBuffer [0]");
		GUI.DrawTexture (r12, _positionBuffer [1]);
		GUI.Label (r12, "_positionBuffer [1]");
		GUI.DrawTexture (r03, _velocityBuffer [0]);
		GUI.Label (r03, "_velocityBuffer [0]");
		GUI.DrawTexture (r13, _velocityBuffer [1]);
		GUI.Label (r13, "_velocityBuffer [1]");

		
	}
}
