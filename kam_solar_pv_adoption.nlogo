extensions
  [
    csv
    matrix
    rnd
    nw
  ]

globals
 [
   setup-complete?

   ; SURVEY DATA
   person-survey-file ; survey file
   opinions-PV-list ; list of opinions of PV owners in survey


   ; THRESHOLD VALUES FOR ADOPTION
   threshold-PV-owner
   threshold-PV-tenant


   ; TECHNOLOGICAL CHARACTERISTICS
   ; price
   ; PV
   learning-rate-PV ; the PV learning rate is 0.04 in the standard scenario
   price-PV ; price of a PV solar panel before subsidy reduction
   price-net-PV ; price of a PV solar panel after subsidy reduction
   price-min-PV ; minimum price of a PV solar panel
   price-start-PV ; price at start of simulation, used for calculations

   ; life cycle greenhouse gas emissions
   ; PV: learning rate is 0.02 in the standard scenario
   life-cycle-ghg-PV ; life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
   life-cycle-ghg-PV-min ; minimum life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]


  ; co-adoption global variables
  co-adoption-PV


  ; adoption 2030/250 variables for sensitivity analysis
  pv-adoption-2012
  pv-adoption-2022


  ; adoption lists, these lists keep a record for at which time step an agent adopted a technology, relevant for the output files of the experiments
  adoption-PV-id-list

 ]

breed [ houses house ]
breed [ persons person ]
breed [ pv-solar-panels PV-solar-panel ]


undirected-link-breed [ neighbours neighbour ]


persons-own
 [
   ; SURVEY DATA
   person-survey-profile
   id-number

   ; GENERAL
   my-house ; house of the person
   owner? ; true if house owner, false if tennant


   ; SOCIAL NETWORK AND WORD-OF-MOUTH
   neighbours-meet-and-discuss ; how much does this person like to meet and discuss with its neighbours (scale 0-1)
   opinion-PV ; what is this persons opinion on PV systems after adopting one, it would be (1) neutral, (2) positive, (3) negative, or (4) mixed
   emotion-PV ; the emotions of this person about PV, one of the adoption decision factors

 ]

houses-own
 [
   ; GENERAL
   id-number ; ID number of house, same as person living here and owned technologies
;   house-type ; can be single family house (SFH) detached, SFH semi-detached, or MFH
;   rooftop-area ; rooftop area available for PV solar panels, determined by house type
   region ; whether the house is situated in an urban, suburban, or rural area
   historic? ; whether the house is classified as historic, and therefore not allowed to install a PV system under current Swiss regulation
   direct-light? ; whether the rooftop receives direct light during the day

   ; TECHNOLOGIES
   PV-solar-panel? ; whether this house has a PV solar panel installed

   ; ENERGY MANAGEMENT
   PV-self-sufficiency-potential-local ; PV self-sufficiency-potential can be increased by battery
  ]

pv-solar-panels-own
 [
   id-number ; id-number to link with house
 ]


patches-own [ ]

; INITIALIZATION FUNCTIONS

to setup
  clear-all
  set setup-complete? false ; the set-up starts

  resize-world -50 50 -50 50

  ; load data
  set-current-directory (word "..")
  set person-survey-file csv:from-file "C:/Users/noaom/MASTER THESIS MODELS/Model tryouts/Noa_trial_Lukas_files/data/surveyData.csv"

  ; We make some seperate lists from the data because we need them later
  set opinions-PV-list [ ]
  foreach range 8002 [ x -> set opinions-PV-list lput item 22 item x person-survey-file opinions-PV-list ]
  set opinions-PV-list remove "PVWoMowners" opinions-PV-list
  set opinions-PV-list remove " " opinions-PV-list


  ; create empty lists for keeping records of which persons adopt a technology when
  set adoption-PV-id-list []


  ; Rural areas are coloured green, suburban areas are coloured brown, urban areas are coloured light gray
  ; The number of patches defined as urban, suburban, and rural are set in a way that the density of persons corresponds to that of the density of dwellings in urban, suburban, and rural regions in Suisse Romande respectively
  ask patches [ set pcolor green ]
  ask patches with [ distance patch 0 0 <= 48 ] [ set pcolor gray + 2 ]
  ask patches with [ distance patch 0 0 <= 41 ] [ set pcolor gray ]

  ; set learning rates and prices
  set learning-rate-PV 0.04 ; learning rate in standard scenario
  set price-min-PV 5000 ; minimum price for a standard solar panels
  set price-start-PV 15000 ; used for calculations
  set price-PV price-start-PV  ; used for calculations
  set price-net-PV price-PV * ( 1 - subsidy_PV / 100 )

  ; set life cycle greenhouse gas emissions
  set life-cycle-ghg-PV 80 ; life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]
  set life-cycle-ghg-PV-min 40 ; minimum life cycle greenhouse gas emissions for PV solar panels [ g / kWh ]

  ; threshold values, estimated based on survey data
  set threshold-PV-owner 0.5
  set threshold-PV-tenant 0.45

  ; SENSITIVITY ANALYSIS
  ; in the sensitivity analysis we can test the impact of variations in certain variables on the model outcomes
  if sensitivity_analysis [
    set learning-rate-PV learning-rate-PV * ( sensitivity_learning_rate_PV / 100 )
    set price-min-PV price-min-PV * ( sensitivity_price_min_PV / 100 )
    set subsidy_PV subsidy_PV * ( sensitivity_subsidy_PV / 100 )
    set PV_net_bill_after_adoption ifelse-value ( PV_net_bill_after_adoption > 0 )
           [ PV_net_bill_after_adoption * ( sensitivity_PV_net_bill_after_adoption / 100 ) ]
           [ PV_net_bill_after_adoption * ( 2 - sensitivity_PV_net_bill_after_adoption / 100 ) ]
    set learning_rate_life_cycle_ghg_PV learning_rate_life_cycle_ghg_PV  * ( sensitivity_learning_rate_ghg_PV / 100 )
    set life-cycle-ghg-PV-min life-cycle-ghg-PV-min * ( sensitivity_min_ghg_PV / 100 )
    set number_of_neighbours round ( number_of_neighbours * ( sensitivity_number_of_neighbours / 100 ) )
    set PV_self_sufficiency_potential_global PV_self_sufficiency_potential_global * ( sensitivity_PV_self_sufficiency_potential / 100 )
  ]

  ; create houses
  create-houses households
    [
      set shape "house"
      set color gray
      set PV-self-sufficiency-potential-local PV_self_sufficiency_potential_global
      set PV-solar-panel? false
      ]

  ; create persons that live in a house
  ask houses [
      let house-id who
      hatch-persons 1 [
        set my-house myself ; house-id ; number that keeps track of which house a persons lives in
        set shape "person"
        set color white
        choose-person-profile
        ask house house-id [ set id-number [ id-number ] of myself ]
        initialize-person-profile
      ]
     ]

  ; social networks consist of neighbours, which are defined as the persons closest to oneself
  ask persons [ create-neighbours-with min-n-of number_of_neighbours other persons [ distance myself ] ]

  ; update global co-adoption indicators
  set co-adoption-PV count persons with [ [ PV-solar-panel? ] of my-house ]

  set setup-complete? true ; the set-up is now completed
  reset-ticks

end

to choose-person-profile
  ; choose random survey variables and betas from file, and make sure that every person has unique profiles
  let a random ( length person-survey-file - 1) + 1
    set person-survey-profile item a person-survey-file
    set person-survey-file remove-item a person-survey-file
  ; the person's ID number is the same as the respondent number
  set id-number item 0 person-survey-profile

end

to initialize-person-profile

  ; persons are owners or tennants of their houses
  ifelse item 1 person-survey-profile = 1 [ set owner? true ] [ set owner? false ]

  if item 2 person-survey-profile = "urban" [ move-to one-of patches with [ not any? persons-here and pcolor = gray ] ]
  if item 2 person-survey-profile = "suburban" [ move-to one-of patches with [ not any? persons-here and pcolor = gray + 2 ] ]
  if item 2 person-survey-profile = "rural" [ move-to one-of patches with [ not any? persons-here and pcolor = green ] ]
  ask my-house [ move-to myself ]

  ; house characteristics
  ifelse item 3 person-survey-profile = "Yes"
    [ ask my-house [ set historic? true ] ]
    [ ask my-house [ set historic? false ] ]
  ifelse item 4 person-survey-profile = "Yes"
    [ ask my-house [ set direct-light? true ] ]
    [ ask my-house [ set direct-light? false ] ]


  ; PV solar panels
  if item 10 person-survey-profile = 1
    [
      adopt-PV-solar-panel
      ; from owners in the survey we know their opinion on the technology

        set opinion-PV item 22 person-survey-profile
    ]


  ; persons have an emotion about the technologies
  set emotion-PV item 46 person-survey-profile

  ; persons have a certain fondness to meet and discuss with their neighbours, which is captured in the following variable (scale 0-1)
  ; this value can be increase by the policy stimulating social interaction

  set neighbours-meet-and-discuss min list ( ( item 26 person-survey-profile - 1 ) / 6 + stimulate_social_interaction ) 1


  ; Savings from solar PV

   set PV_net_bill_after_adoption 90

end

; RUN SIMULATION

to go
  ; UPDATES-START
  ; reset the lists for keeping records of which persons adopt a technology when
  set adoption-PV-id-list []


  ; keep track of adoption in 2012
  if ticks = 1 [
    ; keep track of adoption levels 2012 for sensitivity analysis
    set pv-adoption-2012 count pv-solar-panels


    print ( word "2012: PV solar panels: " count pv-solar-panels  )
  ]
  ; and 2022
  if ticks = 11 [
    ; keep track of adoption levels 2022 for sensitivity analysis
    set pv-adoption-2022 count pv-solar-panels

    print ( word "2022: PV solar panels: " count pv-solar-panels )
  ]

  ; update technological attributes; prices and life cycle ghg emissions
  ; to let persons update their subjective probability
  ; prices
    let price-PV-previous price-PV
    set price-PV max list ( price-PV * ( 1 - learning-rate-PV ) ) price-min-PV
    set price-net-PV price-PV * ( 1 - subsidy_PV / 100 )


  ; update life cycle GHG emissions
    let life-cycle-ghg-PV-previous life-cycle-ghg-PV
    set life-cycle-ghg-PV max list ( life-cycle-ghg-PV * ( 1 - learning_rate_life_cycle_ghg_PV ) ) life-cycle-ghg-PV-min


  ; INFORMATION CAMPAIGNS
  ; influence the emotions of persons
  if ticks = information_campaign_PV_year - 2022 [
    ask persons [ set emotion-PV min list ( max list ( emotion-PV + item 131 person-survey-profile ) 0 ) 1 ]
  ]

  ; STIMULATING SOCIAL INTERACTIONS
  ; Value is updated in case of any chances
  ask persons [

      set neighbours-meet-and-discuss min list ( ( item 26 person-survey-profile - 1 ) / 6 + stimulate_social_interaction ) 1
  ]

  ; ADOPTION DECISIONS

  ; persons without any barriers evaluate whether they buy PV
  ask persons with [
    ( owner? OR tenants_can_install ) and
    ( not [ historic? ] of my-house OR historic_houses_can_install_PV ) and
    [ direct-light? ] of my-house and
    not [ PV-solar-panel? ] of my-house ]
      [ evaluate-PV-solar-panel ]

  ; UPDATES-END
  ; update global co-adoption indicators
  set co-adoption-PV count persons with [ [ PV-solar-panel? ] of my-house ]

  tick

  if ticks = stop-after-x-years + 1 [ stop ]

end

; ADOPTION FUNCTIONS

to adopt-PV-solar-panel
  if [ PV-solar-panel? ] of my-house = false [
  ask my-house [
    set PV-solar-panel? true
    hatch-pv-solar-panels 1 [
      set shape "sun"
      set color yellow
      set size 0.5
      set heading 315
      forward 0.4
      set id-number [ id-number ] of myself
    ]
  ] ]

  ; persons that adopt after the initialisation randomly choose an opinion from the distribution results from the survey
     set opinion-PV one-of opinions-PV-list

  ; they send out new comments to their neighbours about the technologies
  ; depending on how much they discuss with their neighbours (variable neighbours-meet-and-discuss)
  ; and how old their technology is
  ; this influences the emotions of their neighbours about the relevant technologies
  if word_of_mouth [
    ; positive comments
    if opinion-PV = "PositiveFeedback" or opinion-PV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number_of_neighbours ) link-neighbors [
        set emotion-PV min list ( max list ( emotion-PV + item 131 person-survey-profile ) 0 ) 1 ]
      ]
    ; negative comments
    if opinion-PV = "NegativeFeedback" or opinion-PV = "MixedFeedback" [
      ask n-of ( round neighbours-meet-and-discuss * number_of_neighbours ) link-neighbors [
        set emotion-PV min list ( max list ( emotion-PV + item 132 person-survey-profile ) 0 ) 1 ]
      ]
   ]


end


; ADOPTION EVALUATION FUNCTIONS
	
to evaluate-PV-solar-panel
  ; evaluation model including all factors
  let pv-evaluation ( item 48 person-survey-profile  + ; Intercept
    item 49 person-survey-profile * ( price-net-PV / 1000 )  +  ; investment cost	
    item 50 person-survey-profile * ( -1 * PV_net_bill_after_adoption ) + ; net bill after investment
    item 51 person-survey-profile * life-cycle-ghg-PV + ; life-cycle greenhouse gas emissions
    item 52 person-survey-profile * [ PV-self-sufficiency-potential-local ] of my-house + ; self-sufficiency (can be increased by home battery)
    ( ifelse-value neighbourhood_effect [ item 53 person-survey-profile * ( count pv-solar-panels / count houses ) ][ 0 ] ) + ; neighbourhood effect
    item 54 person-survey-profile * item 27 person-survey-profile + ; subjective probability benefit savings
    item 55 person-survey-profile * item 28 person-survey-profile + ; subjective probability benefit independence
    item 56 person-survey-profile * item 28 person-survey-profile + ; subjective probability benefit environment
    item 57 person-survey-profile * item 30 person-survey-profile + ; subjective probability benefit collective action
    item 58 person-survey-profile * item 31 person-survey-profile + ; subjective probability risk high investment costs
    item 59 person-survey-profile * item 32 person-survey-profile + ; subjective probability risk low return on investment costs
    item 60 person-survey-profile * emotion-PV + ; emotions PV
    item 61 person-survey-profile * item 44 person-survey-profile + ; negative emotions climate change
    item 62 person-survey-profile * item 45 person-survey-profile  ; positive emotions climate change
)

  if ( 1 / (1 + exp( -1 * pv-evaluation ) ) ) >= ( ifelse-value owner? [ threshold-PV-owner ] [ threshold-PV-tenant ] )
      [ adopt-PV-solar-panel ]
end


; ADOPTION EVALUATION FUNCTIONS FOR BUNDLES
; they report a true/false value rather than triggering an adoption action
@#$#@#$#@
GRAPHICS-WINDOW
267
10
1151
895
-1
-1
8.68
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
7
13
259
46
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
6
50
69
83
NIL
go
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
78
52
141
85
NIL
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
5
113
255
146
households
households
0
8001
8001.0
1
1
NIL
HORIZONTAL

SLIDER
7
152
257
185
number_of_neighbours
number_of_neighbours
0
20
20.0
1
1
NIL
HORIZONTAL

PLOT
1164
280
1715
500
net prices
NIL
NIL
0.0
13.0
0.0
125000.0
true
true
"" ""
PENS
"PV" 1.0 0 -4079321 true "" "plot price-net-PV"

SWITCH
9
411
237
444
historic_houses_can_install_PV
historic_houses_can_install_PV
0
1
-1000

SWITCH
9
370
189
403
tenants_can_install
tenants_can_install
0
1
-1000

SLIDER
6
530
240
563
learning_rate_life_cycle_ghg_PV
learning_rate_life_cycle_ghg_PV
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
8
491
282
524
PV_net_bill_after_adoption
PV_net_bill_after_adoption
-1000
1000
90.0
1
1
EUR / year
HORIZONTAL

SLIDER
9
573
264
606
PV_self_sufficiency_potential_global
PV_self_sufficiency_potential_global
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
11
452
235
485
subsidy_PV
subsidy_PV
0
100
0.0
1
1
%
HORIZONTAL

INPUTBOX
153
47
258
107
stop-after-x-years
11.0
1
0
Number

SWITCH
10
202
195
235
neighbourhood_effect
neighbourhood_effect
0
1
-1000

SWITCH
13
240
195
273
word_of_mouth
word_of_mouth
0
1
-1000

PLOT
1163
10
1854
275
adoption
Year
Number_of_solar_panels
0.0
13.0
0.0
8001.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" "plot count pv-solar-panels"

SLIDER
12
616
243
649
information_campaign_PV_year
information_campaign_PV_year
2012
2023
2023.0
1
1
NIL
HORIZONTAL

PLOT
1724
282
1903
432
emotion PV
NIL
NIL
0.0
1.1
0.0
1500.0
true
false
"" ""
PENS
"PV" 0.1 1 -16777216 true "" "histogram [ emotion-PV ] of persons"

SLIDER
11
287
217
320
stimulate_social_interaction
stimulate_social_interaction
0
1
1.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
1184
712
1334
730
Sensitivity analysis
11
0.0
0

SLIDER
1170
776
1393
809
sensitivity_learning_rate_PV
sensitivity_learning_rate_PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1392
775
1593
808
sensitivity_price_min_PV
sensitivity_price_min_PV
0
200
102.0
1
1
%
HORIZONTAL

SLIDER
1424
855
1619
888
sensitivity_min_ghg_PV
sensitivity_min_ghg_PV
0
200
100.0
1
1
%
HORIZONTAL

SWITCH
1184
735
1351
768
sensitivity_analysis
sensitivity_analysis
1
1
-1000

SLIDER
1172
817
1362
850
sensitivity_subsidy_PV
sensitivity_subsidy_PV
0
200
100.0
1
1
%
HORIZONTAL

SLIDER
1365
816
1643
849
sensitivity_PV_net_bill_after_adoption
sensitivity_PV_net_bill_after_adoption
0
200
101.0
1
1
%
HORIZONTAL

SLIDER
1594
775
1850
808
sensitivity_number_of_neighbours
sensitivity_number_of_neighbours
0
200
109.0
1
1
%
HORIZONTAL

SLIDER
1640
816
1929
849
sensitivity_PV_self_sufficiency_potential
sensitivity_PV_self_sufficiency_potential
0
200
100.0
1
1
%
HORIZONTAL

SWITCH
1360
729
1519
762
replacement_time?
replacement_time?
1
1
-1000

SLIDER
1173
855
1423
888
sensitivity_learning_rate_ghg_PV
sensitivity_learning_rate_ghg_PV
0
200
100.0
1
1
%
HORIZONTAL

PLOT
1370
560
1570
710
Adoption2
Year
Number of solar Panels
2011.0
2022.0
0.0
8001.0
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count pv-solar-panels"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

computer workstation
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

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

electric outlet
false
0
Rectangle -7500403 true true 45 0 255 297
Polygon -16777216 false false 120 270 90 240 90 195 120 165 180 165 210 195 210 240 180 270
Rectangle -16777216 true false 169 199 177 236
Rectangle -16777216 true false 169 64 177 101
Polygon -16777216 false false 120 30 90 60 90 105 120 135 180 135 210 105 210 60 180 30
Rectangle -16777216 true false 123 64 131 101
Rectangle -16777216 true false 123 199 131 236
Rectangle -16777216 false false 45 0 255 296

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

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

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-price-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="-90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2022"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighours">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="66"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-price-min-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-subsidy-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-PV-net-bill-after-adoption" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-savings-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-PV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-learning-rate-ghg-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-number-of-neighbours" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-PV-self-sufficiency-potential" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-range-EV-increase" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-range-EV-max" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-replacement-time-heat-pump" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-neighbourhood-effect" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-word-of-mouth" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-bundle-bonus" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-savings-EV" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="67"/>
      <value value="133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main-sensitivity" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>pv-adoption-2030</metric>
    <metric>pv-adoption-2050</metric>
    <metric>ev-adoption-2030</metric>
    <metric>ev-adoption-2050</metric>
    <metric>heat-pump-adoption-2030</metric>
    <metric>heat-pump-adoption-2050</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="main-sensitivity-output-test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>count PV-solar-panels</metric>
    <metric>count EVs</metric>
    <metric>count heat-pumps</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity-replacement-time-at-all" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>adoption-PV-id-list</metric>
    <metric>adoption-EV-id-list</metric>
    <metric>adoption-heat-pump-id-list</metric>
    <metric>adoption-home-battery-id-list</metric>
    <enumeratedValueSet variable="households">
      <value value="1469"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-after-x-years">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-neighbours">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighbourhood-effect?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="word-of-mouth?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-PV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-EV">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="subsidy-heat-pump">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bundle-bonus">
      <value value="0"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-net-bill-after-adoption">
      <value value="90"/>
      <value value="-484"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV">
      <value value="&quot;low&quot;"/>
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-large">
      <value value="12.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-medium">
      <value value="10.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-EV-small">
      <value value="8.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="savings-heat-pump">
      <value value="2200"/>
      <value value="2800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-PV">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-EV">
      <value value="0"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate-life-cycle-ghg-heat-pump">
      <value value="0"/>
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stimulate-social-interaction">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tenants-can-install">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="historic-houses-can-install-PV">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PV-self-sufficiency-potential-global">
      <value value="0.2"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="range-EV-increase">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-PV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-EV-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-campaign-heat-pump-year">
      <value value="2051"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-analysis?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-number-of-neighbours">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-subsidy-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-bundle-bonus">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-price-min-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-net-bill-after-adoption">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-savings-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-learning-rate-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-PV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-EV">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-min-ghg-heat-pump">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-PV-self-sufficiency-potential">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-increase">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-range-EV-max">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sensitivity-replacement-time-heating-system">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-time?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-testing?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-prices">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-savings">
      <value value="&quot;high&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-GHG">
      <value value="&quot;low&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-EV-range">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenarios-opinions">
      <value value="&quot;PositiveFeedback&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-neighbours-meet-and-discuss">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extreme-scenario-information-campaign?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
