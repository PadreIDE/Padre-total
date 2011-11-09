#include "cm_planets.inc"

camera {
    spherical 
    angle 360
    location <0,0,0>
    
}



#declare P_Crater =
    pigment {
        leopard
        colour_map { [0 rgb 1 transmit 1 ] 
                     [0.9 rgb 1 transmit 1 ] 
                     [ 0.925 rgb 1 transmit 0.5 ]
                     [0.935 rgb 0 transmit  0.5]
                     [1 rgb 0 transmit 0.5 ] }
        scale 0.1
        
        warp {
            turbulence 0.05
        }
        /*
        turbulence <0.3,0.1,0.3>*0.1
        octaves 8
        sine_wave
        */
        
        scale 50
    }
    
#declare P_Crackle =
    pigment {
        crackle
        scale 15
        turbulence 2
        color_map { [ 0 rgb 1 transmit 1] [0.15 rgb 1 transmit 1] [1 rgb 1 transmit 0] }
        
    }

#default { finish {ambient 1}}
global_settings {
    ambient_light 1
}

sphere {
    <0,0,0> 100
    hollow
    material {
        texture {
            pigment { color rgb 0.5 }
        }
        texture { 
            pigment { average
                pigment_map {
                    [P_Crackle ]
                    [P_Crackle turbulence 1 translate 500]
                    [P_Crackle turbulence 1.3 translate 1500 scale 3]
                   
                }
            }
        
        }
        texture { pigment { P_Crater } }
        texture { pigment { P_Crater translate y*100 scale 5 } }
        texture { pigment { P_Crater translate z*100 scale 5 frequency 0.25 phase 0.75 } }
        
    }
    
}
