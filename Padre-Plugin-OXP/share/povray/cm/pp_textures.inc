#version unofficial megapov 1.21;
#include "cm_planets.inc";

#declare RockyColour = array[4] {
    CM_Martian,
    CM_Grey,
    CM_Martian,
    CM_Grey
};

#declare GasColour = array[4] {
    CM_Abilene
    CM_Dusty
    CM_Earthy
    CM_Abilene
};

#declare P_GasGiant = pigment { gradient y }

#macro Rocky(has_colour,has_pattern)
    texture {
        
    }

#end


#macro Gas(has_colour,has_pattern)
    texture {
        pigment {
            average
            turbulence 0.05
            omega 0.1
            pigment_map {
                [ P_GasGiant colour_map { GasColour[has_colour] } frequency 0.2 phase 0.25 ]
                [ P_GasGiant colour_map { GasColour[has_colour] } frequency 0.1 phase 0.5 ]
                [ P_GasGiant colour_map { GasColour[has_colour] } frequency 0.3 phase 0.85 ]
            }
            scale 80
            warp{
                turbulence 0.5
                omega 0.2
            }
            scale 1/80
        }
        finish { ambient 0.15 }
        
    }

#end


#macro Continents(has_colour,has_pattern)
    
    
    texture {
        
        
    }
        
        
#end

/* continents
sphere { <0,0,0> Radius
    texture {
        pigment {
            granite scale 3
            color_map { CM_Dusty }
            frequency 0.02
            phase 0.1
            warp { 
                displace {
                        magnet 2 mandel 200
                        interior 1,1
                        scale 0.5
                        rotate y*30
                        turbulence 0.35
                    type 1
                }
            }
        }
        finish { ambient.5 }
    }
    
    texture {
        pigment { 
            magnet 1
            mandel 600
            interior 3,1
            scale .5
            rotate y * 30
            turbulence 0.5
            color_map {
                [0.01 color rgb <0.1,0.2,0.3> ]
                [0.02 color rgb <0.5,.9,.9> ]
                [0.02 color rgbt <0.5,0.9,0.9,1>] 
            }
            frequency 1
        }
        finish { ambient 0.5 }
        
    }

}




/// blue marble with clouds
sphere { <0,0,0> 1
    no_shadow
    inverse
    double_illuminate
    texture {
    pigment  {
        granite scale 3
        pigment_map {
            [ 0.5 
                average
                    pigment_map {
                        [ 
                                wrinkles
                                turbulence <5,1,5>
                                color_map { CM_Earthy }
                                frequency 0.25
                        ]
                        [       ripples
                                turbulence <5,2,5>
                                color_map { CM_Greeny }
                        ]
                    }
                    warp { displace { marble scale 21 frequency 2 turbulence 0.3} }
                    scale 3
                    warp { turbulence 1 }
                    scale 20
                    warp { turbulence 1 }
                    scale 1/20                
            ]
            [ 0.51 P_Ocean ]
        }
    }
}     

texture {
    pigment { wrinkles scale .05 turbulence 1
        warp { turbulence 1 }
        scale 20
        color_map { [0 rgbf <1,1,1,0.6>]
                    [0.2 rgbf <.99,.99,1,0.6>]
                    [0.4 rgbf <.99,.99,1,1>]
                    [0.6 rgbf 1]
                }
        warp { displace { radial rotate x*90 type 1 }  }
 } 
 finish { ambient 1 }
}
    
     
}
///

*/