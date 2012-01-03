#version unofficial megapov 1.21;
#include "cm_planets.inc";


#declare GasColour = array[13] {
    CM_dusty_0_255
    CM_Jupiter3
    CM_Jovian
    CM_neptune2_0_255
    CM_Saturn
    CM_Jupiter2
    CM_Europa
    CM_Venus
    
    CM_Jupiter3
    CM_Neptune2
    CM_neptune2_0_255
    CM_Saturn
    CM_Jovian
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

#declare P_GasBanded2 = pigment {
    wood
    rotate x*90
    scale 3
    turbulence 0.005
    sine_wave
}

#declare GasPattern = array[8] {
    P_GasBanded
    P_GasStrata
    P_GasBanded2
    P_GasStrata
    P_GasBanded
    P_GasBanded2
    P_GasBanded
    P_GasStrata
}


#macro Warp_Storm(mod1,mod2,pos)

#end



#declare WF_Radial = function {
  pigment {
    radial  
  }
}

#declare WF_Spherical = function {
    pigment {
      spherical cubic_wave
      color_map {[0 rgb 0 ][ 0.75 rgb 1]}
    }
  }
#declare IWarp=0;
#macro M_StormWarp(RSeed,NWarps,Distance,Rescale)
      //#declare RSeed= seed(41748);
      //#declare NWarps = 35;
      #local IWarp = 0;
      #while (IWarp <= NWarps)
      
        #declare spotpos = vrotate(
                vrotate( <0,0,-Distance> , <rand(RSeed)*180,0,0> )
                <0,rand(RSeed)*360,0>
                );
      warp {
        displace {
          function { WF_Radial(x,y,z).gray * WF_Spherical(x,y,z).gray }
          color_map {[0 rgb 0 ][1 rgb 0.15]}
          scale <1,0.75,1>* (0.5+rand(RSeed))
          scale Rescale
          rotate y*rand(RSeed)*180
          rotate x*rand(RSeed)*180
          
          turbulence 0.15
          lambda 2.5
          octaves 10
          //sine_wave
          //translate <0,0,-1>
          //rotate <rand(RSeed)*100,rand(RSeed)*60,0>
          translate spotpos
        type 0
          }
      }
      warp {
        black_hole spotpos, 0.05
        strength -1
      }
      #local IWarp = IWarp+1;
      #end 
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


#declare TurbBand =
  //
  pigment { 
    
    gradient y frequency 0.95
    //translate -0.55
    scale 2
    cubic_wave
    scale 1/10
    warp { turbulence 0.01 lambda 3 octaves 4 }
    scale 10
    
    
    scale 4
    warp { turbulence <0,0.001,0> omega 2 }
    scale 1/4
    
    scale 8
    warp { turbulence <0.06,0.03,0.06> lambda 5 }
    scale 1/8
  }
  //

#declare LightBand = 
  pigment { 
    gradient y 
    frequency 0.95
    //translate -0.55
    scale 2
    cubic_wave
    scale 1/10
    warp { turbulence 0.01 lambda 3 octaves 4 }
    scale 10
  }
  

#declare Blended = function {
  pigment { gradient y frequency 16 sine_wave turbulence 0.03  }   
}
  



#macro Gas(Radius,has_colour,has_pattern,GalX,GalY,Modifier1,Modifier2)

#local FM1_Rotate = (Modifier1-0.5) * 120;
#local FM2_Rotate = (Modifier2-0.5) * 120;
#local V_storm_eye = <0,0,1>;
#local V_storm_eye_perturbed = vrotate(
    vrotate( V_storm_eye , <FM2_Rotate, 0, 0> ) ,
    <0,FM1_Rotate,0>
);
#local S_storm_eye = <0.2,0.1,0.1>;


#declare OldPig =        pigment {
            average
            turbulence 0.05
            omega 0.1
            pigment_map {
                [ GasPattern[has_pattern] colour_map { GasColour[has_colour] } 
                    frequency 1 * Modifier1 * Modifier2
                    phase 0.25+Modifier1 ]
                [ GasPattern[has_pattern] colour_map { GasColour[has_colour] } frequency 0.1 phase 0.5 ]
            }
            
            Warp_Bloom( 1,1, vrotate( V_storm_eye , <0,FM2_Rotate,0> ) )

            translate <GalX,GalY,0>
            scale 1/10
            warp {
                turbulence 0.01
            }
            scale 10
            translate -<GalX,GalY,0>            
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
            
            scale y*2
            Warp_Bloom(1,1,V_storm_eye_perturbed * <1,2,1> )
            scale y*1/2
          
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
 
#declare NewPig =
pigment {  
      /*
      function { BL_Sphere(x,y,z).gray }
      pigment_map {
         [0 spherical color_map { CM_Europa } phase 0.33  ]
         [0.05 spherical color_map { CM_Europa } phase 0.33 turbulence 1 ]
         [.1 onion sine_wave color_map { CM_Neptune } turbulence 2 octaves 10 ]  
      }
      */
      
       ///*  banded giant - jovian
      function {Blended(x,y,z).gray }
      pigment_map {
        [0 TurbBand translate <GalX,GalY,0> color_map { GasColour[has_colour] }  frequency 0.82
            ]
        [1 LightBand translate <GalX,GalY,0> color_map { GasColour[has_colour] } frequency 0.82
            ]
      } 
      //*/
      
      // randomseed, nwarps, distance from origin, scale factor
      M_StormWarp(seed(GalX*GalY),15,0.95,0.10)
  
      
    } 



sphere { <0,0,0> Radius
    texture {
       pigment { NewPig }
       finish { ambient 0 }
        
    }
}

#end
