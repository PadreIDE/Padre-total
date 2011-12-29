#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"
#include "pp_continental.inc"
#include "pp_gas.inc"

#declare Radius = 1;


light_group {
 // Continental(Radius,4,1,16,251,.35,0.72)
  sphere { <0,0,0> Radius hollow  no_shadow 
    pigment { //rgb 0.75 
      /* image_pattern {
        png "maps/bar-seg-rev.png"
        map_type 1 interpolate 3  
      }
      */
      

        //uv_mapping
        image_map {
            png "maps/martian3-lp.png"
            map_type 7
            interpolate 2 
            once
        }
        // rgb <0.9,0.65,0.52>
      
     
      /*
      image_map {
         png "maps/martian3-lp.png" map_type 7 interpolate 3
      }
       */
      //color rgb <0.8,0.5,0.3>
      
      //warp { turbulence 0.3 }
      
      /*
      warp { displace {
          image_pattern { png "maps/ridges-seg-ll.png" map_type 1 interpolate 3 }
          type 1
        }
      }
      */

    }
    finish { specular 0.1 roughness 0.05 diffuse 0.7 ambient 0.3 }
    /*
    normal {
      bump_map {
          //png "maps/bar-seg-rev.png" 
          //png "maps/cr-cubist1.png"
          //hdr "maps/grace_probe.hdr"
          //png "maps/ridges-seg-ll.png"
          png "maps/ridges-ll.png"
          map_type 1 interpolate 3
          
          //png "maps/martian-lp.png"
          //png "maps/martian2-lp.png"
          //png "maps/martian3-lp.png"
          //png "maps/ridges-lp.png"
          //map_type 7 interpolate 3
          bump_size 3
      
      }
      rotate x*30
      rotate y*60
      
      warp { displace {
          image_pattern { png "maps/ridges-ll.png" map_type 1 interpolate 3 }
          type 1
          }
      }
      
      
   }
   */                       
   
}
  // Rocky(Radius,9,2,75,8,.05,0.822)
                /*Gas(
                        6,  // colour
                        0,  // pattern
                        20,  // galaxy X
                        100,  // galaxy Y
                        0.36567  // float modifier 1
                        0.934534  // float modifier 2
                )*/
  light_source { -0.15 color rgb 1 }
  
  //light_source { <5,10,-20> color rgb 1 }
  global_lights off
}

/*
camera { 
    orthographic
    location <0,0,-2>
    look_at <0,0,0>
    up y*2
    right x*2
}
*/

///*
camera { 
    CubeCamera( frame_number ,Radius,0)
}
//*/

/*
CubeMapBoxes(Radius)
//CubeLight(4,Radius)
CubeMapCamera()
*/