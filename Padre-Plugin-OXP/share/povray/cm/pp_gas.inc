#version unofficial megapov 1.21;
#include "cm_planets.inc";


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

#declare P_GasBanded = pigment {
    gradient y 
    
}

#declare P_GasStrata = pigment {
    onion
    scale 2
    lambda 3
    turbulence 0.05
    sine_wave
}

#declare GasPattern = array[8] {
    P_GasBanded
    P_GasStrata
    P_GasBanded
    P_GasStrata
    P_GasBanded
    P_GasBanded
    P_GasBanded
    P_GasStrata
}

#macro Warp_Storm(mod1,mod2,pos)

#end

#macro Warp_Bloom(mod1,mod2,pos)
warp {
    displace {
        spherical
        cubic_wave
        scale 0.2
        colour_map {
            [0 color rgb .75]
            [1 color rgb 0.5]
        }
        translate pos
        scale 1.05
        type 1    
    }
}

#end

#macro Gas(has_colour,has_pattern,GalX,GalY,Modifier1,Modifier2)

#local FM1_Rotate = (Modifier1-0.5) * 120;
#local FM2_Rotate = (Modifier2-0.5) * 120;
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
                [ GasPattern[has_pattern] colour_map { GasColour[has_colour] } 
                    frequency 1 * Modifier1 * Modifier2
                    phase 0.25+Modifier1 ]
                [ GasPattern[has_pattern] colour_map { GasColour[has_colour] } frequency 0.1 phase 0.5 ]
                [ GasPattern[has_pattern]  colour_map { GasColour[has_colour] } frequency 0.3 phase 0.85+Modifier2 ]
            }
            
            Warp_Bloom( 1,1, vrotate( V_storm_eye , <0,FM2_Rotate,0> ) )

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
                        [1 spiral1 2  phase 0.33
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
            
            /*
            scale y*2
            warp {
                black_hole V_storm_eye_perturbed  vlength( S_storm_eye )*2
                inverse
                strength 1.5
                falloff 1
                
            } 
            scale y*1/2  
          */
            scale y*2
            Warp_Bloom(1,1,V_storm_eye_perturbed * <1,2,1> )
            scale y*1/2
            
           /* warp {
                displace {
                    spherical scale S_storm_eye*2 cubic_wave
                    translate V_storm_eye_perturbed
                    color_map { [0 color rgb 0] [1 color rgb 0.5] }
                    type 1
                }
                
            }
          */
          
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
