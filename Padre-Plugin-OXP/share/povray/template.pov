#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"
#include "pp_continental.inc"
#include "pp_gas.inc"
#include "functions.inc"
#include "math.inc"


#declare Radius = 1;

#declare Gridscale=0.2;


#declare PF_Spherical = function {
    pigment { spherical
        color_map {[0 rgb 0][0.25 rgb 1][1 rgb 0]}
    }
}

#declare PF_Spiral = function {
    pigment { spiral1 1 frequency 1
        rotate x*90
        scale 2
        translate 0 triangle_wave
        color_map { [0 rgb -0.5][1 rgb 0.5] }
    }
}

#declare PF_Vortex = function {
        0.5 + PF_Spiral(x,y,z).red * PF_Spherical(x,y,z).red  
}

#declare PF_Ranges = function {
    pattern  { crackle scale 0.3 lambda 1.85 turbulence 0.5 }
}

#declare PF_Ranges2 = function {
    pattern  { marble translate 10 rotate x*15 scale 0.1 lambda 1.85 turbulence 0.85 }
}

#declare PF_Noise = function { 
    pattern { bozo scale 0.1 translate 1000 turbulence 1 lambda 3 }
}

#declare PF_Mountains = function {
    PF_Ranges2(x,y,z) * ( 0.5 +  PF_Ranges(x,y,z)/2 ) * 
    ( 0.5 + PF_Noise(x,y,z)/2)
    
}

global_settings {
    max_trace_level 100
}
    
/* warp ideas
 
        warp {
            displace {
                        function { PF_Vortex(x,y,z) }
                        turbulence 0.1
                        translate <0,1,0>
                        rotate z*90
                        type 1
            }
        }
        warp {
            displace {
                        function { PF_Vortex(x,y,z) }
                        scale .5
                        turbulence 0.1
                        rotate y*5
                        translate <0,1,0>
                        rotate z*90
                        type 1
            }
        }
        warp {
            displace {
                        function { PF_Vortex(x,y,z) }
                        scale .25
                        turbulence 0.2
                        rotate y*9
                        translate <0,1,0>
                        rotate z*90
                        type 1
            }
        }
*/


light_group {
 // Continental(Radius,7,7,77,153,.05,0.62)
/*  
  sphere { <0,0,0> Radius
    pigment {
         rgb <0.9,0.65,0.52>
    }
    finish { specular 0.1 roughness 0.05 }
    
    /*normal { 
        //Blends
        
        //leopard scale 0.2 lambda 2
        //agate -0.1 scale 30 lambda 4
        //granite scale 5 lambda 6
        marble scale 2 lambda 1.85 turbulence 1.5
        //dents scale 0.5 lambda 3
        
        
        turbulence 0.5
        
        normal_map {
        
        //granite 0.2 scale 1 lambda 6
        //bozo -2 scale 0.01 lambda 6
        //bozo 2 scale 0.01 lambda 6
        //wrinkles -0.6 scale 0.03 lambda 6
        //agate -0.1 scale 30 lambda 6
        //marble 1 scale 0.3 lambda 1.85 turbulence 0.5
        //dents 1.25 scale .04 turbulence 0.5 lambda 6
        //granite -0.2 scale 0.2 lambda 1       
        
        //leopard 3 scale 0.02 lambda 2
        
        [ 0.5 function {PF_Mountains(x,y,z) } 0.15 scale 0.3 ]
        //[ 0.6 granite 0.2 scale 1 lambda 6]
        //   [ 0.6 crackle 0.8 metric 10 scale 0.08 offset 0.5 rotate 15 ]
        }
        

        
        /*
        scallop_wave
        
        scale 10
        warp {
            turbulence 0.3
        }
        scale 1/10
        */
    }
      */  
   
  }
 */            
        
  light_source { -0.15 color rgb 1 }
                Rocky(Radius,3,0,19,150,.5,0.22)
                //Continental(Radius,7,0,19,150,.5,0.22)
                /*Gas(
                        6,  // colour
                        0,  // pattern
                        20,  // galaxy X
                        100,  // galaxy Y
                        0.36567  // float modifier 1
                        0.934534  // float modifier 2
                )*/
  global_lights off
  translate 1000
}

/*
CubeMapBoxes(Radius)
//CubeLight(4,Radius)
CubeMapCamera()
*/
///*
//light_source { <5,7,-5> color rgb 1 }
//light_source { <-5,-7,5> color rgb 1 }

#declare lightpos = vrotate(<3600,3600,10000>, <0,210,0>);
#declare camerapos = <0,0,-2>;

camera { 
    orthographic
    //perspective
    location <0,0,-2>
   // look_at <10,2,1000>
    up y*2.1
    right x*2.1
}
//*/

light_group {
   

sphere { <0,0,0> 1
    pigment {
        uv_mapping
        camera_view { 
            spherical angle 360 location 1000 look_at <1000,1000,1001>
            output 0
        }
    }
    finish { ambient 0.00 diffuse 1}
    scale 0.975
    rotate z*6
}



   //sphere { <1,1,1000> 910 pigment { rgb <1.1,1.05,1>*10 } } 
   
   light_source { lightpos color rgb <1.1,1.05,1> *2.5
   looks_like { sphere { <0,0,0> 600 pigment { rgb <1.1,1.05,1>*2 } } }
        //area_light <1,0,0> <0,1,0> 4 4
        //circular
        //orient
       
        media_attenuation on
        fade_distance 5000
        fade_power 2   
        
    }
   //light_source { <-10000,30,0> color rgb <1.1,1.05,1>  }
  //light_source { <0,2,10000> color rgb <1.1,1.05,1>  }
   
   
   
   sphere { <0,0,0> 1 
       hollow no_shadow
       pigment { rgbf 1 }
       interior {
           
           media { 
               scattering { 
                   1 (1-<0.33,0.33,0.0>)*15 extinction 1
                  //eccentricity 0.03    
               } 
               density { 
                  spherical
                  color_map{
                    [0 rgb 0 filter 0]
                    //[0.01 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]  
                  }  
                  //scallop_wave
               }   
               density { 
                  spherical
                  color_map{
                    [0 rgb 0 filter 0]
                    //[0.01 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]  
                  }  
                  //scallop_wave
               }
           }
           
           
           /*
           media { scattering { 3 (1-<0.33,0.33,0.8>)*5 extinction 1 
                    //eccentricity 0
                }
                density { 
                  spherical
                  color_map{
                    [0 rgb 0 filter 0]
                    //[0.01 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]  
                  }  
                  //scallop_wave
               }   
               density { 
                  spherical
                  color_map{
                    [0 rgb 0 filter 0]
                    //[0.01 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]
                    [0.05 rgb 1 filter 0]  
                  }  
                  //scallop_wave
               }
           }
           */
          
       }
   }
   
   
   
}

