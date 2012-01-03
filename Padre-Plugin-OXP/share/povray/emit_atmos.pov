//////-----
//#version unofficial megapov 1.21
//#include "functions.inc"
//#include "math.inc"
#declare R0 = 1; // planet radius
#declare ah = 0.07; // atmosphere height
#declare Light_Pos = <0,500,11265>;
#declare Light_Transform = transform { rotate y*130 }

#declare Cam_Pos = <0,0,4>;
light_source { Light_Pos color rgb 1 
	transform { Light_Transform }
	looks_like { sphere { 0,300 pigment { rgb 1 } finish { ambient 1 } } }
    //area_light <100,0,0> <0,100,0> 3 , 3
   //	 circular
   // 	orient
  // 	 jitter
}//

//
sphere { 0, R0 hollow
   texture {
	pigment { wrinkles scale 0.2 turbulence 1 
		color_map{[0.3  rgb <0.05,0.11,0.3>][ .9 rgb <0.03,0.04,0.1>]}
		//warp { displace { agate scale 30 type 1}  }        
	}
   	finish { ambient 0 diffuse 1 specular 0.4 roughness 0.15 }
	
   } 

   texture {
        pigment { 
	   bozo scale 1.8 color_map{[0.65 rgbt 1 ][0.65 rgb <0.85,0.7,0.5>] } 
	   phase 0.06
	   turbulence 3 lambda 3 
	}
        finish {  ambient 0 diffuse 1 specular 0.01 roughness 0.1 }  
    }
} // the planet

// clouds
sphere { 0 , R0 + ah/20 hollow
  texture {
    bozo turbulence 3 lambda 3 scale 2 cubic_wave
    texture_map {
     [0.05 pigment { rgbf <1,1,1,0.015> } 
        finish {  ambient 0 diffuse 1.2 specular 0.5 roughness 0.1 }
	]
     [0.55 pigment { rgbf <1,1,1,1> } finish { ambient 0 diffuse 1.2 } ]  
    }
    //warp { displace { wrinkles } }
  }
}
//


sphere { // the atmosphere
  0, 1  hollow no_shadow
  
  pigment { rgbf 1 } 
  finish { ambient 1 diffuse 0 }

  interior {
    media{
	scattering { 5 20 extinction 0 eccentricity 0.5 }
        emission <0.8,0.8,1>*5 // *1/255 //scale to need
	density { spherical color_map {[0 rgb 0][ah rgb 1]} } 	
	density { spherical color_map {[0 rgb 0][ah rgb 1]} } 	
	density { spherical color_map {[0 rgb 0][ah rgb 1]} } 	
	//density { spherical color_map {[0 rgb 0][ah rgb 1]} } 	
	//density { spherical color_map {[0 rgb 0][ah rgb 1]} } 

	density {
          density_file  df3 "shadowmap.df3" interpolate 1
          translate -0.5
	  rotate -x*90
	  transform { Light_Transform }
 	  scale 2
        }
	
      
      density {
        gradient z
	translate -z/2
	transform { Light_Transform }
        scale 2
        density_map {
          [0.00 rgb <10,  8,  8>/255]//day side
          [0.40 rgb <10,  8,  8>/255]
          [0.45 rgb <37, 12,  6>/255]
          [0.50 rgb <59, 34, 15>/255]//terminator
          [0.55 rgb <66, 58, 56>/255]
          [0.60 rgb 0.65]
          [1.00 rgb 0.65]//night side
        }
      }
      
    }
  }

  scale R0+ah
}




camera {
    perspective
    location <0,0,-4>


    look_at <0,0,0>
    up y*2.2
    right x*2.2
angle 33
    
}

