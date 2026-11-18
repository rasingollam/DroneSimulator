extends RefCounted
## Extra biomes share this pure geography with terrain workers and water queries.
const SITES := [
 ["Slot canyon",Vector2(-2070,-450),"Twisting sandstone narrows, side gorge and a timber crossing"],
 ["Coastal lookout",Vector2(-2350,1200),"Sea stacks, a lighthouse, coves and an open sea cave"],
 ["Rice foothills",Vector2(2370,1200),"Flooded terraces, stone walls, irrigation and a hillside hamlet"],
 ["Braided river",Vector2(-250,2300),"Choose a channel between gravel islands and fallen trees"],
 ["Alpine bowl",Vector2(2100,-2500),"Snowy bowl, steep descents and a ridge traverse"],
 ["Landslide pass",Vector2(-2050,-2100),"Exposed scarps, scree fans, uprooted pines and boulders"],
 ["Mine camp",Vector2(-2050,460),"A branching mine passage, abandoned equipment and ruins"],
 ["Dam overlook",Vector2(2150,-1710),"Reservoir, spillway, hydro station and downstream gorge"],
 ["Ridge station",Vector2(800,-2600),"Cable cars, lookout towers and the summit-to-lake line"]
]
const MINE := [Vector2(-2050,540),Vector2(-2050,660),Vector2(-1980,740),Vector2(-1860,740)]
static func shore_x(z: float) -> float:
 return -2600+sin(z*0.003)*110+exp(-pow((z-1500)/200,2))*200
static func slot_x(z: float) -> float:
 return -2200+sin((z+600)*0.008)*55+sin((z+600)*0.017)*12
static func slot_y(z: float) -> float:
 return 75+(-z+50)*0.04
static func delta_x(z: float,channel: int) -> float:
 return -500+sin(z*0.002)*120+(channel-1)*65+sin(z*0.012+channel)*20
static func delta_y(z: float) -> float:
 return lerpf(34+(3000-z)*0.01,35,smoothstep(2700,2800,z))
static func segment_distance(p: Vector2,a: Vector2,b: Vector2) -> float:
 return p.distance_to(a+(b-a)*clampf((p-a).dot(b-a)/(b-a).length_squared(),0,1))
static func height(x: float,z: float,base: float) -> float:
 var p := Vector2(x,z)
 var h := base
 if x < -2150 and z>300 and z<2500:
  var coast := lerpf(5,maxf(base,70),smoothstep(shore_x(z)-80,shore_x(z)+180,x))
  h=lerpf(h,coast,smoothstep(300,650,z)*(1-smoothstep(2200,2500,z)))
  for island in [Vector2(-2850,1100),Vector2(-2950,1700),Vector2(-2750,2100)]:
   var offset: Vector2=p-island
   var radius: float=offset.length()*(1+sin(offset.angle()*3+island.x*0.001)*0.17+sin(offset.angle()*7)*0.08)
   h+=75*(1-smoothstep(18,63,radius))
  var sea_cave := (1-smoothstep(12,40,absf(x+2445)))*(1-smoothstep(58,105,absf(z-1500)))
  h=lerpf(h,14,sea_cave)
 if x>-2550 and x<-1650 and z>-1300 and z<200:
  var d := absf(x-slot_x(z))
  var width := 9+smoothstep(700,1100,absf(z+550))*35
  var gorge := lerpf(slot_y(z),h,smoothstep(width,width+75,d))
  h=lerpf(h,gorge,smoothstep(-1300,-1100,z)*(1-smoothstep(0,200,z)))
  var side := absf(z-(-650-(x+2200)*0.4))
  var branch := lerpf(103+(x+2200)*0.04,h,smoothstep(12,75,side))
  h=lerpf(h,branch,smoothstep(-2250,-2150,x)*(1-smoothstep(-1850,-1700,x)))
 if z>1500 and z<3200 and x>-1100 and x<200:
  var reach := smoothstep(1500,1770,z)*(1-smoothstep(2970,3200,z))
  var valley := lerpf(delta_y(z)+3,h,smoothstep(135,330,absf(x+500-sin(z*0.002)*120)))
  for channel in range(3):
   valley=lerpf(delta_y(z)-3,valley,smoothstep(11,24,absf(x-delta_x(z,channel))))
  h=lerpf(h,valley,reach)
  var lake := Vector2((x+500)/220,(z-2920)/160).length()
  h=lerpf(32,h,smoothstep(0.8,1.5,lake))
 if x>1750 and x<2520 and z>700 and z<1700:
  var u := (x-1900)/44
  var terraces := 145+(floorf(u)+smoothstep(0.75,1,fposmod(u,1)))*3
  var amount := smoothstep(1750,1900,x)*(1-smoothstep(2300,2520,x))*smoothstep(700,900,z)*(1-smoothstep(1500,1700,z))
  h=lerpf(h,terraces,amount)
  h=lerpf(181,h,smoothstep(50,100,p.distance_to(Vector2(2370,1200))))
 var bowl := p.distance_to(Vector2(2100,-2650))
 if bowl<800:
  h=lerpf(h,610+pow(bowl/620,1.65)*170+(sin(x*0.012)+sin(z*0.009))*4,1-smoothstep(540,800,bowl))
 if bowl<800:
  for spire in [Vector2(2400,-2700),Vector2(2150,-3100),Vector2(1800,-2900)]: h+=65*exp(-p.distance_squared_to(spire)/600)
 var slide := p-Vector2(-2150,-2250)
 if slide.length()<500:
  h-=exp(-pow(slide.x/160,2)-pow((slide.y+70)/150,2))*65*(1-smoothstep(350,500,slide.length()))
  h+=exp(-pow(slide.x/250,2)-pow((slide.y-180)/240,2))*22*(1-smoothstep(350,500,slide.length()))
 var quarry := Vector2((x-2450)/1.1,z+300).length()
 if quarry<380:
  var q := quarry/55
  var benches := 110+(floorf(q)+smoothstep(0.7,1,fposmod(q,1)))*14
  h=lerpf(benches,h,smoothstep(250,380,quarry))
 if x>-2200 and x<-1700 and z>380 and z<900:
  var d := INF
  for i in range(MINE.size()-1): d=minf(d,segment_distance(p,MINE[i],MINE[i+1]))
  h=lerpf(h,110,1-smoothstep(13,40,d))
  for entrance in [MINE[0],MINE[-1]]: h=lerpf(h,110,1-smoothstep(50,100,p.distance_to(entrance)))
 var gallery := (1-smoothstep(5,25,absf(x-1750)))*smoothstep(-2230,-2210,z)*(1-smoothstep(-2120,-2100,z))
 h=lerpf(h,545,gallery)
 var reservoir := Vector2((x-2300)/160,(z+1950)/160).length()
 if reservoir<1.65:
  h=lerpf(264,h,smoothstep(0.8,1.65,reservoir))
 if z>-1790 and z<-1400 and absf(x-2300)<180:
  h=lerpf(h,236,smoothstep(-1790,-1760,z)*(1-smoothstep(-1500,-1400,z))*(1-smoothstep(32,160,absf(x-2300))))
 h=lerpf(h,250,1-smoothstep(48,85,p.distance_to(Vector2(2430,-1690))))
 return h
static func water_height(x: float,z: float) -> float:
 if x<-2150 and z>350 and z<2450: return 12
 if z>1750 and z<2800 and x>-1000 and x<0:
  for channel in range(3):
   if absf(x-delta_x(z,channel))<18: return delta_y(z)
 if Vector2((x+500)/330,(z-2920)/240).length()<1: return 35
 if x>1902 and x<2290 and z>910 and z<1490:
  var u:=fposmod(x-1900,44)
  var v:=fposmod(z-910,48)
  if u>3 and u<31 and v>3 and v<44: return 145+floorf((x-1900)/44)*3+0.1
 if x>1900 and x<2290 and absf(z-1500)<1.5: return 145+floorf((x-1900)/44)*3+0.15
 if z<-1795 and Vector2((x-2300)/270,(z+1950)/270).length()<1: return 270
 if absf(x-2300)<9 and z>-1799 and z<-1735:
  if z<-1789: return lerpf(270,269,(z+1799)/10)
  if z<-1765: return lerpf(269,242,(z+1789)/24)
  return lerpf(242,240,(z+1765)/30)
 if z>-1780 and z<-1480 and absf(x-2300)<25: return 240
 return NAN

static func passage_clearance(x: float,z: float) -> bool:
 if absf(x+2445)<28 and absf(z-1500)<115: return true
 if x>-2220 and x<-1700 and z>380 and z<900:
  for i in range(MINE.size()-1):
   if segment_distance(Vector2(x,z),MINE[i],MINE[i+1])<26: return true
 if x<-1300 and z>-1950 and z<-1000:
  var trail: Array[Vector2]=[Vector2(-1400,-1800),Vector2(-1650,-1800),Vector2(-1900,-1600),Vector2(-2150,-1280),Vector2(slot_x(-1100),-1100)]
  for i in range(trail.size()-1):
   if segment_distance(Vector2(x,z),trail[i],trail[i+1])<5: return true
 if x<-1700 and z>-1250 and z<160 and absf(x-slot_x(z))<25: return true
 return false
