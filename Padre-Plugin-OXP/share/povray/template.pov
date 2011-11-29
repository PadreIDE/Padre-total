#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"


#declare Radius = 1;

sphere { <0,0,0> Radius
        hollow no_shadow inverse double_illuminate
        material {
                Gas(
                        1,  // colour
                        1,  // pattern
                        0,  // galaxy X
                        0,  // galaxy Y
                        0.76567  // float modifier 1
                        0.134534  // float modifier 2
                )
        }
}
CubeMapBoxes(Radius)

CubeMapCamera()
