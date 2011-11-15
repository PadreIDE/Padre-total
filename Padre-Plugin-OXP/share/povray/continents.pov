#version unofficial megapov 1.21
#include "cm_camera.inc"

#declare Radius = 1;

#include "pl_pigments.inc"
#include "cm_planets.inc"


sphere {
    <0,0,0> Radius
    hollow
    no_shadow
    material {
        
        texture {
            normal { wrinkles 3 scale 0.01 turbulence 1 }
            finish { ambient 0.5 }
            pigment { color rgb <0.1,0.2,0.5>  }
        }
    }
    scale 1/Radius

    texture {
        pigment { 
            bozo scale 0.3 turbulence 0.8
            color_map {
                [0 rgbt 1]
                [0.55 rgbt 1]
                [0.55 rgb <0.7,0.55,0.3>]
                
            }
        }
        finish { ambient .1 } 
        normal { wrinkles 3 scale 0.1 translate 100 } 
        
    }
    // polar caps
    texture {
        pigment { gradient y 
            translate -Radius/2  
            color_map {
                [0 rgb <1,1,1> ]
                [0.2 rgb <1,1,1> ]
                [0.2 rgbt 1 ]
                [0.84 rgbt 1]
                [0.84 rgb 1]
                
            }
            turbulence .1
            scale 20
            
            warp { turbulence 2 }
            scale 0.04
            scale 2.75
        }
        finish { ambient 1  }
        
    }
    scale 1/Radius
}

CubeMapBoxes(Radius)
CubeMapCamera()
/*
camera {
    perspective
    location <1,0.1,1>*2
    look_at <0,0,0>
    up <0,1,0>
    right <1,0,0>
}
*/

light_source { <5,5,5> color rgb 1 }