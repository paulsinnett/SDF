using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class CreateSDFTexture : EditorWindow
{
	// Add menu item named "Search and Replace" to the Edit menu
	Texture2D source;
	Vector2Int dimensions;
	int distance;

	[MenuItem("Assets/Create/SDF Texture")]
	public static void ShowWindow()
	{
		//Show existing window instance. If one doesn't exist, make one.
		EditorWindow.GetWindow(typeof(CreateSDFTexture));
	}

	bool InsideShape(int x, int y)
	{
		return source.GetPixel(x, y).a > 0.5f;
	}

	float NearestEdge(int x, int y)
	{
		float nearest = this.distance;
		bool inside = InsideShape(x, y);
		for (int dy = -this.distance; dy <= this.distance; ++dy)
		{
			for (int dx = -this.distance; dx <= this.distance; ++dx)
			{
				float distance = new Vector2(dx, dy).magnitude;
				if (distance < this.distance && inside != InsideShape(x + dx, y + dy) && distance < nearest)
				{
					nearest = distance;
				}
			}
		}
		return inside ?
		       (Mathf.Lerp(0.5f, 1.0f, nearest / this.distance)):
		       (Mathf.Lerp(0.5f, 0.0f, nearest / this.distance));
	}

	Texture2D CreateSDF()
	{
		Color colour = Color.white;
		Texture2D SDF = new Texture2D(dimensions.x, dimensions.y, TextureFormat.Alpha8, false);
		Debug.LogFormat("Texture {0} x {1} {2}", SDF.width, SDF.height, SDF.format.ToString());
		for (int y = 0; y < dimensions.y; ++y)
		{
			for (int x = 0; x < dimensions.x; ++x)
			{
				int sourceX = Mathf.RoundToInt((float)(source.width) * (float)x / (float)(dimensions.x));
				int sourceY = Mathf.RoundToInt((float)(source.height) * (float)y / (float)(dimensions.y));
				colour.a = NearestEdge(sourceX, sourceY);
				SDF.SetPixel(x, y, colour);
			}
		}
		SDF.Apply();
		return SDF;
	}

	void OnGUI()
	{
		GUILayout.Label("Create SDF Texture", EditorStyles.boldLabel);
		source = EditorGUILayout.ObjectField("Source Texture", source, typeof(Texture2D), false) as Texture2D;
		dimensions = EditorGUILayout.Vector2IntField(
		                 new GUIContent("SDF dimensions", "dimensions of the output SDF texture in pixels"), dimensions);
		distance = EditorGUILayout.IntField(
		               new GUIContent("Distance px", "range of the distance field in pixels on the source texture"), distance);
		if (GUILayout.Button("Create SDF Texture"))
		{
			string outputPath = EditorUtility.SaveFilePanel(
			                        "Output SDF texture as PNG",
			                        "",
			                        source.name + ".png",
			                        "png");
			try
			{
				Texture2D SDF = CreateSDF();
				bool refresh = File.Exists(outputPath);
				File.WriteAllBytes(outputPath, ImageConversion.EncodeToPNG(SDF));
				if (refresh)
				{
					AssetDatabase.Refresh();
				}
				else
				{
					AssetDatabase.ImportAsset(outputPath);
				}
			}
			catch (UnityException exception)
			{
				ShowNotification(new GUIContent(exception.ToString()));
				Debug.LogError(exception.ToString());
			}
		}
	}
}
