#declare Light_Pos = <0,500,11265> ;

light_source { Light_Pos rgb 40 
    area_light <100,0,0> <0,100,0> 7 , 7
    circular
    orient
    jitter
    
 }
sphere { 0 , 0.95  no_image  }
disc { 
    0 y 5
    translate -y
    translate y*2*clock 
    pigment { rgb 1 } 
    finish { ambient 0 }
    no_shadow 
}
camera {
    orthographic
    location <0,4,0>
    look_at <0,0,0>
    up y*2.1
    right x*2
}

