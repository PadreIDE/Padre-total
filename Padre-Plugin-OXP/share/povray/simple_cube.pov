// cube mapping of planet sphere texture
#version unofficial megapov 1.21;
#include "pl_pigments.inc"
#include "cm_planets.inc"


sphere {
    <0,0,0> 100
    hollow
    material {
        texture {
            finish { ambient 1 }
            pigment { average
                pigment_map {
                    [ 2 P_Banded frequency 0.1 ]
                    [ P_Banded phase 0.4 frequency 0.3  ]
                    [ P_Banded phase 0.55 frequency 0.6 colour_map { CM_Abilene }  ]
                    [ P_Banded phase 0.333 warp { turbulence 0.5  } color_map { CM_Dusty } ]                    
                }
            }
        }
    }
    
}


#macro CubeCamera(Face)
  //perspective 
  orthographic
  location <0,0,0>
  angle 45
  look_at <0,0,200>
  //right <1,0,0> up <0,1,0>
  // turn the cam based on the current frame=clock : [0-5]
  #switch (Face)
    #range (0,3)
      // first 4 frames : turn from left to right
      rotate (90*Face)*y
    #break
    #case (4)
      // look at the sky
      rotate -90*x
    #break
    #case (5)
      // look at the ground
      rotate 90*x
    #break
  #end // End of conditional part

#end


#macro PigmentCameraFace(Face)

    camera_view {
        CubeCamera(Face)
    }
#end


// Debug camera
/*
camera {
    perspective
    location <0,50,-200>
    angle 90
    look_at <0,0,0>
}
*/

// Box/Cube camera
 
camera { 
    orthographic
    location <0.5,1003 , -1>
    look_at  <0.5,1003 , 0>
    up <0,6,0>
    right <0,0,1>
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(0) }
        finish { ambient 1 } 
     }
     translate y*1000
     
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(1) } 
        finish { ambient 1 } 
    }
    translate y*1001
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(2) } 
        finish { ambient 1 } 
    }
    translate y*1002
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(3) } 
        finish { ambient 1 } 
    }
    translate y*1003
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(4) } 
        finish { ambient 1 } 
    }
    translate y*1004
}

box { <0,0,0> <1,1,1> 
    texture { 
        pigment { PigmentCameraFace(5) } 
        finish { ambient 1 } 
    }
    translate y*1005
}




