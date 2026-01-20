using UnityEngine;
using System.Collections;

public class RayMarchingCamera : MonoBehaviour
{
    [SerializeField] private Material material;

    [Space(5)]
    [SerializeField] private float movementSpeedX;
    [SerializeField] private float movementSpeedY;
    [SerializeField] private float movementSpeedZ;
    [SerializeField] private float movementSpeedAsteroids;
    [SerializeField] private float movementSpeedCamera;

    private float movementEffectX;
    private float movementEffectJump;
    private float movementEffectZ;
    private float movementEffectAsteroids = -40;

    private float dissolve = 1;
    public float dissolveSpeed = 0.5f;
    private bool canDisolve;

    private void Update()
    {
        material.SetFloat("_AnimationBaseX", movementEffectX);
        material.SetFloat("_AnimationJump",movementEffectJump);
        material.SetFloat("_AnimationZ", movementEffectZ);
        material.SetFloat("_AnimationAsteroids", movementEffectAsteroids);

        movementEffectX = Mathf.PingPong(Time.time * movementSpeedX, 2f) - 1;
        movementEffectJump = Mathf.PingPong(Time.time * movementSpeedY, 2f) - 1;
        movementEffectAsteroids += (0.5f * Time.deltaTime * movementSpeedAsteroids);
        movementEffectZ += (0.1f * Time.deltaTime * movementSpeedZ);

        if(movementEffectZ > 21f)
        {
            movementEffectZ = 0;
        }

        if(movementEffectAsteroids > 44)
        {
            movementEffectAsteroids = -40;
        }

        transform.position = new Vector3(movementEffectX * movementSpeedCamera, transform.position.y, transform.position.z - (0.01f * Time.deltaTime * movementSpeedCamera));

        //if (canDisolve)
        //{
        //   dissolve -= Time.deltaTime * dissolveSpeed;
        //   material.SetFloat("_Clip", dissolve);
        //}

        //if (material.GetFloat("_Clip") <= 0)
        //   StartCoroutine(RestoreSkin());

        //if (Input.GetKeyDown(KeyCode.Space))
        //   canDisolve = true;

    }

    private IEnumerator RestoreSkin()
    {
        yield return new WaitForSeconds(2f);
        material.SetFloat("_Clip", 1);
        canDisolve = false;
        dissolve = 0;
    }
}
