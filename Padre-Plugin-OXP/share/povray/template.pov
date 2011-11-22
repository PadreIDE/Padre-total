#version unofficial megapov 1.21;
#include "cm_camera.inc"
#include "pp_textures.inc"


#declare Radius = 1;

sphere { <0,0,0> Radius
        hollow no_shadow inverse double_illuminate
        material {
                Gas(2,0)
        }
}
CubeMapBoxes(Radius)
CubeLight(4,Radius)
CubeMapCamera()
