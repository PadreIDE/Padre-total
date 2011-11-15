#include "cm_planets.inc"

#declare P_RedSwirl = 
    pigment {
        bozo
        turbulence 1
        omega 0.4
        lambda 3
        color_map { CM_warmer_0_255 
        }
        scale 8
        warp {
            black_hole <50,20,90> 250
            falloff 2
            strength 2
            turbulence 3
            
            turbulence 0.3
            //octaves 6
            //omega 0.3
            
            
        }
        scale 10
    }


#declare P_Banded =
    pigment {
        gradient y
        colour_map { CM_Greeny }
        scale 0.1
        warp {
            turbulence 0.03
        }
        turbulence <0.3,0.1,0.3>*0.01
        octaves 8
        sine_wave
        phase 0.05
        scale 1250
        warp {
            black_hole <50,20,90> 150
            falloff 3
            strength 1.4
            inverse
            turbulence 0.3
            //octaves 6
            //omega 0.3
            
            
        }
    }

#declare P_Continent =
    pigment {
        wrinkles
        turbulence 0.02
        color_map { CM_Abilene }
        scale 50
    }