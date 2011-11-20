#version unofficial MegaPov 1.21;
#include "pprocess.inc"
#include "cm_planets.inc"
#include "cm_camera.inc"

#declare Radius = 1;

sphere { <0,0,0> Radius
    texture {
        pigment {
            granite scale 3
            color_map { CM_Dusty }
            frequency 0.02
            phase 0.1

        }
        finish { ambient.5 }
    }
    
    texture {
        pigment { 
            
            magnet 1
            mandel 20
            interior 0,2
            scale 0.34     
            rotate y * 45
            turbulence 0.5
            /*
            color_map {
                [0.01 color rgb <0.1,0.2,0.3> ]
                [0.02 color rgb <0.5,.9,.9> ]
                [0.02 color rgbt <0.5,0.9,0.9,1>] 
            }
            */
            frequency 1
        }
        finish { ambient 0.5 }
        
    }

}


///*
light_source { <0,2,4> color rgb 1 }
camera {
    perspective 
    location <2,0.1,2>
    look_at <0,0,0>
    up <0,1,0>
    right <1,0,0>
    
}


// latlong camera (inside sphere)
camera { spherical angle 360 location <0,0,0> }

//*/

/*
CubeMapBoxes(Radius)
CubeLight(4,Radius)
CubeMapCamera()
*/

