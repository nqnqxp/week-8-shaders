using UnityEngine;

public class cutOutController : MonoBehaviour
{
    public Material cutOutMaterial;
    public GameObject cutter;
    public float cutOutRadius = 1f;

    void Update()
    {
        if(cutter != null && cutOutMaterial != null)
        {
            cutOutMaterial.SetVector("_CutOutLocation", cutter.transform.position);
            cutOutMaterial.SetFloat("_CutOutRadius", cutOutRadius);
        }
    }
}
