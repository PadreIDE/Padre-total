camera {
    perspective
    angle 55
    location <60,110,-200>
    look_at <0,20,0>
}

sphere {
    <0,0,0> 100
    material {
        texture {
            pigment { color rgb <1,0,0> }
        pigment {
            image_map {
                png "planet.png"
                map_type 1
                interpolate 2
                filter all 0
                transmit all 0
            }
        }
        finish { diffuse 1 }
        }
    }
    hollow
    no_shadow
}

background { color 0.1 }

light_source { 
    <10,1000,-10> rgb 1
    fade_power 1
    fade_distance 1000000
}

