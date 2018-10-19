using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SetShaderAspect : MonoBehaviour
{
    public RawImage image;

    void Update()
    {
        if (image != null)
        image.material.SetFloat("_Aspect", image.rectTransform.rect.width / image.rectTransform.rect.height);
    }
}
