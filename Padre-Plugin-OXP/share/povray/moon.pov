#include "cm_planets.inc"

camera {
    spherical 
    angle 360
    location <0,0,0>
    
}



#declare P_Crater =
    pigment {
        leopard
        colour_map { [0 rgb 0 transmit 0 ] [0.25 rgb 0.5 transmit 0 ] 
                     [ 0.4 rgb 1 transmit 0 ]
                     [0.5 rgb 0.5 transmit 1] }
        scale 0.1
        warp {
            turbulence 0.05
        }
        turbulence <0.3,0.1,0.3>*0.1
        octaves 8
        //sine_wave
        
        
        scale 150
    }
    
#declare P_Crackle =
    pigment {
        crackle
        scale 15
        turbulence 3
        
    }


sphere {
    <0,0,0> 100
    hollow
    material {
        texture {
            pigment { color rgb 0.5 }
            finish { ambient 1 }
        }
        texture {
            pigment { 
                average
                pigment_map { 
                    [ 1 P_Crater  ]
                    [ 1 P_Crater rotate <30,15,5> translate 400 scale 0.3 ]
                    [ 1 P_Crackle ]
                    
                }
            }
            finish { ambient 1 }
        }

            
    }
    
}
