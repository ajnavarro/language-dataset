;; ================================================================================================
;; =================================== Don't make changes here ====================================
;; ================================================================================================
breed [redTanks redTank]
breed [blueTanks blueTank]
breed [turrets turret]
breed [bullets bullet]

redTanks-own [
  ;;Users should not set the values of these variables in the code----------
  name  ;;Name of the tank
  myTurret  ;;Pointer to my turret
  velocity  ;;Velocity of the tank, non-negative
  health  ;;Health of the tank. The tank dies when health < 0.
  startXcor  ;;X coordinate when the tank is created
  startYcor  ;;Y coordinate when the tank is created
  wins  ;;Number of wins

  ;;Users can set the values of these variables in the code------------------
  degree  ;;Degree to rotate the tank
  acceleration  ;;Indicator of acceleration: -1 for decelerate, 1 for accelerate, 0 for none

]

blueTanks-own [
  ;;Users should not set the values of these variables in the code----------
  name  ;;Name of the tank
  myTurret  ;;Pointer to my turret
  velocity  ;;Velocity of the tank, non-negative
  health  ;;Health of the tank. The tank dies when health < 0.
  startXcor  ;;X coordinate when the tank is created
  startYcor  ;;Y coordinate when the tank is created
  wins  ;;Number of wins

  ;;Users can set the values of these variables in the code------------------
  degree  ;;Degree to rotate the tank
  acceleration  ;;Indicator of acceleration: -1 for decelerate, 1 for accelerate, 0 for none

  ;;Users can define their own variables here--------------------------------
]

turrets-own [
  ;;Users should not set the values of these variables in the code---------
  heat  ;;Heat of the turret
  fp  ;;Firepower

  ;;Users can set the values of these variables in the code-----------------
  degree  ;;Degree to rotate the turret
  fire?  ;;Control turret fire: true for fire, false for no fire
]

bullets-own [
  ;;Users should not set the values of these variables in the code---------
  velocity
  damage
]

globals [
  ;;Users should not set the values of these variables in the code---------
  TankSize
  StartHealth
  CollisionHealth  ;;Health damage from collisions with tanks or walls
  MaxTurretRotation
  VTankAcc  ;;Acceleration of tank
  VTankDec  ;;Deceleration of tank
  VTankMax  ;;Max speed of tank
  VFactor  ;;For speed adjustment
  FireHeat  ;;Heat generated at each fire
  TankRed
  TankBlue
  Tanks
]

to setup
  ca
  set VFactor 0.02
  set FireHeat 20
  set TankSize 3
  set StartHealth 100
  set CollisionHealth -5
  set MaxTurretRotation 20 * VFactor
  set VTankMax 1 * VFactor
  set VTankAcc 0.2 * VFactor
  set VTankDec -0.4 * VFactor
  set Tanks nobody
  ask patches with [pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor][
    set pcolor yellow
  ]
  reset-ticks
end

to obs-create-tank [argColor argPos]
  let tr nobody

  if Tanks != nobody and count Tanks with [color = argColor] > 0 [
    ask Tanks with [color = argColor] [
      ask myTurret [die]
      die
    ]
  ]
  create-turtles 1 [
    if argColor = red [
      set breed redTanks
      set TankRed self
    ]
    if argColor = blue [
      set breed blueTanks
      set TankBlue self
    ]
    if argPos = 1 [setxy max-pxcor - tankSize max-pycor - tankSize]
    if argPos = 5 [setxy min-pxcor + tankSize min-pycor + tankSize]
    set shape "tank"
    set name TankName
    set color argColor
    set size TankSize
    set health StartHealth
    hatch 1 [
      set breed turrets
      set shape "turret"
      set fp FirePower
      set tr self
    ]
    set myTurret tr
    create-link-to tr [
      tie
      set hidden? true
    ]
    facexy 0 0
    set startXcor xcor
    set startYcor ycor
    set Tanks (turtle-set Tanks self)
    set-current-plot "Health"
    create-temporary-plot-pen name
  ]
end

to obs-reset
  ask bullets [die]
  ask Tanks [
    set xcor StartXcor
    set ycor StartYcor
    set health StartHealth
    facexy 0 0
  ]
  ask turrets [
    set heat 0
  ]
  obs-reset-plots
  cd
  reset-ticks
end

to obs-go
  let tks Tanks with [health > 0]

  ifelse LeaveTrack? [ask tks [pd]] [ask tks [pu]]
  ask tks [
    tank-prepare
  ]
  ask tks [
    ask myTurret [
      turret-rotate
      turret-fire
      turret-cooldown
    ]
  ]
  ask bullets [
    bullet-forward
    bullet-check-collision
  ]
  ask tks [
    tank-rotate
    tank-change-velocity
    tank-forward
    tank-check-collision
  ]
  obs-update-plots
  if obs-check-win [stop]
  tick
end

to-report obs-check-win
  let tks Tanks with [health > 0]
  if count tks = 1 [
    ask one-of tks [set wins wins + 1]
    user-message (word "Winner: " [name] of one-of tks)
    report true
  ]
  if count tks = 0 [
    user-message "Tie"
    report true
  ]
  report false
end

to obs-update-plots
  set-current-plot "Health"
  ask Tanks [
    set-current-plot-pen name
    set-plot-pen-color color
    plot health
  ]
end

to obs-reset-plots
  set-current-plot "Health"
  ask Tanks [
    set-current-plot-pen name
    plot-pen-reset
  ]
end

to tank-accelerate
  set velocity min list VTankMax (velocity + VTankAcc)
end

to tank-decelerate
  set velocity max list 0 (velocity + VTankDec)
end

to tank-change-velocity
  if acceleration = -1 [tank-decelerate]
  if acceleration = 1 [tank-accelerate]
end

to tank-forward
  fd velocity
end

to tank-rotate
  if degree = 0 [stop]
  let dMax 10 - 5 * velocity / VTankMax
  let th [heading] of myTurret
  set heading heading + degree / (abs degree) * (max list dMax abs degree)
  ask myTurret [set heading th]
end

to tank-check-collision
  let tks other Tanks with [distance myself <= TankSize]
  if count tks > 0 [
    ask tks [
      set health health + CollisionHealth
      fd 0 - TankSize / 2
      set velocity 0
    ]
    set health health + CollisionHealth
    fd 0 - TankSize / 2
    set velocity 0
  ]
  if pcolor = yellow [
    set health health - velocity * 10
    set velocity 0
    move-to one-of neighbors with [pcolor != yellow]
  ]
end

to tank-prepare
  if color = red [tank-prepare-red]
  if color = blue [tank-prepare-blue]
end

to turret-rotate
  if degree = 0 [stop]
  set heading heading + degree / (abs degree) * (max list MaxTurretRotation abs degree)
end

to turret-fire
  if not fire? or heat > 0 [stop]
  let tfp fp
  hatch 1 [
    set breed bullets
    set color white
    set shape "circle"
    set size 0.2 * tfp
    fd tankSize / 2
    set velocity (3 - 0.3 * tfp) * VFactor
    set damage tfp * 4 * (3 - 0.3 * 5) * VFactor / velocity
  ]
  set heat heat + fp * FireHeat
end

to turret-cooldown
  set heat max list 0 (heat - 1)
end

to bullet-forward
  fd velocity
end

to bullet-check-collision
  let tks tanks with [distance myself < (TankSize / 2)]
  if count tks > 0 [
    ask tks [
      set health health - [damage] of myself
    ]
    die
  ]
  if pcolor = yellow [die]
end

;; ================================================================================================
;; =================================== Don't make changes above ===================================
;; ================================================================================================

;; ================================================================================================
;; = The following code drives the 'best' red tank,
;; = all you need is to make your blue tank better than it!
;; =
;; = You can not make change related to the red tank here.
;; =================================================================================================

;; ======== status-1 【move forward status】=========
to status-forward[v]
  if((item 0 v) != nobody)[
    set velocity (item 0 v)
  ]
  set degree 0
  fd velocity
end

to status-random-forward[tickNum]
  if ((item 0 tickNum) != nobody)[
    if (ticks mod (item 0 tickNum) = 0)[set heading random-float 360]
  ]
end

;; ======== status-2 【move back status】=========
to status-back
  set heading degree + 180
  bk velocity
end

;; ======== status-3 【turn left status】=========
to status-left
  set heading degree + 90
  lt velocity
end

;; ======== status-4 【turn right status】=========
to status-right
  set heading degree - 90
  rt velocity
end

;; ======== status-5 【stop status】=========
to status-stop
  set degree 0
  set acceleration 0
  set velocity 0
  fd 0
end

;; ======== status-6 【find direction status】=========
;; find a safe direction before hitting on the wall or other tanks.
to status-stop-turn-wall
  let tempDirection (random-float 360)
  if((patch-at-heading-and-distance tempDirection 1) != nobody)[
    ask patch-at-heading-and-distance tempDirection 1 [
      if (pcolor != yellow)[
        ask myself[
          set heading tempDirection
          fd velocity
        ]
      ]
    ]
  ]
end

to status-stop-turn-tank
  let tks other Tanks with [distance myself > TankSize]
  if(patch-at-heading-and-distance heading 2 != nobody)[
    ask patch-at-heading-and-distance heading 2 [
      if (pcolor = black)[
        ask myself[
          status-random-lrb
          if item 0 [velocity] of tks != nobody [
            fd (item 0 [velocity] of tks)
          ]
        ]
      ]
    ]
  ]
end

;; ======== status-7 【random turn left/right status】=========
to status-random-lrb
  let direction random 180
  if (direction > 0 and direction < 60)[status-left]
  if (direction > 60 and direction < 120)[status-right]
  if (direction > 120)[status-back]
end

;; ======== status-8 【dodge other's attack status】========
to status-dodge-forward[args]
  let tks other Tanks with [distance myself > TankSize]
  if count tks > 0[
    ifelse ticks < 100 [
      status-random-forward[101]
    ][
      ifelse(ticks mod (item 0 args) = 0)[
        let tempNum random 100
        ifelse (tempNum mod 2 = 0)[
          set heading ([heading] of (item 0 [myTurret] of tks)  + 90)
        ][
          set heading ([heading] of (item 0 [myTurret] of tks) - 90)
        ]
      ][status-forward[0.01]]
    ]
  ]
end

;; ======== 【set the moving status per tick】=========
;; this function will be called every ticks, we should set up the status machine here.
to tank-prepare-red
  let tks other Tanks with [distance myself < TankSize + 3]
  ifelse count tks > 0 [status-stop-turn-tank][status-forward[0.01]]
  status-dodge-forward[500]

  ask patches with [distance myself < 2 and pcolor = yellow][
    ask myself[
      status-stop-turn-wall
    ]
  ]

  ask myTurret [
    let enemys other Tanks with [distance myself > TankSize] ;with [distance myself < TankSize + 10];
    if(count enemys > 0)[
      if (item 0 ([patch-ahead 5] of enemys) != nobody)[
        facexy ([pxcor] of item 0 ([patch-ahead 5] of enemys)) ([pycor] of item 0 ([patch-ahead 5] of enemys))
      ]
    ]
    set fire? true
  ]
end

;; ================================================================================================
;; =================================== Don't make changes above ===================================
;; ================================================================================================



;; ===========================================================================================================================
;; =================================== The following procedures can be defined by the use ====================================
;; ===========================================================================================================================

;; You can build your tank here! and free to write new functions!
;; If you can beat the red tank (test over 100 times, if you win over 70% of the games, please send us a PR)
;; We will update the 'abest tank' as you designed, and your github avatar is and id will display in our github page.

;; ===========================================================================================================================

to tank-prepare-blue
  let tks other Tanks with [distance myself < TankSize + 3]
  ifelse count tks > 0 [status-stop-turn-tank][status-forward[0.01]]
  status-random-forward[700]

  ask patches with [distance myself < 2 and pcolor = yellow][
    ask myself[
      status-stop-turn-wall
    ]
  ]

  ask myTurret [
    let enemys other Tanks with [distance myself > TankSize] ;with [distance myself < TankSize + 10] ;等到敌人进入距离自己 10(假)再攻击他们
    if(count enemys > 0)[
      if (item 0 ([patch-ahead 5] of enemys) != nobody)[
        facexy ([pxcor] of item 0 ([patch-ahead 5] of enemys)) ([pycor] of item 0 ([patch-ahead 5] of enemys))
      ]
    ]
    set fire? true
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
310
24
747
462
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
763
271
864
304
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1100
400
1273
461
TankName
blue tank
1
0
String

BUTTON
824
26
960
71
Create Red Tank
obs-create-tank red 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
419
237
461
Create Blue Tank
obs-create-tank blue 5
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1099
314
1272
347
FirePower
FirePower
1
5
2.0
1
1
NIL
HORIZONTAL

BUTTON
985
269
1088
303
go
obs-go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
873
270
978
304
reset
obs-reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
245
416
303
461
Win
[wins] of TankBlue
17
1
11

MONITOR
758
26
816
71
Win
[wins] of TankRed
17
1
11

PLOT
759
313
1091
463
Health
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS

SWITCH
1100
358
1271
391
LeaveTrack?
LeaveTrack?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

TankLogo aims for training the users' basic NetLogo programming techniques. It simulates a battle field with multiple tanks combating each other.

## HOW IT WORKS

The model pre-defines the basic behavior of the agents. The users have to define the specific behavior of their own tanks so that the tanks can think and behave automatically without human intervensions. The goal, of course, is to WIN!

## HOW TO USE IT

The users define the procedures like "tank-prepare-red, tank-prepare-blue" which prepare the parameters determining the tanks' behavior in each turn (tick).

## THINGS TO NOTICE

The users should not change the codes about the agents' basic behavior.

Collosions between the tanks or tanks and walls inflict damage.

## THINGS TO TRY

"FirePower" slide sets the fire power of a tank's gun. More fire power means a bullet can inflict more damage but with less velocity. Moreover, a more powful gun needs more time to cool down. When a gun is hot, it cannot fire.

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

TankLogo is inspired by Robocode (https://robocode.sourceforge.io/)

## CREDITS AND REFERENCES

TankLogo is developed by Wei Zhu, Department of Urban Planning, Tongji University, Shanghai, China
Version-20180925
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

tank
true
0
Rectangle -7500403 true true 45 90 255 255
Polygon -7500403 true true 150 30 45 75 255 75

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turret
true
0
Rectangle -16777216 true false 120 45 180 120
Circle -16777216 true false 96 96 108
Circle -1 true false 108 108 85
Rectangle -1 true false 135 60 165 120

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
