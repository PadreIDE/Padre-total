#version unofficial megapov 1.21;
#include "cm_planets.inc";

#declare RockyColour = array[8] {
    CM_Martian
    CM_Bland_Jovian
    CM_Europa
    CM_Grey
    CM_Venus
    CM_Europa
    CM_earthy2_120_80
    CM_Grey
};

#declare RockyPattern = array[4] {
    pigment { granite scale 2 cubic_wave }
    pigment { agate scale 4 agate_turb 2 }
    pigment { wrinkles }
    pigment { crackle cubic_wave turbulence 1 scale 3 }
    
};

#declare RockyNormal = array[4] {
    normal { granite scale 2 scallop_wave }
    normal { agate scale 4 agate_turb 2 }
    normal { wrinkles }
    normal { crackle }
};

#declare GasColour = array[8] {
    CM_dusty_0_255
    CM_Earthy
    CM_Jovian
    CM_neptune2_0_255
    CM_Saturn
    CM_Jupiter2
    CM_Europa
    CM_Venus
};

#declare P_GasGiant = pigment { gradient y }

#macro Rocky(has_colour,has_pattern,GalX,GalY,Modifier1,Modifier2)
    texture {
        pigment {
            RockyPattern[has_pattern]
            turbulence 2*((1+Modifier1)/2)
            pigment_map {
                [ 0      RockyPattern[has_pattern]
                        translate <GalX,GalY,0>
                        scale 10
                        color_map { RockyColour[has_colour] }
                ]
                [ 1
                        RockyPattern[has_pattern]
                        translate <GalX,GalY,0>*-1
                        color_map { RockyColour[has_colour] } 
                        frequency 0.5
                        phase 0.5 
                ]
            }            
            scale 70 
            warp { turbulence 0.3 + Modifier2/3 }
            scale 1/70
        }
        finish { ambient 1 }
        /*
        normal {
            RockyNormal[has_pattern]
            translate <GalX,GalY,0>
            
            normal_map {
                [0 bumps .3 scale 0.1 turbulence 0.1 ]
                [1 wrinkles .3 scale 0.05 turbulence 0.03 ]
            }
        }
        */
    }

#end


#macro Gas(has_colour,has_pattern,GalX,GalY,Modifier1,Modifier2)

#local FM1_Rotate = (Modifier1-0.5) * 60;
#local FM2_Rotate = (Modifier2-0.5) * 60;
#local V_storm_eye = <0,0,1>;
#local V_storm_eye_perturbed = vrotate(
    vrotate( V_storm_eye , <FM2_Rotate, 0, 0> ) ,
    <0,FM1_Rotate,0>
);
#local S_storm_eye = <0.2,0.1,0.1>;

    texture {
        pigment {
            average
            turbulence 0.05
            omega 0.1
            pigment_map {
                [ P_GasGiant colour_map { GasColour[has_colour] } 
                    frequency 1 * Modifier1 * Modifier2
                    phase 0.25+Modifier1 ]
                [ P_GasGiant colour_map { GasColour[has_colour] } frequency 0.1 phase 0.5 ]
                [ P_GasGiant colour_map { GasColour[has_colour] } frequency 0.3 phase 0.85+Modifier2 ]
            }

            scale 1/10
            warp {
                turbulence 0.01
            }
            scale 10
            
            warp {
                displace {
                    spherical  scale S_storm_eye*3 translate <0,1,0>
                    cubic_wave
                    pigment_map { 
                        
                        [0 color rgb 0.5]
                        [1 spiral1 3  phase 0.75
                            cubic_wave
                            color_map{
                                [0 color rgb 0.5 ]
                                [0.5 color rgb 0.4]
                                [1 color rgb 0.5]
                            }
                        ]
                    }
                    rotate x*90
                    translate V_storm_eye_perturbed - V_storm_eye
                    type 1
                    
                }
            }
            
          
            warp {
                displace {
                    spherical  scale S_storm_eye*2 translate <0,1,0>
                    cubic_wave
                    pigment_map { 
                        
                        [0 color rgb 0.5]
                        [1 spiral1 4  phase 0.33
                            cubic_wave
                            color_map{
                                [0 color rgb 0.5 ]
                                [0.5 color rgb 0.4]
                                [1 color rgb 0.5]
                            }
                        ]
                    }
                    rotate x*90
                    translate V_storm_eye_perturbed-V_storm_eye
                    type 1
                    
                }
            }
            
            scale y*2
            warp {
                black_hole V_storm_eye_perturbed  vlength( S_storm_eye )*2
                inverse
                strength 1.5
                falloff 1
                
            } 
            scale y*1/2  
          
            translate <GalX,GalY,0>
            scale 20
            warp{
                turbulence 0.15
                omega 0.2
                octaves 8 lambda 2.4
            }
            scale 1/20
            translate -<GalX,GalY,0> 
            
        }
        finish { ambient 1 }
        
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