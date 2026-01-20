       
            float Planets(float3 pos){

                float dPlanet1 = sdf_Sphere(pos - float3(-40,13,0),25);

                float dPlanet2 = sdf_Sphere(pos - float3(30,-70,0),60);

                float result = sdfUnion(dPlanet1,dPlanet2);

                return result;

            }

            float Asteroids(float3 pos){

                float3 absPos = abs(pos);

                float dAsteroid= sdEllipsoid(absPos + float3(-10,0,-22),float3(0,0,0),float3(2.5,2,3));

                float holes = sdf_Sphere(absPos + float3(-8,-2,-22),2);

                dAsteroid = sdfSubtraction(dAsteroid,holes);

                float holes1 = sdf_Sphere(absPos + float3(-10,1,-25),0.7);

                dAsteroid = sdfSubtraction(dAsteroid,holes1);

                float holes2 = sdf_Sphere(absPos + float3(-10,-1.2,-24),0.7);

                dAsteroid = sdfSubtraction(dAsteroid,holes2);

                return dAsteroid;
            }

            float Stars(float3 pos){

                float3 position = repeatXY(pos,32);
                
                float star = sdOctahedron(position,0.5);

                return star;
            }

    