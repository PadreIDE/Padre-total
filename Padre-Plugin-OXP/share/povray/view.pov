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
            image_map {
                png "planet.png"
                map_type 1
                
            }
        }
        finish { diffuse 1 ambient 0.5 }
        }
    }
    hollow
    no_shadow
}

background { color 0.5 }

light_source { 
    <300,1400,-10000> rgb 1
    
}

