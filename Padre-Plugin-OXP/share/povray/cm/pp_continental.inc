#include "cm_planets.inc";
#include "cm_continental.inc";


#declare Vegetation_Colours = array[13] {
    CM_Grass1
    CM_Grass2
    
    CM_Jungle1
    CM_Jungle2
    CM_Jungle3
    CM_Jungle4 
    
    CM_Jungle5
    CM_Jungle6
    
    CM_Jungle7
    CM_Grass2
    
    CM_Jungle1
    CM_Jungle3
    
    CM_Jungle5
    
};

#declare Land_Colours = array[13] {
    CM_Desert1
    CM_Desert3
    CM_Desert4
    CM_Desert5
    CM_Desert6
    CM_Desert7
    CM_Desert8
    CM_Desert9
    CM_Desert10
    CM_Desert1
    CM_Desert2
    CM_Desert3
    CM_Desert5
    
   
};

#declare Ocean_Colours = array[13] {
    CM_Aqua1
    CM_Ocean1
    CM_Ocean2
    CM_Ocean3
    
    CM_Ocean4
    CM_Aqua2
    CM_Ocean3
    CM_Ocean4
    
    CM_Ocean5
    CM_Ocean6
    CM_Ocean7
    CM_Aqua2
    
    CM_Ocean2
    
};

#declare NormalDepth = 1;

#declare P_Continents = pigment {
    bozo
    turbulence 1
    lambda 4
};
#declare N_Continents = normal {
    bozo NormalDepth
    turbulence 1
    lambda 4
};

#declare P_Continents2 = pigment {
    wrinkles
    turbulence 0.5
    lambda 4
}
#declare N_Continents2 = normal {
    wrinkles NormalDepth
    turbulence 0.5
    lambda 4
}

#declare P_Continents3 = pigment {
    dents turbulence 1.5 scale 0.8 phase 0.25
    lambda 4
    
}

#declare N_Continents3 = normal {
    dents NormalDepth
    turbulence 1.5 scale 0.8 phase 0.25
    lambda 4
}


#declare P_Continents4 = pigment {
    dents turbulence 1.5 scale 0.8 phase 0.75 scallop_wave
    lambda 4
    
}

#declare N_Continents4 = normal {
    dents NormalDepth
    turbulence 1.5 scale 0.8 phase 0.75 scallop_wave
    lambda 4
    
}

#declare P_Continents5 = pigment {
    bozo
    turbulence 0.5
    lambda 5
    scale 3
};

#declare N_Continents5 = normal {
    bozo NormalDepth
    turbulence 0.5
    lambda 5
    scale 3
};

#declare P_Continents6 = pigment {
    wrinkles
    turbulence 0.5
    lambda 5
    scale 2
}
#declare N_Continents6 = normal {
    wrinkles NormalDepth
    turbulence 0.5
    lambda 5
    scale 2
}

#declare P_Continents7 = pigment {
    wrinkles
    turbulence 0.5
    lambda 5
    scale 4
}
#declare N_Continents7 = normal {
    wrinkles NormalDepth
    turbulence 0.5
    lambda 5
    scale 4
}



#declare P_Continents8 = pigment {
    dents turbulence 0.5 scale 1.8 phase 0.75 scallop_wave
    lambda 5
    
}
#declare N_Continents8 = normal {
    dents NormalDepth turbulence 0.5 scale 1.8 phase 0.75 scallop_wave
    lambda 5
    
}




#declare Continents_Pattern = array[8] {
    P_Continents
    P_Continents2
    
    P_Continents3
    P_Continents4
    P_Continents5
    P_Continents6
    P_Continents7
    P_Continents8
}

#declare Continents_Normal = array[8] {
    N_Continents
    N_Continents2
    
    N_Continents3
    N_Continents4
    N_Continents5
    N_Continents6
    N_Continents7
    N_Continents8
    
}


#declare Clouds1 = 
        pigment {
            average
            pigment_map {
                [   wrinkles
                    turbulence 0.35 scale <0.34,0.1,0.34>
                    lambda 4
                    colour_map {
                        [0.65 rgbf 1]
                        [0.85 rgb 1 filter 0 ]
                    }
                ]
                [   bozo translate 1000 
                turbulence 0.7 lambda 4 
                    scale <0.5,0.22,0.5> * 3
                    colour_map {
                        [0.65 rgbf 1]
                        [0.8 rgb .925 filter 0]
                    }
                ]
            }
        }


#declare Clouds2 = 
        pigment {
            average
            pigment_map {
                [   wrinkles
                    turbulence 0.35 scale <0.34,0.1,0.34>
                    lambda 4
                    colour_map {
                        [0.5 rgbf 1]
                        [0.8 rgb 1 filter 0 ]
                    }
                ]
                [   bozo translate 1000 
                turbulence 0.7 lambda 4 
                    scale <0.5,0.12,0.5>
                    colour_map {
                        [0.5 rgbf 1]
                        [0.8 rgb .85 filter 0]
                    }
                ]
            }
        }
  
#declare PF_Bozo =       
    function {
        pattern { bozo turbulence 0.5 lambda 4 } 
    }
#declare PF_Wrinkles =
    function {
        pattern { wrinkles turbulence 0.5 lambda 4 }
    }
    
#declare Clouds3 =
pigment {
    function {
        PF_Bozo(x,y,z) * PF_Wrinkles(x,y,z)
       
    }        
    colour_map {
    [0.4 rgbf 1]
    [0.45 rgb .85 filter .3]
    [0.7 rgb 1 filter 0]
    }
    scale 0.13
}

#declare Clouds2 =
pigment {
    function {
        PF_Bozo(x,y,z) * PF_Wrinkles(x,y,z)
       
    } 
    translate 1000       
    colour_map {
    [0.4 rgbf 1]
    [0.45 rgb 0.925 filter .6]
    [0.7 rgb 0.98 filter .2 ]
    }
    scale 0.23
    turbulence 1
}

#declare Clouds4 =
pigment {
    function {
        PF_Bozo(x,y,z) * PF_Wrinkles(x,y,z)
       
    } 
    translate 1000    
    cubic_wave   
    colour_map {
    [0.2 rgbf 1]
    [0.5 rgb .92 filter .6]
    [0.85 rgb .96 filter .2 ]
    }
    scale 2
    turbulence 1
    lambda 4
}

#declare Clouds5 = 
        pigment {
            average
            pigment_map {
                [   wrinkles
                    turbulence 0.35 scale <0.34,0.1,0.34>
                    lambda 2
                    cubic_wave
                    colour_map {
                        [0.35 rgbf 1]
                        [.9 rgb 1 filter 0.25 ]
                    }
                ]
                [   bozo translate 1000 
                turbulence 0.7 lambda 3 
                    cubic_wave
                    scale <0.5,0.12,0.5>
                    colour_map {
                        [0.35 rgbf 1]
                        [0.9 rgb .925 filter 0.25]
                    }
                ]
            }
        }
  



#declare Cloud_Patterns = array[8] {
        Clouds1
        Clouds2
        Clouds3
        Clouds4
        Clouds5
        Clouds3
        Clouds4
        Clouds5
    
}

#macro Clouds(CloudOffset,Cloud_pattern,fmod1,fmod2)
// Clouds
    texture {
        pigment  { 
            Cloud_Patterns[Cloud_pattern]
            translate CloudOffset
            scale 1+sqrt(fmod1+fmod2)
            
            warp {
                displace {
                    average
                    pigment_map {
                            [ spiral1 1  scale 2 rotate x*90 rotate y*90 colour_map { [0 rgb 0.5] [1 rgb 0 ] } ]
                            [ radial 
                                triangle_wave 
                                colour_map { [0 rgb 0.5] [1 rgb 0.75 ] }
                                rotate x*5 
                            ]
                    }
                    turbulence 0.4
                    type 1
                    
                }
            }
            //*/
        }

    }


#end



#macro Continental(Radius,has_colour,has_pattern,galx,galy,f_mod1,f_mod2)

#default {
  finish { ambient 0.3 diffuse 0.7 }
}

#local MyGalOffset = <galx,galy,0>;
#local MySpin =  <360*f_mod1,0,180*f_mod2>;

#local MyGradBlend = function {
    pigment {
        gradient y scale 2 triangle_wave
        scale 1/3
        warp { turbulence 0.35 } 
        scale 3
        
        scale 10
        warp { turbulence 0.8 lambda 3.5 }
        scale 1/10
        
        translate <galx,0,galy>
        
    }
}
#local MyPigFunc = function { pigment { Continents_Pattern[has_pattern]  
            rotate MySpin translate MyGalOffset }
};
#local MyPattern = pigment { function { MyPigFunc(x,y,z).gray } };
#local MyNormal = Continents_Normal[has_pattern];

#local MyOcean   = Ocean_Colours[has_colour];
#local MyVegetation = Vegetation_Colours[has_colour];
#local MyTerrain = Land_Colours[has_pattern]; // not the colour modifier ?!?

#local P_MyLand =     // Land mass
    pigment {
        function { MyGradBlend(x,y,z).gray }
        pigment_map {
            [ 0.5 
                
                    MyPattern
                    lambda 2.8
                    rotate MySpin translate MyGalOffset 
                    pigment_map {
                        [ 0.2 rgbt 1  ]
                        [ 0.2 wrinkles scale 0.02 colour_map { MyVegetation }  ]
                    }
                

            ]
            [ 0.55 
                
                    MyPattern
                    lambda 3.2
                    rotate MySpin translate MyGalOffset 
                    pigment_map {
                       [ 0.2 rgbt 1 ]
                       [ 0.2 wrinkles scale 0.05 colour_map { MyTerrain } ]
                   }
                
            ]
            [ 0.65 
                 MyPattern lambda 5 rotate MySpin translate MyGalOffset
                    pigment_map {
                        [0.2 rgbt 1]
                        [0.2 wrinkles scale 0.075 colour_map { MyTerrain } ]
                    }
                
            ]
            [ 0.9
                //Mountains
                
                    MyPattern
                    lambda 3.5
                    pigment_map {
                        [ 0.4  rgbt 1]
                        [ 0.4  wrinkles colour_map { CM_Mountain1 } ]
                        [ 0.675 wrinkles colour_map { CM_Mountain1 } ]
                        [ 0.8 color rgb <1,1,1> ]
                    }
                

            ]
        }
        
    };

#local T_MyOceans = 
    texture {
        pigment {
            MyPattern phase 0  frequency 1 triangle_wave
            rotate MySpin translate MyGalOffset 
            colour_map { MyOcean }
        }
    };

        
    //
    
sphere { <0,0,0> Radius hollow inverse no_shadow
    texture {
        pigment {
            MyPattern
            rotate MySpin translate MyGalOffset
            scale .99
            color_map { MyOcean }
        }
    }
}
    
sphere { <0,0,0> Radius-0.001 hollow inverse no_shadow
    texture {
        pigment {
            MyPattern

            lambda 3
            pigment_map {
                [ 0.5 rgbt 1 ]
                [ 0.5 
                   
                    
                    function { MyGradBlend(x,y,z).gray }
                    pigment_map {
                        [0.65 granite scale 3 turbulence 1 lambda 3 scallop_wave  colour_map { MyVegetation } ]
                        [0.875 wrinkles scale 0.3 colour_map { MyTerrain } ]
                     
                    }
                ]
            }
            
            
            
        }
        normal {
            MyNormal
            rotate MySpin translate MyGalOffset 
            lambda 3
            scale 0.96
            rotate z*1
            rotate y*f_mod2
            rotate x*f_mod1
            normal_map {
                [0.5 bumps 0 ]
                [0.5 granite .35 scale 0.3 ]
                [0.6 wrinkles .6 scallop_wave scale 0.1 ]
            }
        }
        

        
    }
    
    ///*
    // IceCaps
    texture {
        pigment {
            gradient y scale 2.05 triangle_wave
            rotate x * 2 * f_mod1
            
            #local Percent_Polar = 0.15 * (f_mod2+f_mod1) / 2;
            colour_map {
                [1 - Percent_Polar rgbf 1]
                [1 - Percent_Polar rgbf <0.925,0.975,1,0.15> ]
                [1 rgbf <0.975,1,1,0.025> ]
            }
            

            scale 1/3
            warp { turbulence <0.1,0.05,0.1> }
            scale 3

            scale 15
            warp {
                turbulence <0.5,0.5,0.5>
                lambda 3
            }
            scale 1/15
            
            
            //
            warp {
                displace {
                    MyPattern lambda 1.5 turbulence 1+f_mod1 * <1,0.1,1>
                    rotate MySpin translate MyGalOffset 
                    colour_map { [0.5 rgb 0.5 ][1 rgb 0.6]}
                    type 1
                }
            }
            //
            rotate <0,180*f_mod2,0>
        }

        normal { bumps 0.6 scale 0.014 }
    }
    //*/
}   
   
//
sphere { <0,0,0> Radius*0.96 hollow inverse 
    //
    Clouds( MyGalOffset, has_pattern, f_mod1,f_mod2 )

}     


sphere { <0,0,0> Radius*0.98 hollow inverse 
    Clouds( -MyGalOffset, mod(galx,8), f_mod2,f_mod1)
}
//
  
    
#end
