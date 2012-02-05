#include "cm_planets.inc";

#declare RockyColour = array[14] {
    CM_Martian
    CM_Bland_Jovian
    CM_Europa
    CM_Grey
    CM_Venus
    CM_Europa
//    CM_earthy2_120_80
    CM_Grey
    
    CM_Rocky1
    CM_Rocky2
    CM_Rocky3
    CM_Rocky4
    CM_Rocky5
    CM_Rocky6
    CM_Rocky7
};

#declare RockyPattern = array[8] {
    function { pigment { granite scale 2 cubic_wave turbulence 0.4 lambda 5 } }
    function { pigment { agate scale 4 agate_turb 2 } }
    function { pigment { wrinkles scale 0.3 } }
    function { pigment { crackle cubic_wave turbulence 1 scale 3 } }

    function { pigment { granite scale .9 scallop_wave } }
    function { pigment { agate scale 15 agate_turb 1 scallop_wave turbulence .25 lambda 4 } }
    function { pigment { wrinkles scale 0.3  cubic_wave } }
    function { pigment { crackle scallop_wave turbulence 1.6 scale 2 } }
 
};

#declare RockyNMap = array[8] {
    function { pigment { granite  scale 2 cubic_wave turbulence 0.4 lambda 5 } }
    function { pigment { agate   scale 4 agate_turb 2 } }
    function { pigment { wrinkles  scale 0.3 } }
    function { pigment { crackle  cubic_wave turbulence 1 scale 3 } }

    function { pigment { granite  scale .9 scallop_wave } }
    function { pigment  { agate   scale 15 agate_turb 1 scallop_wave turbulence .25 lambda 4 } }
    function { pigment { wrinkles  scale 0.3  cubic_wave } }
    function { pigment { crackle scallop_wave turbulence 1.6 scale 2 } }
 
};




#declare F_Craters =  function {
    pigment { average
          pigment_map { 
          #local NumCraters = 50;
          #local CraterN = 1;
          #local SeedCraters = seed(1000000);
          #while (CraterN < NumCraters)   
            [ spherical cubic_wave
            // scale 0.5 * rand(SeedCraters)
            scale 0.06 * ( 0.5 + rand(SeedCraters) )
            translate <0,0,1> 
            rotate <rand(SeedCraters)*360,0,0>
            rotate <0,0,rand(SeedCraters)*360>
            rotate <0,rand(SeedCraters)*360,0>
            turbulence 0.05
            colour_map {[0 rgb 0 ] [ 1 rgb 50 -1 ]}
            ]
          #local CraterN=CraterN+1;
          #end
            }
  }
}


#declare RockyNormal = array[8] {
    normal { granite 0.3 scale 2.8 lambda 3 turbulence 0.4 scallop_wave }
    normal { agate -0.15 scale 0.1 agate_turb 1 scallop_wave }
    normal { wrinkles 0.4 scale 0.56 scallop_wave turbulence 1}
    normal { crackle  0.5 form <0.2,0.3,0.4> scale 0.25 }
    normal { granite 0.6 scale 2.8 turbulence 1 }
    
    normal { agate 0.2 scale 0.08 agate_turb 0.86 turbulence 0.5 lambda 2.5 scallop_wave }
    
    normal { wrinkles 0.2 scale 0.01 turbulence 0.5  }

    normal { bozo -3 scale 0.43 turbulence 0.5 lambda 5 }


};

        //normal { wrinkles 0.7  scale 0.02  translate <GalX,GalY,0>*-1}
        //normal { granite  0.2 scale 0.25 }
        //normal { agate 0.5 scale 0.1 agate_turb 1  }

#macro Rocky(Radius,has_colour,has_pattern,GalX,GalY,Modifier1,Modifier2)

#default {
    finish { ambient 0.3 diffuse 0.7 }
    
}

sphere { <0,0,0> Radius hollow inverse
    texture {
        pigment {
            function { RockyPattern[ mod(GalY,8) ](x,y,z).gray }
            translate <GalX,GalY,GalX>
            
            turbulence 0.25*((1+Modifier1)/2)
            lambda 3
            pigment_map {
                [ 0.5     function{  RockyPattern[has_pattern](x,y,z).gray }
                        translate <GalX,GalY,0>
                        scale 5
                        color_map { RockyColour[has_colour] }
                        scale 30
                        warp { turbulence 0.3 + Modifier2/3 }
                        scale 1/30
                ]
                [ 0.75
                        function { RockyPattern[has_pattern](x,y,z).gray }
                        translate <GalX,GalY,0>*-1
                        color_map { RockyColour[has_colour] } 
                        frequency 0.28
                        phase sqrt(Modifier2+Modifier1)/2 
                        scale 70
                        warp { turbulence 0.3 + Modifier1/3 }
                        scale 1/70
                ]
            }
        }
        finish { specular 0.1 roughness 0.05 }
        //
        normal {
            function { RockyNMap[mod(GalY,8)](x,y,z).gray }    
            translate <GalX,GalY,GalX>
            rotate <1,3,5> * Modifier1        
            turbulence 0.25*((1+Modifier1)/2)
            lambda 3.3
            normal_map {
                [ 0.5 RockyNormal[ mod(GalX,8) ]  translate <GalX,GalY,0> ]
                [ 0.75 RockyNormal[ mod(GalY,8) ] translate <GalX,GalY,0> ]
            }
        }
        //
    }
}

/* VerySlow
    texture {
      pigment {
        function { F_Craters(x,y,z).green }
          colour_map {
                [0 rgb 0 transmit 1]
                [0.1 rgb 1 transmit 1]
                [0.2 rgb 1 transmit 0.6]
                
                [0.3 rgb 0 transmit 0.9]
                [1 rgb 0 transmit 0.75 ]
          }
        scale 100
        warp {
            turbulence 1
        }
        scale 1/100
      }
    }
*/

#end

