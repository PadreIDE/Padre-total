


sphere {
    <0,0,0> 1
    texture { pigment { color rgb 1 filter 0.5 } finish { ambient 1 } }
    texture {
        pigment { gradient y
            frequency 11
            color_map {
                [0 rgbt 1]
                [0.95 rgbt 1]
                [1 rgbt <1,0,0,0> ]
            }
        }
            finish { ambient 1 }
        }
    texture {
        pigment { spiral1 11
            color_map {
                [0 rgbt 1]
                [0.95 rgbt 1]
                [1 rgbt <0,1,0,0> ]
            }
        }
            finish { ambient 1 }
        }

    
    
    
}

#declare CubeSide = sqrt( 1/3 ) * 2;

box { 0 , CubeSide
    translate -1 * CubeSide/2
    texture { pigment { rgb <0,0,1> } finish { ambient 1 } }
}

camera {
    orthographic
    location <0,0,-2>
    up <0,CubeSide,0>
    right <CubeSide,0,0>
    direction <0,0,1>
    //rotate y*270
    rotate -x*90
}

/*
camera {
    perspective 
    location <3,3,3>
    look_at <0,0,0>
    
}
*/
