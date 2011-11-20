#version unofficial megapov 1.21
#include "cm_camera.inc"

#declare Radius = 1;

#version unofficial megapov 1.21;
#include "pl_pigments.inc"
#include "cm_planets.inc"

/*
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
                warp {
                displace {
                    radial frequency 10
                type 0 
            }
            }
            }
        
        }
    }
    scale 1/100
}
*/

/*
sphere {
    <0,0,0> 100
    hollow
    material {
        texture {
            finish { ambient 1 }
            pigment { average
                pigment_map {
                    [ 2 P_Banded frequency 0.085 colour_map { CM_Dusty}]
                    [ P_Banded phase 0.4 frequency 0.026  colour_map { CM_Dusty }]
                    [ P_Banded phase 0.55 frequency 0.016 colour_map { CM_Abilene }  ]
                    [ P_Banded frequency 0.08 phase 0.333 warp { turbulence 0.5  } color_map { CM_Earthy } ]                    
                }
                scale 1/10
                
                warp {
                displace {
                    dents 
                    type 1 
                }
                }
                scale 10
                translate 50
                warp { displace { radial rotate x*15 rotate z*5 } }
            }
        
        }
    }
    scale 1/100
}
*/

/*
sphere {
    <0,0,0> Radius
    texture { pigment { color rgb 1 filter 0} finish { ambient 1 } }
    texture {
        pigment { gradient y
            frequency 15
            //phase 0.025
            triangle_wave
            color_map {
                [0 rgbt <1,0,0,1>]
                [0.95 rgbt <1,0,0,1> ]
                [1 rgbt <1,0,0,0> ]
            }
        }
            finish { ambient 1 }
        }
    texture {
        pigment { radial 
            color_map {
                [0 rgbt <0,1,0,1> ]
                [0.95 rgbt <0,1,0,1> ]
                [1 rgbt <0,1,0,0>  ]
            }
            frequency 36
        }
            finish { ambient 1 }
        }
    hollow
    no_shadow
}
*/


#declare CubeSide = sqrt( 1/3 ) * (Radius*2);
/*
box { 0 , CubeSide
    translate -1 * CubeSide/2
    texture { pigment { rgb <0,0,1> } finish { ambient 1 } }
}
*/

/* Registration boxes
sphere { <-CubeSide,CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <1,0,0> } finish { ambient 1 } }
}
sphere { <-CubeSide,CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <0,1,0> } finish { ambient 1 } }
    rotate y * 90
}
sphere { <-CubeSide,CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <0,0,1> } finish { ambient 1 } }
    rotate y * 180
}
sphere { <-CubeSide,CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <0,0,0> } finish { ambient 1 } }
    rotate y * 270
}

sphere { <-CubeSide,-CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <1,1,0> } finish { ambient 1 } }
}
sphere { <-CubeSide,-CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <0,1,1> } finish { ambient 1 } }
    rotate y * 90
}
sphere { <-CubeSide,-CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <1,0,1> } finish { ambient 1 } }
    rotate y * 180
}
sphere { <-CubeSide,-CubeSide,-CubeSide>/2 0.02
    texture { pigment { rgb <0.5,0.5,0.5> } finish { ambient 1 } }
    rotate y * 270
}
*/

///*
sphere { <0,0,0> 1
    texture {
        pigment { average
            pigment_map {
                [ 
                        wrinkles
                        turbulence <5,1,5>
                        color_map { CM_Martian }
                ]
                [       ripples
                        turbulence <5,2,5>
                        color_map { CM_Martian }
                ]
            }
            scale 3
            warp { turbulence 1 }
            scale 20
            warp { turbulence 1 }
            scale 1/20
        }
        finish { ambient .5  crand 0.01}
        normal {   crackle         
                    turbulence <5,1,5>
                    scale 3
            normal_map {
            [ 0 crackle -0.52 scale 0.01 ]
            [ 1 bumps -0.3 scale 0.04 ]
            }
            warp { turbulence .5 }
        }
    }
    texture {
        pigment { gradient y triangle_wave scale 2.15
            color_map {
                [0 rgbf 1]
                [0.9 rgbf 1]
                [0.921 rgb <1,1,1> filter .15 ]
                [1 rgb <1,1,1> filter 0 ]
            }
            turbulence 0.3
            scale 100
            warp { turbulence 1 }
            scale 1/100
        }

        finish { ambient 0.5 }
    }
    no_shadow
    inverse
    double_illuminate
}
//*/


/*
light_source { <0,2,4> color rgb 1 }
light_source { <0,-2,-4> color rgb 1 }
camera {
    perspective 
    location <2,0.1,2>
    look_at <0,0,0>
    up <0,1,0>
    right <1,0,0>
    
}
*/

// latlong camera (inside sphere)
//camera { spherical angle 360 location <0,0,0> }

///*
CubeMapBoxes(Radius)
CubeLight(4,Radius)
CubeMapCamera()
//*/