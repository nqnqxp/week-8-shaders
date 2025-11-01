float hash21(float2 v){
    return frac(23425.32 * sin(v.x*542.02 + v.y * 456.834));
}

float noise21(float2 uv){
  
    float2 scaleUV = floor(uv);
    float2 unitUV = frac(uv);
  
    float2 noiseUV = scaleUV;
  
    float value1 = hash21(noiseUV);
    float value2 = hash21(noiseUV + float2(1.,0.));
    float value3 = hash21(noiseUV + float2(0.,1.));
    float value4 = hash21(noiseUV + float2(1.,1.));
  
    unitUV = smoothstep(float2(0,0),float2(1,1),unitUV);
  
    float bresult = lerp(value1,value2,unitUV.x);
    float tresult = lerp(value3,value4,unitUV.x);
  
    return lerp(bresult,tresult,unitUV.y);
}

float fBM(float2 uv){
    float result = 0.;
    for(int i = 0; i <  8; i++){
        result = result + (noise21(uv * pow(2.,float(i))) / pow(2.,float(i)+1.));
    }
  
    return result;
}
