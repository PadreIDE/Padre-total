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
        pigment {
            rgb 0.75
        }
        normal {
            bump_map {
                png "moon.png"
                map_type 1
                interpolate 4
            }
            5
        }
        finish { diffuse 1 }
        }
    }
    
}

background { color 0.5 }

light_source { 
    <300,1400,-1000> rgb 1 
}

