;                                     ABMS PROJECT
; Group-6
;------------------------------------------------------------------------------------------------------------------------------------------------------

globals
[
  max-grain                   ; maximum amount any patch can hold
  gini-index-reserve          ; measure of gini coefficient for every tick
  lorenz-points               ; list that contains (wealth-sum-so-far / total-wealth) * 100)  for the lorenz curve
  initail-wealth              ; initial wealth each turtle has
  gdp-growth                  ; % of grains produced & grown
  ed-level                    ; education attained by a turtle 0,25,50,75 or 100
  total-consumption           ; total consumption of each turtle
  last-tick-median-income     ; median income of previous tick
  consumption-tax-collection  ; tax to be paid for consumption
  inheritance-tax-collection  ; tax to be paid for inheriting the wealth of a parent
  income-tax-collection       ; tax imposed on the income of a turtle
  total-tax-collected         ; sum of all 3 taxes
  metabolism-max              ; max. amount of grain a turtle eats
  grain-growth-interval       ; determines how often grain grows (set to 1 to represent a year)

]

patches-own
[
  grain-here        ; the current amount of grain on this patch
  max-grain-here    ; the maximum amount of grain this patch can hold

  rich-turtle       ; no. of rich turtles in a patch
  poor-turtle       ; no. of poor turtles in a patch
  mid-turtle        ; no. of mid-class turtles in a patch

  highly-edu-turtle ; no. of highly educated turtles in a patch (12th grade & higher)
  edu-turtle        ; no. of educated turtles in a patch ( high school)
  unedu-turtle      ; no. of uneducated turtles in a patch (primary school or lower)

  rich-median-vision      ; median vision of rich turtles without considering education
  mid-median-vision       ; median vision of mid turtles without considering education
  high-edu-median-vision  ; median vision of highly educated turtles
  mid-edu-median-vision   ; median vision of mid-educated turtles
]

turtles-own
[
  age              ; how old a turtle is
  wealth           ; the amount of grain a turtle has
  life-expectancy  ; maximum age that a turtle can reach
  metabolism       ; how much grain a turtle eats each time
  vision           ; how many patches ahead a turtle can see
  income           ; amount of grain a turtle collects from a patch
  consumption_     ; consumption of turtule in a single tick
  bequest          ; amount of wealth a turtle had before it dies
  inheritance      ; amount of wealth a turtle inherits from its parent
  education        ; education level of a turlte
                   ;(uneducated:0, primary education: 25, secondary education:50, tertiary education:75, graduate:100)
]
;------------------------------------------------------------------------------------------------------------------------------------------------------
;;;
;;; SETUP AND HELPERS
;;;


to setup
  clear-all
  reset-ticks
  ;; set global variables to appropriate values
  set max-grain 50
  set metabolism-max 25
  set grain-growth-interval 1
  ;; call other procedures to set up various parts of the world
  setup-patches
  setup-turtles
  update-lorenz-and-gini

end

;; set up the initial amounts of grain each patch has
to setup-patches
  ;; give some patches the highest amount of grain possible --
  ;; these patches are the "best land"
  ask patches
    [ set max-grain-here 0
      if (random-float 100.0) <= percent-best-land
        [ set max-grain-here max-grain
          set grain-here max-grain-here ] ]
  ;; spread that grain around the window a little and put a little back
  ;; into the patches that are the "best land" found above
  repeat 5
    [ ask patches with [max-grain-here != 0]
        [ set grain-here max-grain-here ]
      diffuse grain-here 0.25 ]
  repeat 10
    [ diffuse grain-here 0.25 ]          ;; spread the grain around some more
  ask patches
    [ set grain-here floor grain-here    ;; round grain levels to whole numbers
      set max-grain-here grain-here      ;; initial grain level is also maximum
      recolor-patch ]
end

to recolor-patch  ;; patch procedure -- use color to indicate grain level
  set pcolor scale-color white grain-here 0 max-grain
end

;; set up the initial values for the turtle variables
to setup-turtles
  set-default-shape turtles "person"
  create-turtles num-people
    [ move-to one-of patches  ;; put turtles on patch centers
      set size 1.9  ;; easier to see
      set-initial-turtle-vars
      set age random life-expectancy ]

  recolor-turtles
  initial-wealth-dist
end

to set-initial-turtle-vars
  set age 0
  face one-of neighbors4
  set life-expectancy life-expectancy-min + random (life-expectancy-max - life-expectancy-min + 1)
  set metabolism 1 + random metabolism-max
 ; ifelse ( ticks = 0 )
 set wealth metabolism + random 50
 set-education
 if (ticks > 1) [set wealth wealth + inheritance + metabolism ]  ; inherting the wealthh

   ifelse(enable-edu)
  [set-vision]
  [ifelse(ticks = 0)
    [set vision 1 + random max-vision]
    [ set-class-based-vision]]

end

;; Set the class of the turtles -- if a turtle has less than a third
;; the wealth of the richest turtle, color it red.  If between one
;; and two thirds, color it green.  If over two thirds, color it blue.
to recolor-turtles
  let median-sal median [wealth] of turtles
  ask turtles
    [ ifelse (wealth < 3 / 4 * median-sal )   ;;
        [ set color red ]
        [ ifelse (wealth <= 1.75 * median-sal)
            [ set color green ]
            [ set color blue ] ] ]
end

;;;
;;; GO AND HELPERS
;;;

to go
  ask turtles
    [ turn-towards-grain ]  ;; choose direction holding most grain within the turtle's vision
  harvest   ; With the Education on/off switch

  ask turtles
  [ move-eat-age-die
   ; income-tax ;; collect income tax
  ]
  recolor-turtles
  set gdp-growth  (random (gdp-growth-max) + random (gdp-growth-min)) / 100 ; gdp-growth variable

 set max-grain max-grain + max-grain * gdp-growth


  ;; grow grain every grain-growth-interval clock ticks
  if ticks mod grain-growth-interval = 0
    [ ask patches [ grow-grain ] ]

  update-lorenz-and-gini

  set last-tick-median-income median [income] of turtles ; store median income of this tick
  set total-tax-collected consumption-tax-collection + inheritance-tax-collection + income-tax-collection; store total tax collected
  tick
end



;; this is the initial wealth distribution for the agents as the inital wealth is distributed based on the metabolisim
to initial-wealth-dist
  let tot-wealth sum [wealth] of turtles
  let amt-dist initail-wealth * tot-wealth
  ask turtles [
    if ( who <= floor (0.05 *  num-people)) [ set wealth wealth + (.3 * amt-dist)/( 0.05 * num-people) ]
    if ( who <= floor (0.30 *  num-people) and who > floor (0.05 *  num-people) ) [ set wealth wealth + (.35 * amt-dist)/( 0.25 * num-people) ]
    if ( who <= floor (0.70 *  num-people) and who > floor (0.30 *  num-people) ) [ set wealth wealth + (.25 * amt-dist)/( 0.40 * num-people) ]
    if (  who > floor (0.70 *  num-people) ) [ set wealth wealth + (.10 * amt-dist)/( 0.30 * num-people) ]
  ]

end

;-----------------------------------------------------------------------------------------------------------------------
;; determine the direction which is most profitable for each turtle in
;; the surrounding patches within the turtles' vision
to turn-towards-grain  ;; turtle procedure
  set heading 0
  let best-direction 0
  let best-amount grain-ahead
  set heading 90
  if (grain-ahead > best-amount)
    [ set best-direction 90
      set best-amount grain-ahead ]
  set heading 180
  if (grain-ahead > best-amount)
    [ set best-direction 180
      set best-amount grain-ahead ]
  set heading 270
  if (grain-ahead > best-amount)
    [ set best-direction 270
      set best-amount grain-ahead ]
  set heading best-direction
end

to-report grain-ahead  ;; turtle procedure
  let total 0
  let how-far 1
  repeat vision
    [ set total total + [grain-here] of patch-ahead how-far
      set how-far how-far + 1 ]
  report total
end
;---------------------------------------------------------------------------------------------------------------------------------------

to grow-grain  ;; patch procedure
  ;; if a patch does not have it's maximum amount of grain, add
  ;; num-grain-grown to its grain amount   ;;-> num of grain grown
  set max-grain-here max-grain-here + max-grain-here * gdp-growth
  if (grain-here < max-grain-here)
    [ set grain-here grain-here + num-grain-grown
      recolor-patch
      ;; if the new amount of grain on a patch is over its maximum
      ;; capacity, set it to its maximum
      if (grain-here > max-grain-here)
        [ set grain-here max-grain-here ]
      recolor-patch ]
end

;---------------------------------------------------------------------------------------------------------------------------------------
to set-education
  set ed-level [0 25 50 75 100] ; uneducated - primary education - secondary education - tertiary education - graduate
  if color = red [
    set education one-of ed-level
    if education > poor-ed-max
    [ set education poor-ed-max ]
]
  if color = green [
    set education one-of ed-level + 25
    if education > mid-ed-max
    [ set education mid-ed-max ]
]
  if color = blue [
    set education one-of ed-level  + 50
    if education > rich-ed-max
    [ set education rich-ed-max ]
 ]
end
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;; each turtle harvests the grain on its patch.  if there are multiple
;; turtles on a patch, divide the grain evenly among the turtles
to harvest-without-edu ;; YoY income -> make it realistic       Harvest Without education
  ; have turtles harvest before any turtle sets the patch to 0
  ;ask turtles
    ;[ set wealth floor (wealth + (grain-here / (count turtles-here))) ]
  ;; now that the grain has been harvested, have the turtles make the
  ;; patches which they are on have no grain
  ask patches [
    if( count turtles-here != 0 )[
    let patch-median median [wealth] of turtles-here
    let turtles-set sort [wealth] of turtles-here

    set  rich-turtle count turtles-here with [color = blue]
    set mid-turtle count turtles-here with [color = green]
    set poor-turtle count turtles-here with [color = red]
  ]
  ]
  ;;these distribution are done based on the current global scenario's
  ask turtles[
    ;if there are all 3 classes
    if( rich-turtle != 0 and mid-turtle != 0 and poor-turtle != 0 )
    [
      if( color = blue ) [ set income (.50 * grain-here) / rich-turtle ]
      if( color = green ) [ set income (.30 * grain-here) / mid-turtle ]
      if( color = red ) [ set income (.20 * grain-here) / poor-turtle ]
    ]
    ;if there are poor and middle class
    if( rich-turtle = 0 and mid-turtle != 0 and poor-turtle != 0 )
    [
      if( color = green ) [ set income (.60 * grain-here) / mid-turtle ]
      if( color = red ) [ set income (.40 * grain-here) / poor-turtle ]
    ]
    ;if there are rich and poor class
    if( rich-turtle != 0 and mid-turtle = 0 and poor-turtle != 0 )
    [
     if( color = blue ) [ set income (.70 * grain-here) / rich-turtle ]
     if( color = red ) [ set income (.30 * grain-here) / poor-turtle ]
    ]
    ;if there are rich and middle class
    if( rich-turtle != 0 and mid-turtle != 0 and poor-turtle = 0 )
    [

     if( color = green ) [ set income (.40 * grain-here) / mid-turtle ]
     if( color = blue ) [ set income (.60 * grain-here) / rich-turtle ]
    ]
    ;if there are only poor class
    if( rich-turtle = 0 and mid-turtle = 0 and poor-turtle != 0 )
    [
      if( color = red ) [ set income ( grain-here) / poor-turtle ]
    ]
    ;if there are only middle class
    if( rich-turtle = 0 and mid-turtle != 0 and poor-turtle = 0 )
    [
      if( color = green ) [ set income ( grain-here) / mid-turtle ]
    ]
    ;if there are only rich class
    if( rich-turtle != 0 and mid-turtle = 0 and poor-turtle = 0 )
    [
      if( color = blue ) [ set income ( grain-here) / rich-turtle ]
    ]
    ;if min wage, distribute to red from tax
    if ( color = red and minimum-wage ) ; poor turtule, gets upto minimum wage
    [
      let min-wage-of-turtle min-wage-rate-percent-for-median * last-tick-median-income
      let need min-wage-of-turtle - income
      if ( need > 0   and total-tax-collected > need )
      [
        set total-tax-collected total-tax-collected - need
        set income min-wage-of-turtle
      ]
    ]

     set wealth floor ( wealth + income ) - 1
  ]

end


; Harvest With Education
to harvest-with-edu

  ask patches[
    if( count turtles-here != 0 )[
    set highly-edu-turtle count turtles-here with [education >= 75]
    set edu-turtle count turtles-here with [education = 50 ]
    set unedu-turtle count turtles-here with [education < 50]
  ]
  ]

  ask turtles[

  if( highly-edu-turtle != 0 and  edu-turtle != 0 and unedu-turtle != 0 )
    [
        if( education >= 75 )
          [ set income (.50 * grain-here) / highly-edu-turtle ]

        ifelse( education >= 50 and education < 75 )
        [ set income (.30 * grain-here) / edu-turtle ]
        [ set income (.20 * grain-here) / unedu-turtle]

        if( highly-edu-turtle = 0 and edu-turtle != 0 and unedu-turtle != 0 )
        [
          if( education >= 50 and education < 75 ) [ set income (.60 * grain-here) / edu-turtle ]
          if( education < 50 ) [ set income (.40 * grain-here) / unedu-turtle ]
        ]

    ;if there are rich and poor class
    if( highly-edu-turtle != 0 and edu-turtle = 0 and poor-turtle != 0 )
    [
     if( education >= 75 ) [ set income (.70 * grain-here) / highly-edu-turtle ]
     if( education < 50 ) [ set income (.30 * grain-here) / unedu-turtle ]
    ]
    ;if there are rich and middle class
    if( highly-edu-turtle != 0 and edu-turtle != 0 and unedu-turtle = 0 )
    [

     if( education >= 50 and education < 75) [ set income (.40 * grain-here) / edu-turtle ]
     if( education >= 75 ) [ set income (.60 * grain-here) / highly-edu-turtle ]
    ]
    ;if there are only poor class
    if( highly-edu-turtle = 0 and edu-turtle = 0 and unedu-turtle != 0 )
    [
      if( education < 50 ) [ set income ( grain-here) / unedu-turtle ]
    ]
    ;if there are only middle class
    if( highly-edu-turtle = 0 and edu-turtle != 0 and unedu-turtle = 0 )
    [
      if( education >= 50 and education < 75 ) [ set income ( grain-here) / unedu-turtle ]
    ]
    ;if there are only rich class
    if( highly-edu-turtle != 0 and edu-turtle = 0 and unedu-turtle = 0 )
    [
      if( education >= 75 ) [ set income ( grain-here) / highly-edu-turtle ]
    ]

    ;if min wage, distribute to red from tax
    if ( color = red and minimum-wage  ) ; poor turtule, gets upto minimum wage
    [
      let min-wage-of-turtle min-wage-rate-percent-for-median * last-tick-median-income
      let need min-wage-of-turtle - income
      if ( need > 0  and total-tax-collected > need )
      [
        set total-tax-collected total-tax-collected - need
        set income min-wage-of-turtle
      ]
    ]

     set wealth floor ( wealth + income ) - 2
  ]
  ]

  ask turtles
    [ set grain-here 0
      recolor-patch ]

end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to income-perf-meteric-with-edu ; measure of the income distribution between social class based on education
  ask patches[
    if( count turtles-here != 0 )[
      set  highly-edu-turtle count turtles-here with [ education >= 75 ]
      set  edu-turtle count turtles-here with [ education = 50 ]
      if ( highly-edu-turtle > 0 and edu-turtle > 0 )
      [
        set high-edu-median-vision median [vision] of turtles-here with [ education >= 75 ]
        set mid-edu-median-vision median [vision] of turtles-here with [  education = 50 ]
      ]
  ]
  ]
  ask turtles[
    if( color = blue  )
    [ if ( highly-edu-turtle > 0)
      [
        ifelse (vision >= high-edu-median-vision)
        [
          set income income * 1.05
      ]
      [
        set income income * 0.95
      ]]
    ]
    if( color = green  )
    [ if ( edu-turtle > 0)
      [
        ifelse (vision >= mid-edu-median-vision)
        [
          set income income * 1.1
      ]
      [
        set income income * 0.9
      ]]
    ]

  ]
end



to income-perf-meteric-without-edu ; measure of the income distribution between social class without considering education
  ask patches[
    if( count turtles-here != 0 )[
       set  rich-turtle count turtles-here with [color = blue]
    set mid-turtle count turtles-here with [color = green]

      if (rich-turtle > 0 and mid-turtle > 0 ) [

      set rich-median-vision median [vision] of turtles-here with [ color = blue ]
      set mid-median-vision median [vision] of turtles-here with [ color = green ]
      ]

  ]
  ]
  ask turtles[
    if( color = blue  )
    [ if ( rich-turtle > 0)
      [
        ifelse (vision >= rich-median-vision)
        [
          set income income * 1.05
      ]
      [
        set income income * 0.95
      ]]
    ]
    if( color = green  )
    [ if ( mid-turtle > 0)
      [
        ifelse (vision >= mid-median-vision)
        [
          set income income * 1.1
      ]
      [
        set income income * 0.9
      ]]
    ]

  ]
end

;---------------------------------------------------------------------------------------------------------------------------------

to harvest
  ifelse enable-edu
  [
    harvest-with-edu
    income-perf-meteric-with-edu
  ]
  [
    harvest-without-edu
    income-perf-meteric-without-edu
  ]

end



to consumption
  if (color = red )
  [
    ifelse (public-healthcare)
    [
      let health-expenditure random-normal poor-healthcare-rate 4.5
      let income-used random-normal poor-consumption 10 - health-expenditure
      set wealth wealth - income * ( income-used / 100 )
      set total-consumption total-consumption + income * (income-used / 100)
      set consumption_  income * (income-used / 100)
    ]
    [
      let income-used random-normal poor-consumption 10   ;[ 70 -90 ]  add a minimum consuption
      set wealth wealth - income * ( income-used / 100 )
      set total-consumption total-consumption + income * (income-used / 100)
      set consumption_  income * (income-used / 100)
    ]
  ]

  if (color = green )
  [
    ifelse (public-healthcare)
    [
      let health-expenditure random-normal mid-healthcare-rate 3.5
      let income-used random-normal mid-consumption 7  - health-expenditure
      set wealth wealth - income * ( income-used / 100 )
      set total-consumption total-consumption + income * (income-used / 100)
      set consumption_  income * (income-used / 100)
    ]
    [
      let income-used random-normal mid-consumption 7
      set wealth wealth - income * ( income-used / 100 )
      set total-consumption total-consumption + income * (income-used / 100)
      set consumption_  income * (income-used / 100)
    ]
  ]

  if (color = blue )
  [
    let income-used random-normal rich-consumption 5
    set wealth wealth - income * ( income-used / 100 )
    set total-consumption total-consumption + income * (income-used / 100)
    set consumption_  income * (income-used / 100)
  ]

  set consumption-tax-collection consumption-tax-collection + ( total-consumption * consumption-tax-rates-percent / 100.0 )

  if ( enable-consumption-rebate )
  [ consumption-rebate  ]
end

to consumption-rebate
  ; for poor people, give back 60%-70% of previous collected tax on consumption
  ; for mid people, return 10%-30%
  ; for rich, not return
  if ( color = red )
  [
    let return-back  ( poor-rebate / 100.0 * consumption_ * consumption-tax-rates-percent / 100.0 )
    set wealth wealth + return-back
    set consumption-tax-collection consumption-tax-collection - return-back
  ]

  if ( color = green)
  [
    let return-back ( middle-rebate / 100.0 * consumption_ * consumption-tax-rates-percent / 100.0 )
    set wealth wealth + return-back
    set consumption-tax-collection consumption-tax-collection - return-back
  ]
end
;-------------------------------------------------------------------------------------------------------------------------------------------------------------------

to set-class-based-vision ;  only when education is enabled

  if( color = red ) [ set vision 1 + random(poor-vision-max) ]
  if( color = blue ) [ set vision 1 + random(rich-vision-max) ]
    if( color = green ) [ set vision 1 + random(mid-vision-max) ]

end

to set-vision ; only when education is enabled ; a person has more oppurtunities if educated
  if( education <=  25) [ ; uneducated - primary education
    set vision  1 + random int( max-vision / 3)
  ]
  if education >  25 and education <=  50 [  ; primary education - secondary education
    set vision  2 + random int( max-vision * 2 / 3)
  ]
  if( education > 50 ) [  ;  secondary education - graduate
    set vision  5 + random( max-vision )
  ]
end

;----------------------------------------------------------------------------------------------------------------------------------------------------
to inheritance-tax
  let median-sal median [wealth] of turtles
  ; Flat inheritance Tax and a progrssive tax
  if ( enable-inheritance-tax and wealth > ( inheritance-threshold / 100 ) * median-sal )
  [
    ; flat inheritance tax
    ifelse enable-flat-inh [
      let post-thres bequest -  ( inheritance-threshold / 100 ) * median-sal
      let tax post-thres * ( flat-inh-tax / 100 )
      set inheritance bequest - tax - ( inheritance-threshold / 100 ) * median-sal
      set inheritance-tax-collection inheritance-tax-collection + tax
    ]
    ; progressive tax
    [
      ; after the inheritance tax threshold
      let post-thres bequest -  ( inheritance-threshold / 100 ) * median-sal
      ; tax-rate per slab
      let high-tax-bracket highest-thres-max-wealth * median-sal

      let slab-no ceiling post-thres / median-sal

      if ( ceiling post-thres / high-tax-bracket > 1)
      [
        set slab-no no-tax-slabs
      ]
      let tax-slab-rate floor max-prog-inh-tax /  no-tax-slabs
      ; number of tax slabs


      let cur-no 1
      let tot-tax 0
      while [ cur-no < slab-no ]
      [

        let curr-slab ( cur-no * tax-slab-rate ) / 100
        set tot-tax tot-tax + curr-slab * median-sal
        set cur-no cur-no + 1
      ]
      set tot-tax tot-tax + ( bequest - (cur-no - 1) * median-sal ) *  ( ( cur-no * tax-slab-rate ) / 100 )
      ; post progressive tax in inheritance tax
      set inheritance bequest - tot-tax
      set inheritance-tax-collection inheritance-tax-collection + tot-tax
    ]
  ]
end


; 6 slabs
; 2.5% --- 40%
; 2 slabs, __|2.5%|40%
; 3 slabs, __|2.5%|10%|40%
; 4 slabs, __|2.5%|10%|20%|40%
; n slabs,
; 0. calculate % of tax-payment for each bracket/slab based on median tax
; 1. find what slab turtle belongs to
; 2. for each slab upto this turltles slab, collect share of tax

to income-tax
  let median-sal median [income] of turtles
  if ( enable-prog-tax  and median-sal > 0 and income > 0 and ticks > 100 )
  [
    if (income > income-tax-threshold * median-sal) [


     let tax-slab-rate  ( top-income-tax-rate - bottom-income-tax-rate ) / no-income-tax-slabs
      let cur-no 1
      let tot-tax 0

      let high-tax-bracket max-bracket * median-sal

      let slab-no ceiling income / median-sal

      if ( ceiling (income / high-tax-bracket) > 1)
      [
       set slab-no no-income-tax-slabs
      ]

      let salary income - income-tax-threshold * median-sal

      while [ cur-no < slab-no  and salary > 0]
      [

        let curr-slab ( cur-no * tax-slab-rate ) / 100
        set tot-tax tot-tax + curr-slab * income
        set salary salary - median-sal
        set cur-no cur-no + 1
      ]

      set tot-tax tot-tax + ( salary ) *  ( ( cur-no * tax-slab-rate ) / 100 )
      set income income - tot-tax
      set income-tax-collection income-tax-collection + tot-tax
    ]
  ]
end
;------------------------------------------------------------------------------------------------------------------------------------------------------
to move-eat-age-die  ;; turtle procedure
  fd 1
  ;; consume some grain according to metabolism
  ;set wealth (wealth - metabolism) ;; The Metabolisim Should BE a percentage of income or wealth  and seperate metabolism for poor ,mid,rich
  consumption
  set age (age + 1)
  income-tax;; grow older
  ;; check for death conditions: if you have no grain or
  ;; you're older than the life expectancy or if some random factor
  ;; holds, then you "die" and are "reborn"
  if (wealth < 0) or (age >= life-expectancy)
    [
      if (wealth >= 0)[
      set bequest wealth    ; for inheritance

      ifelse enable-inheritance-tax
        [inheritance-tax]
        [set inheritance bequest]
      ]  ; Wrote a Unit Test for this to prevent the -ive wealth and gini coefficent > 1
      set-initial-turtle-vars
  ]
end
;; this procedure recomputes the value of gini-index-reserve
;; and the points in lorenz-points for the Lorenz and Gini-Index plots
to update-lorenz-and-gini
  let sorted-wealths sort [wealth] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set lorenz-points []

  ;; plot the Lorenz curve
  ;; calculate the Gini index.
  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve
      gini-index-reserve +
      (index / num-people) -
      (wealth-sum-so-far / total-wealth)
  ]
end


; Copyright 1998 Uri Wilensky.
@#$#@#$#@
GRAPHICS-WINDOW
185
10
675
501
-1
-1
9.451
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
12
233
88
266
setup
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

BUTTON
96
233
175
266
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
7
47
175
80
max-vision
max-vision
1
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
7
12
175
45
num-people
num-people
2
1200
500.0
1
1
NIL
HORIZONTAL

SLIDER
8
159
176
192
percent-best-land
percent-best-land
5
25
15.0
1
1
%
HORIZONTAL

SLIDER
8
118
176
151
life-expectancy-max
life-expectancy-max
1
100
90.0
1
1
NIL
HORIZONTAL

PLOT
861
10
1086
183
Class Plot
Time
Turtles
0.0
50.0
0.0
250.0
true
true
"set-plot-y-range 0 num-people" ""
PENS
"low" 1.0 0 -2674135 true "" "plot count turtles with [color = red]"
"mid" 1.0 0 -10899396 true "" "plot count turtles with [color = green]"
"up" 1.0 0 -13345367 true "" "plot count turtles with [color = blue]"

SLIDER
9
195
177
228
num-grain-grown
num-grain-grown
1
15
15.0
1
1
NIL
HORIZONTAL

SLIDER
7
83
175
116
life-expectancy-min
life-expectancy-min
1
100
55.0
1
1
NIL
HORIZONTAL

PLOT
861
339
1087
519
Class Histogram
Classes
Turtles
0.0
3.0
0.0
250.0
false
false
"set-plot-y-range 0 num-people" ""
PENS
"default" 1.0 1 -2674135 true "" "plot-pen-reset\nset-plot-pen-color red\nplot count turtles with [color = red]\nset-plot-pen-color green\nplot count turtles with [color = green]\nset-plot-pen-color blue\nplot count turtles with [color = blue]"

PLOT
1294
340
1493
520
Lorenz Curve
Pop %
Wealth %
0.0
100.0
0.0
100.0
false
true
"" ""
PENS
"lorenz" 1.0 0 -2674135 true "" "plot-pen-reset\nset-plot-pen-interval 100 / num-people\nplot 0\nforeach lorenz-points plot"
"equal" 100.0 0 -16777216 true "plot 0\nplot 100" ""

PLOT
1090
340
1290
520
Gini-Index v. Time
Time
Gini
0.0
50.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot (gini-index-reserve / num-people) / 0.5"

MONITOR
938
628
1080
673
NIL
sum [wealth] of turtles
3
1
11

INPUTBOX
763
503
846
563
initial-wealth
10.0
1
0
Number

TEXTBOX
17
342
179
370
Consumption Rates by each social class 
11
0.0
1

SLIDER
6
375
178
408
poor-consumption
poor-consumption
0
100
82.0
1
1
%
HORIZONTAL

SLIDER
6
412
178
445
mid-consumption
mid-consumption
0
100
57.0
1
1
%
HORIZONTAL

SLIDER
6
449
178
482
rich-consumption
rich-consumption
0
100
32.0
1
1
%
HORIZONTAL

MONITOR
937
534
1080
579
NIL
median [wealth] of turtles
17
1
11

MONITOR
937
581
1079
626
NIL
max [wealth] of turtles
17
1
11

MONITOR
1295
600
1459
645
NIL
sum [income] of turtles
17
1
11

INPUTBOX
7
272
93
332
gdp-growth-max
0.0
1
0
Number

INPUTBOX
95
272
179
332
gdp-growth-min
0.0
1
0
Number

PLOT
1091
187
1291
337
GDP-growth %
gdp-growth
NIL
-4.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot gdp-growth * 100\n"

PLOT
1089
10
1289
183
Total Wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [wealth] of turtles"

PLOT
1293
10
1493
183
Median Income
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if not empty? [ income ] of turtles [\nplot median [income] of turtles ]"

SWITCH
681
14
851
47
enable-edu
enable-edu
0
1
-1000

TEXTBOX
683
51
833
69
Education Rate based on class\n
11
0.0
1

MONITOR
1086
586
1259
631
NIL
max [ vision ] of turtles
5
1
11

MONITOR
1086
633
1259
678
NIL
min [ vision ] of turtles
5
1
11

SLIDER
680
69
852
102
poor-ed-max
poor-ed-max
0
100
50.0
25
1
NIL
HORIZONTAL

SLIDER
680
104
852
137
mid-ed-max
mid-ed-max
25
100
75.0
25
1
NIL
HORIZONTAL

SLIDER
680
139
852
172
rich-ed-max
rich-ed-max
50
100
100.0
25
1
NIL
HORIZONTAL

SLIDER
9
583
181
616
poor-vision-max
poor-vision-max
0
max-vision
2.0
1
1
NIL
HORIZONTAL

SLIDER
8
509
180
542
rich-vision-max
rich-vision-max
0
max-vision
6.0
1
1
NIL
HORIZONTAL

SLIDER
9
546
181
579
mid-vision-max
mid-vision-max
0
max-vision
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
10
490
160
508
Class Based Vision\n
11
0.0
1

MONITOR
1293
536
1457
581
NIL
mean [ education ] of turtles
17
1
11

MONITOR
1294
648
1458
693
NIL
median [ income ] of turtles
17
1
11

TEXTBOX
562
511
691
529
Inheritance Tax
11
0.0
1

SLIDER
557
599
716
632
inheritance-threshold
inheritance-threshold
80
140
140.0
10
1
NIL
HORIZONTAL

SWITCH
558
526
715
559
enable-inheritance-tax
enable-inheritance-tax
1
1
-1000

TEXTBOX
1342
193
1492
211
Wealth
11
0.0
1

TEXTBOX
1090
572
1129
590
Vision\n
11
0.0
1

TEXTBOX
1296
585
1363
613
Income\n\n
11
0.0
1

TEXTBOX
1296
522
1446
540
Education\n
11
0.0
1

TEXTBOX
396
639
526
667
Flat-Tax for inheritance
11
0.0
1

SWITCH
558
563
715
596
enable-flat-inh
enable-flat-inh
1
1
-1000

SLIDER
394
653
545
686
flat-inh-tax
flat-inh-tax
20
50
50.0
5
1
NIL
HORIZONTAL

TEXTBOX
392
511
568
539
Progressive Tax for inheritance\n
11
0.0
1

SLIDER
391
529
538
562
max-prog-inh-tax
max-prog-inh-tax
0
50
50.0
5
1
NIL
HORIZONTAL

SLIDER
391
564
538
597
no-tax-slabs
no-tax-slabs
2
6
6.0
1
1
NIL
HORIZONTAL

SLIDER
391
600
542
633
highest-thres-max-wealth
highest-thres-max-wealth
5
13
5.0
1
1
NIL
HORIZONTAL

PLOT
1295
186
1494
336
Inheritance Tax Collection
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot inheritance-tax-collection"

TEXTBOX
221
504
371
522
Income Tax
11
0.0
1

SWITCH
205
523
378
556
enable-prog-tax
enable-prog-tax
1
1
-1000

SLIDER
205
559
378
592
top-income-tax-rate
top-income-tax-rate
30
60
48.0
1
1
NIL
HORIZONTAL

SLIDER
205
595
379
628
bottom-income-tax-rate
bottom-income-tax-rate
5
30
20.0
1
1
NIL
HORIZONTAL

SLIDER
206
631
379
664
income-tax-threshold
income-tax-threshold
0.75
2
1.35
.2
1
NIL
HORIZONTAL

SLIDER
206
701
379
734
no-income-tax-slabs
no-income-tax-slabs
1
8
5.0
1
1
NIL
HORIZONTAL

SLIDER
205
665
378
698
max-bracket
max-bracket
5
11
5.0
0.2
1
NIL
HORIZONTAL

PLOT
860
186
1087
336
income-tax-collection
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot income-tax-collection"

SWITCH
731
591
867
624
minimum-wage
minimum-wage
1
1
-1000

SLIDER
727
627
927
660
min-wage-rate-percent-for-median
min-wage-rate-percent-for-median
30
70
42.0
2
1
NIL
HORIZONTAL

SWITCH
676
340
856
373
enable-consumption-rebate
enable-consumption-rebate
1
1
-1000

SLIDER
677
378
862
411
consumption-tax-rates-percent
consumption-tax-rates-percent
0
40
26.0
1
1
NIL
HORIZONTAL

SLIDER
676
413
863
446
poor-rebate
poor-rebate
0
70
50.0
5
1
NIL
HORIZONTAL

SLIDER
676
448
863
481
middle-rebate
middle-rebate
0
40
20.0
5
1
NIL
HORIZONTAL

TEXTBOX
727
569
916
597
Minimum Wage/Universal Basic Income\n
11
0.0
1

TEXTBOX
680
323
847
343
Consumption Rebate(Experiment)\n
11
0.0
1

MONITOR
1091
522
1204
567
gini-index-reserve
(gini-index-reserve / num-people) / 0.5
17
1
11

SWITCH
681
185
850
218
public-healthcare
public-healthcare
1
1
-1000

SLIDER
680
242
852
275
poor-healthcare-rate
poor-healthcare-rate
1
40
16.0
1
1
NIL
HORIZONTAL

SLIDER
680
279
854
312
mid-healthcare-rate
mid-healthcare-rate
1
35
11.0
1
1
NIL
HORIZONTAL

TEXTBOX
684
223
838
241
% expenditure for health care
11
0.0
1

@#$#@#$#@
## ABSTRACT

This project uses NetLogo and Sugarscape model to simulate the wealth distribution in a virtual world. The aim is to try introducing new concepts like taxation, rebates, education, minimum wage and healthcare and observe how it affects the wealth distribution in the society. 


## 1. Introduction

Wealth Inequality is defined as the unequal distribution of assets within a population. 
It is a major concern in today’s society and there are many complexities involved with understanding the wealth distribution. All over the world, we see a huge contrast in the living standards of the rich and the poor. There have been many attempts to simulate a virtual world and study how this inequality arises.
The objective of our project is to build on top of the NetLogo Wealth Distribution model (Wilensky,U.) and add various concepts that are known to reduce the wealth inequality if implemented properly.


## 2. Model Description (Overview)

The model description follows the ODD (Overview, Design concepts, Details) protocol for describing agent-based models (Grim et al). This model was implemented in NetLogo (Wilensky, 1999) and the base model used is NetLogo Wealth Distribution model available in the Models Library.

### 2.1 Purpose and Patterns

#### 2.1.1 Purpose
The main purpose of our model is to observe how the wealth distribution patterns can change by introducing progressive and flat inheritance tax, progressive income tax, tax rebates on consumer tax, Minimum wage and Education.

Level of abstraction:
*  Sugarscape model that shows the amount of grain and grain capacity in a patch. 
*  Vision determines how many patches ahead a turtle can see

Assumptions: 
*  No family structure or dependency; every individual earns for themselves 
*  Population of the society remains constant
*  Life expectancy
*  Number of grain grown in a patch
*  Consumption rates by each social class
*  Multiple people can harvest on a single patch, but grain distribution is based on education/vision. (Credit Suisse 2021 wealth Report)

#### 2.1.2 Patterns
The model will account for 
- Lorenz curve ( a graphical representation of income inequality or wealth inequality, developed by Max Lorenz 1905)
- Gini-Index vs Time ( a measure of statistical dispersion intended to represent the wealth inequality within a nation or social group, developed by statistician and sociologist Corrado Gini)

### 2.2 Entities, state variables, and scales
People have a random life expectancy between [slider values of] life-expectancy-min=55 and life-expectancy-max=90. Maximum value of metabolism in code is set as`metabolism-max = 25`.

#### People
age - Age of turtle [0 - life-expectancy] - unit: years
wealth- Amount of grain a person has 0 - (max-grain-here * life-expectancy)
metabolism - How much grain a person consumes in each tick. (0 - 25]
life-expectancy - Life expectancy of a person - [ 55 - 90 ]- unit:years
vision - How many patches ahead person can see - [0 - max vision] - unit:patches
income - Amount of grain a turtle collects from a patch - [0 - num-grain-grown]
consumption_ - Total consumption of turtle in a tick/year >0
bequest - A legacy that descendant receives >0
inheritance - Bequest after inheritance tax deduction >0
education - Education level of turtle {0, 25, 50, 75, 100}
		0-uneducated
		25-primary
		50-secondary
		75-tertiary
		100-graduate

#### Patches

grain-here - Grain present on that patch [0 - max-grain-here]
max-grain-here - Maximum amount of grain 
rich-turtle - No. of rich-turtles on this patch [0 - num-people]
poor-turtle - No. of poor people on this patch [0 - num-people]
mid-turtle - No. of middle-class people on this patch [0 - num-people]
highly-edu-turtle - No. of highly educated turtles on this patch[0 - num-people]
edu-turtle - No. of educated people on the patch [0 - num-people]
unedu-turtle - No. of uneducated people on this patch [0 - num-people]
rich-median-vision - Median of rich turtles vision on this patch [0-max vision] unit:patches
mid-median-visionMedian of middle class turtles vision on this patch
[0-maxPatches vision] unit:patches
high-edu-median-vision - Median of highly educated turtles vision on this patch.
[0-max vision] unit:patches
mid-edu-median-vision- Median of educated turtles vision on this patch
[0-max vision] unit:patches
max-grain - Maximum amount of grain any patch can hold [ 0 - num-grain-grown ]

### 2.3 Process overview and scheduling

Each tick (1 year), the following processes are processed in the given order

#### 2.3.1 set-initial-turtle-vars
	Age is set to 0. Will face randomly one of South, East, North, West. Life-expectancy, Metabolism, education and vision are set randomly in their range. Wealth is inherited from ancestors(can only happen when calling this function with ticks>1). If education is enabled, vision max range, for the class of person, is based on slider value `rich- mid- poor- vision-max`.

#### 2.3.2 turn-towards-grain
	Determine the direction which is most profitable for each turtle in the surrounding patches within the turles vision and face there.

#### 2.3.4 harvest-on-patch
	People earn income by harvesting grain-here on the patch it is standing on. Since our model can have multiple people on a patch, some form of distribution is needed among all persons. To make this distribution fair, when education is enabled, use `harvest-with-edu`. If education is not used, use `harvest-without-education`. 

#### 2.3.5 harvest-with-edu
Let x = highly-edu-turtle on this patch, y = edu-turtle on path, z = unedu-turtle on patch. Grain-here is distributed as following table

x>0, y>0, z>0  x : y : z : : 50 : 30 : 20
x>0, y=0, z>0  x : z : : 70 : 30
x>0, y>0, z=0  x : y : : 60 : 40

	In other cases, if only one of(x,y,z)>0, 100% of the grain is distributed among one class.


#### 2.3.6 harvest-without-edu
	Each person harvests the grain on its patch. If there are multiple turtles on a patch, with the same income-group, divide the grain evenly among the turtles of the same income group. Distribution of grain among income groups is as following table
	Let x = rich-turtles, y = mid-turtles, z = poor-turtles

x>0, y>0, z>0  x : y : z : : 50 : 30 : 20
x=0, y>0, z>0  y : z : : 60 : 40
x>0, y=0, z>0  x : z : : 70 : 30
x>0, y>0, z=0  x : y : : 60 : 40

#### 2.3.7 move-eat-age-die
	Move the person in whatever direction it is facing 1 step. Call consumption, increment age of person, call to collect income-tax. If the dying condition is met, reset variables. If inheritance tax is used in the model, call inheritance-tax.

#### 2.3.8 consumption
	Calculate consumption of a person based on social class, yearly expenditure on health-care (health-expenditure). This expenditure is deducted from wealth. If consumption-rebate is enabled, a small fraction of expenses are returned back.



#### 2.3.9 income-tax
	Progressive taxation is implemented. People every year(tick) give some fraction of income as tax

#### 2.3.10 inheritance-tax	
If ancestors' wealth crosses some threshold (inheritance-threshold), fraction of wealth goes as tax.

				
### 2.4 Design Concepts

#### 2.4.1 Basic Principles
	Model a mini artificial society using a sugarscape model. Each person has a vision and within the vision radius it can move to the maximum yielding patch. The harvesting of land is used as income in our model. The population survives on grains it has accumulated (wealth). We include real life taxing methods on income and try to observe how much these taxing methods decrease wealth distribution in society.
	
#### 2.4.2 Emergence
	Lorenz curve and gini-index values emerge from taxing, public spending and welfare schemes dynamics.
#### 2.4.3 Adaptation
People move to better yielding harvesting regions available to them every year. People's consumption, healthcare spending are  based on their income group. People with higher wealth are more likely to go for higher education.

#### 2.4.4 Learning
	Decisions are not adaptive.
#### 2.4.5 Prediction
	No predictions are made for the future in our model.
#### 2.4.6 Sensing
	Currently, agents only sense the maximum grain yielding patch in their vision. Use this information to face over that direction and move forward every tick.
	Future improvement: sensing can be used to figure out whether a patch is overpopulated and whether going to low yielding patch is better idea to have more grain itself (don’t have to distribute among many others)
#### 2.4.8 Interaction
	There is no direct interaction between agents. They do agree to share a bigger fraction of grain yields (income) to agents having higher education / wealth groups. 
#### 2.4.9 Stochasticity
	Randomness was used to account for randomness in real life. Randomness was used in setting initial variables like location of persons, education level, life-expectancy, vision (when enable-edu is disabled). Mostly we have used equally likely probability distribution, but setting variables like ‘education’ we have used normal distribution.
#### 2.4.10 Collectives
	Median wealth of the entire population is used as a benchmark of where other people stand in the wealth group. Based on individual wealth compared to aggregate median wealth, we color them. This color defines their social class. This class affects how much education they receive, consumption habits, what ratio of grain they harvest in a patch.
#### 2.4.11 Observation
	Observe how imposing these taxing methods & varying the tax rates
 reduce wealth inequality:
Progressive Tax on Income
Inheritance tax (both flat & progressive)
Observe how the implementing the following affect the wealth distribution:
Tax Rebates on Consumer Tax
Minimum wage
Public Healthcare
Education
	The results are displayed on [Interface, Plot] 
Lorenz Curve(closer to straight line means less inequality) and 
Gini-Index vs Time (Lower value displays less inequality).
### 2.5 Initialization
	Setup patches as field growing grains. 
	Setup turtles as people, having initial variables (age, wealth, life-expectancy, metabolism, vision)

Parameters used in model

### 2.6 Submodels

Recolor-patch: Patch is coloured in white shades based on the amount of grain present on the patch on comparing with the maximum amount of grain any patch can hold.
Recolor-turtles: if a turtle has less than one third of the wealth of the richest turtle, it is coloured red indicating poor class. If between one-third and two-third it is coloured as green indicating middle class. If more than two-third it is coloured blue indicating rich.
Initial-wealth-dist: initial wealth is distributed based on metabolism. Top 5% of turtles get 30%, the next 25% turtles get 35%, the next 40% get 25%, and the last 30% get 10% of total wealth.
Set-education: sets the education of the turtle based on social class. Initially takes one of the educations from the ed-level list and compares the education with its maximum education allowed in its social class. If the education level is greater than its max education then sets the education as max education.
Class-based-vision: sets the vision of the turtle based on social class of the turtle when enable-edu switch is disabled. This sets vision randomly from maximum vision accepted in its social class.
Set-vision: sets the vision of the turtle based on its education. If the turtle is educated upto primary (<=25 education) then its vision is set randomly in range of [1, max-vision/3]. If the turtle is educated upto secondary education (<=50 education) then its vision is set randomly in range of [2,  max-vision * 2 / 3]. Else the turtle is highly educated (>50 education) the vision is set randomly in range[5, 5+max-vision].
Flat-tax: First tax threshold is calculated based on median of wealth and turtle bequest then tax is calculated by imposing flat-tax percentage on obtained threshold and then the tax imposed is deducted from bequest to get inherited amount.
Progressive-tax: first tax payment percentage is calculated for each slab based on median tax then we find the slab to which the turtle belongs to and then collects the share of tax up to the turtle slab. And then the tax amount is deducted from the bequest.
Update-lorenz-and-gini: updates the Lorenz curve and Gini index for every tick.
2.7 Submodels
Recolor-patch: Patch is coloured in white shades based on the amount of grain present on the patch on comparing with the maximum amount of grain any patch can hold.
Recolor-turtles: if a turtle has less than one third of the wealth of the richest turtle, it is coloured red indicating poor class. If between one-third and two-third it is coloured as green indicating middle class. If more than two-third it is coloured blue indicating rich.
Initial-wealth-dist: initial wealth is distributed based on metabolism. Top 5% of turtles get 30%, the next 25% turtles get 35%, the next 40% get 25%, and the last 30% get 10% of total wealth.
Set-education: sets the education of the turtle based on social class. Initially takes one of the educations from the ed-level list and compares the education with its maximum education allowed in its social class. If the education level is greater than its max education then sets the education as max education.
Class-based-vision: sets the vision of the turtle based on social class of the turtle when enable-edu switch is disabled. This sets vision randomly from maximum vision accepted in its social class.
Set-vision: sets the vision of the turtle based on its education. If the turtle is educated upto primary (<=25 education) then its vision is set randomly in range of [1, max-vision/3]. If the turtle is educated upto secondary education (<=50 education) then its vision is set randomly in range of [2,  max-vision * 2 / 3]. Else the turtle is highly educated (>50 education) the vision is set randomly in range[5, 5+max-vision].
Flat-tax: First tax threshold is calculated based on median of wealth and turtle bequest then tax is calculated by imposing flat-tax percentage on obtained threshold and then the tax imposed is deducted from bequest to get inherited amount.
Progressive-tax: first tax payment percentage is calculated for each slab based on median tax then we find the slab to which the turtle belongs to and then collects the share of tax up to the turtle slab. And then the tax amount is deducted from the bequest.
Update-lorenz-and-gini: updates the Lorenz curve and Gini index for every tick.

## 3.Results
	
### 3.1 Model Testing






## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
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
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225
@#$#@#$#@
0
@#$#@#$#@
