            #include "RayMarchingLib.hlsl" 
            #include "BGLib.hlsl" 

            float Head(float3 pos)      
            {
                float dHead = sdf_Sphere(pos - float3(0,3,0) ,2);

                float3 eyesPos = float3(abs(pos.x),pos.yz);

                float dHeadDetail1 = sdf_Sphere( eyesPos - float3(0.7,3.8,-1.6) , 0.2);

                dHead = sdfUnion(dHead,dHeadDetail1);

                return dHead;
            }

            float Body(float3 pos)
            {
                float dBody = sdf_Cylinder(pos - float3(0,1,0),2,2);

                float dBodyDetail1 = sdf_Box(pos + float3(0,-1,2),float3(1,0.6,0.03));

                dBody = sdfSubtraction(dBody,dBodyDetail1);

                float dBodyDetail2 = sdf_Box(pos + float3(0,0,2),float3(1,0.15,0.03));

                dBody = sdfSubtraction(dBody,dBodyDetail2);

                return dBody;
            }

            float BottomPart(float3 pos)
            {
                float dCone = sdf_Cone(pos + float3(0,1.4,0), 0.4, 1, 2);

                dCone = sdfUnion(dCone, Head(pos));

                return dCone;
            }
            
            float Arm(float3 pos)
            {
                float3 absPos = float3(abs(pos.x),pos.yz);

                float dArmConection = sdf_Sphere(absPos - float3(2,2,0),0.7);                

                float dArmCylin = sdf_CylinderHorizontal(absPos - float3(2.65, 2,0),1,0.7);

                float dArmCylin2 = sdf_CylinderHorizontal(absPos - float3(2.65, 2,-1),0.3,0.6);
                dArmCylin = opSmoothSubtraction(dArmCylin2,dArmCylin,0.1);

                float dArmExtension = sdf_Box(absPos - float3(2.59,-0.6,0), float3(0.3,1.5,0.35));

                float dArmExtensionDetail = sdf_Box(absPos - float3(2.59,-0.75,-0.4), float3(0.2,0.4,0.25));

                dArmExtension = sdfSubtraction(dArmExtension,dArmExtensionDetail);

                dArmCylin = opSmoothUnion(dArmCylin,dArmExtension,0.1);

                dArmConection = opSmoothUnion(dArmConection,dArmCylin,0.1);

                float dArmBase = sdf_Box(absPos - float3(2.59, 1.5 ,0), float3(0.4,0.8,0.4));
                
                float dArmBaseDecoration = sdf_Box(absPos - float3(2.59, 0 ,0), float3(0.36,0.1,0.4)) - 0.02;

                dArmBase = sdfUnion(dArmBase,dArmBaseDecoration);

                dArmConection = opSmoothUnion(dArmConection,dArmBase,0.18);

                return dArmConection;
            }

            float Foot(float3 pos)
            {
                float3 absPos = float3(abs(pos.x),pos.yz);

                float dFoot = sdf_Box(absPos - float3(2.59, -2, 0), float3(0.5,0.4,1)) - 0.05; 

                float dFoot4 = sdf_Box(absPos - float3(2.4, -2.5, 0), float3(0.7,0.1,1.5)) - 0.05;

                dFoot = opSmoothUnion(dFoot,dFoot4,0.2);

                float dFootBase = sdf_Box(absPos - float3(1.8, -1.96, 0), float3(0.2,0.4,0.5)) - 0.02;

                float dCylinBase = sdf_CylinderHorizontalZ(pos - float3(0, -2.1, 0),1.5,0.1);
                float dCylinBase1 = sdf_Cylinder(pos - float3(0, -1.8, 0),0.2,0.09);

                float dCylinCross = opSmoothUnion(dCylinBase,dCylinBase1,0.2);

                dFootBase = opSmoothUnion(dCylinCross,dFootBase,0.2);

                dFoot = sdfUnion(dFoot,dFootBase);

                return dFoot;
            }

            float Character(float3 pos, float animationJump)
            {
                pos.y += animationJump;

                float dSpaceHead = sdEllipsoid(pos - float3(0,2.1,0),float3(0,1,0),float3(3,0.5,2.2));

                float dCompleteBody = sdfUnion(Head(pos),Body(pos));

                dCompleteBody = sdfSubtraction(dCompleteBody,dSpaceHead);

                dCompleteBody = opSmoothUnion(dCompleteBody,BottomPart(pos),0.1);
                
                float dCompleteArm = opSmoothUnion(Arm(pos), Foot(pos),0.2);

                dCompleteBody = opSmoothUnion(dCompleteBody,dCompleteArm,0.18);

                return dCompleteBody;
            }

            float Base(float3 pos)
            {
                pos.y = abs(pos.y) - 1.7;

                float dFloor = sdf_Cylinder(pos - float3(0,2.5,0),0.2,6) - 0.2;

                float dFloor2 = sdf_Cylinder(pos - float3(0,2.4,0),0.19,5.8) - 0.2;

                dFloor = sdfSubtraction(dFloor,dFloor2);

                return dFloor;
            }

    