#version unofficial megapov 1.21;
#include "cm_planets.inc";
#include "cm_continental.inc";


#declare Vegetation_Colours = array[8] {
    CM_Grass1
    CM_Grass2
    
    CM_Jungle1
    CM_Jungle2
    CM_Jungle3
    
    CM_Grass2
    CM_Jungle2
    CM_Jungle1
    
};

#declare Land_Colours = array[8] {
    CM_Desert1
    CM_Desert1
    CM_Desert3
    CM_Mountain1

    CM_Desert1
    CM_Desert3
    CM_Desert3
    CM_Mountain1

};

#declare Ocean_Colours = array[8] {
    CM_Aqua1
    CM_Ocean1
    CM_Aqua1
    CM_Ocean2
    CM_Ocean3
    CM_Ocean1
    CM_Ocean3
    CM_Ocean2
};

#declare P_Continents = pigment {
    bozo
    turbulence 1
    lambda 4
    //omega 1.8
    /*scale 5 */
};

#declare P_Continents2 = pigment {
    wrinkles
    turbulence 0.5
    lambda 4
}

#declare P_Continents3 = pigment {
    dents turbulence 1.5 scale 0.8 phase 0.25
    lambda 4
    
}

#declare P_Continents4 = pigment {
    dents turbulence 1.5 scale 0.8 phase 0.75 scallop_wave
    lambda 4
    
}


#declare Continents_Pattern = array[8] {
    P_Continents
    P_Continents2
    
    P_Continents3
    P_Continents4
    P_Continents
    P_Continents2
    P_Continents3
    P_Continents4
}


#macro Clouds()
// Clouds
    texture {
        pigment {
            average
            pigment_map {
                [   wrinkles
                    turbulence 0.35 scale <0.34,0.1,0.34>
                    colour_map {
                        [0.5 rgbf 1]
                        [0.85 rgb 1 filter 0 ]
                    }
                ]
                [   bozo translate 1000 
                turbulence 0.7 lambda 4 
                    scale <0.5,0.12,0.5>
                    colour_map {
                        [0.5 rgbf 1]
                        [0.85 rgb 1 filter 0]
                    }
                ]
            }
                
            /*
            warp {
                displace {
                    marble 
                    rotate z*90
                    turbulence 0.3 scale 1 cubic_wave
                    colour_map { [0 rgb 0.5 ] [1 rgb 1 ] }
                    type 1
                }
            }
            */
            
            warp {
                displace {
                    average
                    pigment_map {
                            [ spiral1 1  scale 2 rotate x*90 rotate y*90 colour_map { [0 rgb 0.5] [1 rgb 0 ] } ]
                            //[ radial triangle_wave ]
                    }
                    type 1
                    
                }
            }
            //*/
        }
        finish { ambient 1 }
    }


#end



#macro Continental(has_colour,has_pattern,galx,galy,f_mod1,f_mod2)

#local MyPattern = Continents_Pattern[has_pattern];
#local MyOcean   = Ocean_Colours[has_colour];
#local MyVegetation = Vegetation_Colours[has_colour];
#local MyTerrain = Land_Colours[has_pattern]; // not the colour modifier ?!?

#local MyGalOffset = <galx,galy,0>;
#local MySpin =  <360*f_mod1,0,180*f_mod2>;

#local T_MyLand =     // Land mass
    texture {
        gradient y scale 2 triangle_wave
        texture_map {
            [ 0.6 
                pigment {
                    MyPattern
                    lambda 2.8
                    rotate MySpin translate MyGalOffset 
                    pigment_map {
                        [ 0.2 rgbt 1  ]
                        [ 0.2 wrinkles scale 0.25 colour_map { MyVegetation }  ]
                    }
                }
                finish { ambient 1 }
            ]
            [ 0.8 
                pigment {
                    MyPattern
                    lambda 3.2
                    rotate MySpin translate MyGalOffset 
                    pigment_map {
                       [ 0.2 rgbt 1 ]
                       [ 0.2 wrinkles scale 0.3 colour_map { MyTerrain } ]
                    }
                }
                finish { ambient 1 }
            ]
            [ 0.9
                //Mountains
                pigment {
                    MyPattern
                    lambda 3.5
                    pigment_map {
                        [ 0.4  rgbt 1]
                        [ 0.4  wrinkles colour_map { CM_Mountain1 } ]
                        [ 0.675 wrinkles colour_map { CM_Mountain1 } ]
                        [ 0.8 color rgb <1,1,1> ]
                    }
                }
                finish { ambient 1 }
            ]
        }
        
    };

#local T_MyOceans = 
    texture {
        pigment {
            MyPattern phase 0  frequency 0.5
            rotate MySpin translate MyGalOffset 
            colour_map { MyOcean }
            /*pigment_map {
                [0.6 wrinkles scale 1 colour_map { CM_Ocean1 } ]
                [0.9 wrinkles scale 1 colour_map { CM_Aqua1 } ]
            }*/
            
        }
        finish { ambient 1 }
    };

        
    //
    texture {
        pigment {
            MyPattern
            rotate MySpin translate MyGalOffset 
            lambda 3
            pigment_map {
                [ 0.5  MyPattern
                        rotate MySpin translate MyGalOffset 
                        lambda 2
                        colour_map { MyOcean }
                ]
                [ 0.5 
                    gradient y scale 2 triangle_wave  
                    //turbulence 0.1 lambda 2
                    // rotate -MySpin translate -MyGalOffset 
                    pigment_map {
                        [0.6 dents scale 0.3 scallop_wave  colour_map { MyVegetation } ]
                        [0.8 wrinkles scale 0.3 colour_map { MyTerrain } ]
                     
                    }
                ]
            }
            
            
        }
        
        //
        finish { ambient 1 }
    }
    //
    

    
    ///*
    // IceCaps
    texture {
        pigment {
            gradient y scale 1.8+(f_mod2/2) triangle_wave
            colour_map {
                [0.8 rgbf 1]
                [0.8 rgbf <0.925,0.975,1,0.15> ]
                [1 rgbf <0.975,1,1,0.025> ]
            }
            warp {
                displace {
                    MyPattern lambda 4 turbulence 2+f_mod1
                    rotate MySpin translate MyGalOffset 
                    colour_map { [0 rgb 0.25 ][1 rgb 0.75]}
                    type 1
                }
            }
        }
        finish { ambient 1 }
    }
    //*/
    
        
    
    
#end
