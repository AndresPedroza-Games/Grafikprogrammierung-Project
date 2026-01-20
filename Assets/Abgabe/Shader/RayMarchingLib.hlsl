//StandardShapeSDFs

float sdf_Sphere(float3 p, float r)
{
    return length(p) - r;
}

//based on https://iquilezles.org/articles/distfunctions/
float sdEllipsoid( float3 p, float3 c, float3 r )
{
    p = p-c;
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

//based on https://iquilezles.org/articles/distfunctions/
float sdOctahedron( float3 p, float s )
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  float3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(float3(q.x,q.y-s+k,q.z-k)); 
}

//based on https://iquilezles.org/articles/distfunctions/
float sdf_Box( float3 p, float3 b )
{
    float3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//based on https://iquilezles.org/articles/distfunctions/
float sdf_Cylinder( float3 p, float h, float r )
{
  float2 d = abs(float2(length(p.xz),p.y)) - float2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdf_CylinderHorizontal( float3 p, float h, float r )
{
  float2 d = abs(float2(length(p.xy),p.z)) - float2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdf_CylinderHorizontalZ( float3 p, float h, float r )
{
  float2 d = abs(float2(length(p.yz),p.x)) - float2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdf_Cone( float3 p, float h, float r1, float r2 )
{
  float2 q = float2( length(p.xz), p.y );
  float2 k1 = float2(r2,h);
  float2 k2 = float2(r2-r1,2.0*h);
  float2 ca = float2(q.x-min(q.x,(q.y<0.0)?r1:r2), abs(q.y)-h);
  float2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot(k2, k2), 0.0, 1.0 );
  float s = (cb.x<0.0 && ca.y<0.0) ? -1.0 : 1.0;
  return s*sqrt( min(dot(ca, ca),dot(cb, cb)) );
}

//Transformation

float3 inverseTranslate(float3 p, float3 t)
{
    return p - t;
}

float3 inverseRotate(float3 p, float3x3 r)
{
    return mul(transpose(r), p);
}

float3 inverseScale(float3 p, float s)
{
    return p / s;
}

//CSG

float2 cm(float2 a, float2 b)
{
    return (a.x < b.x) ? a : b; 
}
float sdfUnion(float a, float b)
{
	return min(a, b);
}
float sdfIntersection(float a, float b)
{
	return max(a, b);
}
float sdfSubtraction(float a, float b)
{
	return max(a, -b);
}

//based on https://iquilezles.org/articles/distfunctions/
float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h);
}
//based on https://iquilezles.org/articles/distfunctions/
float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h);
}
//based on https://iquilezles.org/articles/distfunctions/
float opSmoothIntersection( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h);
}

//Repeatition 

//based on https://iquilezles.org/articles/sdfrepetition/
float3 repeatX(float3 p, float s)
{
    p.x = p.x - s*round(p.x / s);
    return p;
}

float3 repeatXY(float3 p, float s)
{
    p.xy = p.xy - s*round(p.xy / s);
    return p;
}

float3 repeatXZ(float3 p, float s)
{
    p.xz = p.xz - s*round(p.xz / s);
    return p;
}