;;;;;************** TSUNAMI EVACUATION MODEL *********************;;;;
;;;;;                                                             ;;;;
;;;;; This model simulates a tsunami evacuation scenario with     ;;;;
;;;;; capability of adding vertical evaucation shelters and       ;;;;
;;;;; simulating transportation network damage and road closures. ;;;;
;;;;; This model is developed by Alireza Mostafizi and under      ;;;;
;;;;; direct supervision of Dr. Haihzong Wang, Dr. Dan Cox, and   ;;;;
;;;;; Dr. Lori Cramer from Oregon State University. Tsunami       ;;;;
;;;;; inundations are modeled by Dr. Hyoungsu Park. If you use    ;;;;
;;;;; this model to any extent, we ask you to cite our relevant   ;;;;
;;;;; publications listed in the Readme file of the repository.   ;;;;
;;;;;                                                             ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; EXTENSIONS ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [
  gis   ; the GIS extension is required to load the 1. transportation network
        ;                                           2. shelter locations
        ;                                       and 3. population distribution
  csv   ; the CSV extension is required to read the tsunami inundation file
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; BREEDS ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

breed [ residents resident]              ; the evacuees before they make it to the transportation network
breed [ pedestrians pedestrian ]         ; a resident will turn to a pedestrian (after they make it to the transportation network) if they decided to walk to the shelters
breed [ cars car ]                       ; a resident will turn to a car (after they make it to the transportation network) if they decided to drive to the shelters
breed [ intersections intersection ]     ; intersections are treated as agents
directed-link-breed [ roads road ]       ; roads are trated as directed links between the intersection (e.g, two directed links between a pair of intersections if the road is two-way)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; VARIABLES ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

patches-own [    ; the variables that patches own
  depth          ; current tsunami depth
  depths         ; sequence of tsunami depths over time
  max_depth      ; maximum depth of tsunami over time at the end of simulation
]

residents-own [  ; the variables that residents own
  init_dest      ; initial destination, the closest intersection to the agent at the start of simulation
  reached?       ; true if the agent is reached to the init_dest and ready to turn to pedestrian or car, false if not
  current_int    ; current/previous intersection of an agent, 0 if none
  moving?        ; true if the agent is moving, false if not
  evacuated?     ; true if an agent is evacuated, either in a shelter or outside of the shelter
  dead?          ; true if an agent is dead and caught by the tsunami
                 ; if the simulation is ended and the agent is not caught by the tsunami
  speed          ; speed of the agent, measured in patches per tick
  decision       ; the agents decision code: 1 for Hor Evac on foot
                 ;                           2 for Hor Evac by Car
                 ;                           3 for Ver Evac on foot
                 ;                           4 for Ver Evac by Car
  miltime        ; the agents milling time (preparation time before the evacuation starts) referenced from the earthquake
                 ; measureed in seconds
  time_in_water  ; time that the agent has been in the water in seconds
]

roads-own [      ; the variables that roads own
  crowd          ; number of people on foot on each link at any time
  traffic        ; number of cars on each link at any time
  mid-x          ; xcor of the middle point of a link, in patches
  mid-y          ; ycor of the middle point of a link, in patches
]

intersections-own [ ; the variables that intersections own
  shelter?          ; true if there is a shelter at an interseciton, flase if not
  shelter_type      ; string representing the type of the shelter, 'Hor' for horizontal
                    ;                                            , 'Ver' for vertical
  id                ; a unique id associated to each intersection (0 to number of intersections - 1)
  previous          ; for calculating the shortest path from each intersection to the a shelter (A* Alg)
  fscore            ; for calculating the shortest path from each intersection to the a shelter (A* Alg)
  gscore            ; for calculating the shortest path from each intersection to the a shelter (A* Alg)
  ver-path          ; best path from an intersection to the vertical shelter (list of intersection 'who's)
  hor-path          ; best path from an intersection to the horizontal shelter (list of intersection 'who's)
  evacuee_count     ; the number of agents that are evacuated in an intersection, if there is a shelter in it
]


pedestrians-own [; the variables that pedestrians own
  current_int    ; current/previous intersection of an agent, 0 if none
  shelter        ; 'who' of the intersection that the agent is heading to (its shelter)
                 ; -1 if there is none due to disconnectivity in the network
  next_int       ; the next intersection an agent is heading towards
  moving?        ; true if the agent is moving, false if not (e.g., turning at intersection)
  evacuated?     ; true if an agent is evacuated, either in a shelter or outside of the shelter
  dead?          ; true if an agent is dead and caught by the tsunami
  speed          ; speed of the agent, measured in patches per tick
  path           ; list of intersection 'who's that represent the path to the shelter of an agent
  decision       ; the agents decision code: 1 for Hor Evac on foot
                 ;                           3 for Ver Evac on foot
  time_in_water  ; time that the agent has been in the water in seconds
]

cars-own [       ; the variables that cars own
  current_int    ; current/previous intersection of an agent, 0 if none
  moving?        ; true if the agent is moving, false if not (e.g., turning at intersection)
  evacuated?     ; true if an agent is evacuated, either in a shelter or outside of the shelter
  dead?          ; true if an agent is dead and caught by the tsunami
  next_int       ; the next intersection an agent is heading towards
  shelter        ; 'who' of the intersection that the agent is heading to (its shelter)
  speed          ; speed of the agent, measured in patches per tick
  path           ; list of intersection 'who's that represent the path to the shelter of an agent
  decision       ; the agents decision code: 2 for Hor Evac by Car
                 ;                           4 for Ver Evac by Car
  car_ahead      ; the car that is immediately ahead of the agent
  space_hw       ; the space headway between the agent and 'car_ahead'
  speed_diff     ; the speed difference between the agent and 'car_ahead'
  acc            ; acceleration of the car agent
  road_on        ; the link that the car is travelling on
  time_in_water  ; time that the agent has been in the water in seconds
]

globals [        ; global variables
  ev_times       ; list of evacuation times (in mins) for all agents referenced from the earthquake
                 ; later to be used to look into the distribution of the evacuation times
  mouse-was-down?; event-handler variable to capture mouse clicks accurately
  road_network   ; contains the road network gis information
  population_distribution
                 ; contains population distribution gis information
  shelter_locations
                 ; contains shelter locations gis information

  tsunami_sample ; sample tsunami inundation wavefiled raster data

  tsunami_data_inc   ; the increements in seconds for the inundation data
  tsunami_data_start ; the start of the inundation data in seconds
  tsunami_data_count ; count of inunudaiton files

  tsunami_max_depth    ; maximum observed depth for color normalization
  tsunami_min_depth    ; minimum observed depth for color normalization


  mortality_rate ; mortality rate of the event

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;; CONVERSION RATIOS ;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  patch_to_meter ; patch to meter conversion ratio
  patch_to_feet  ; patch to feet conversion ratio
  fd_to_ftps     ; fd (patch/tick) to feet per second
  fd_to_mph      ; fd (patch/tick) to miles per hour
  tick_to_sec    ; ticks to seconds - usually 1

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;; TRANSFORMATIONS ;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  min_lon        ; minimum longitude that is associated with min_xcor
  min_lat        ; minimum latitude that is associated with min_ycor
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; HELPER FUNCTIONS ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; returns truen if the moouse was clicked
to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

; returns a list of intersections for which the shortest path to the closest shelter should be calculated
to-report find-origins
  let origins []
  ask residents [
    ; add the closest intersection to each agent at the start of the simulation to the origins
    ; there is no need to calculate the shortest path for the rest of the intersections
    set origins lput min-one-of intersections [ distance myself ] origins
  ]
  set origins remove-duplicates origins
  report origins
end

; generates a randomly drawn number from Rayleigh dist. with the given sigma
to-report rayleigh-random [sigma]
  report (sqrt((- ln(1 - random-float 1 ))*(2 *(sigma ^ 2))))
end

; TURTLE FUNCTION: sets random decision as to the mode (foot/car) and the shelter (horizontal/vertical) for the evaucation based on the percentages entered by the user
;                  in addition, it sets the appropriate milling time based on the decision and its corresponding Rayleigh dist. parameters entered by the user
to make-decision
  let rnd random-float 100
  ifelse (rnd < R1_HorEvac_Foot ) [
    set decision 1
    set miltime ((Rayleigh-random Rsig1) + Rtau1 ) * 60 / tick_to_sec
  ]
  [
    ifelse (rnd >= R1_HorEvac_Foot and rnd < R1_HorEvac_Foot + R2_HorEvac_Car ) [
      set decision 2
      set miltime ((Rayleigh-random Rsig2) + Rtau2 ) * 60 / tick_to_sec
    ]
    [
      ifelse (rnd >= R1_HorEvac_Foot + R2_HorEvac_Car and rnd < R1_HorEvac_Foot + R2_HorEvac_Car + R3_VerEvac_Foot ) [
        set decision 3
        set miltime ((Rayleigh-random Rsig3) + Rtau3 ) * 60 / tick_to_sec
      ]
      [
        if (rnd >= R1_HorEvac_Foot + R2_HorEvac_Car + R3_VerEvac_Foot and rnd < R1_HorEvac_Foot + R2_HorEvac_Car + R3_VerEvac_Foot + R4_VerEvac_Car ) [
          set decision 4
          set miltime ((Rayleigh-random Rsig4) + Rtau4 ) * 60 / tick_to_sec
        ]
      ]
    ]
  ]
end

; finds the shortest path from and intersection (source) to a shelter (one of gls) with A* algorithm
; gl is only used as a heuristic for the algorithm, the closest destination in a network is not necessarily the closest in euclidean distance
to-report Astar [ source gl gls ]
  let rchd? false       ; true if the algorithm has found a shelter
  let dstn nobody       ; the destinaton or the closest shelter
  let closedset []      ; equivalent to closed set in A* alg
  let openset []        ; equivalent to open set in A* alg
  ask intersections [   ; initialize "previous", which later will be used to reconstruct the shortest path for each intersection
    set previous -1
  ]
  set openset lput [who] of source openset  ; start the open set with the source intersection
  ask source [                              ; initialize g and f score for the source intersection
    set gscore 0
    set fscore (gscore + distance gl)
  ]
  while [ not empty? openset and (not rchd?)] [ ; while a destination hasn't been found, look for one
    let current Astar-smallest openset          ; pick the most promissing intersection from the open set
    if member? current  [who] of gls [          ; if it is one of the candid shelters, we're done
      set dstn intersection current             ; set the destination
      set rchd? true                            ; and toggle the flag so we don't look for a destination anymore and move on to the recosntructing the path
    ]
    set openset remove current openset          ; update the open and closed set
    set closedset lput current closedset
    ask intersection current [                  ; explore the neighbors of the current intersection
      ask out-road-neighbors [
        let tent_gscore [gscore] of myself + [link-length] of (road [who] of myself who)   ; update f and gscore tentatively
        let tent_fscore tent_gscore + distance gl
        if ( member? who closedset and ( tent_fscore >= fscore ) ) [stop]                  ; if not improved, stop
        if ( not member? who closedset or ( tent_fscore >= fscore )) [                     ; if the score improved, continue updating
          set previous current
          set gscore tent_gscore
          set fscore tent_fscore
          if not member? who openset [
            set openset lput who openset
          ]
        ]
      ]
    ]
  ]
  let route []                                    ; reconstruct the path to destination
  ifelse dstn != nobody [                         ; if there was a path
    while [ [previous] of dstn != -1 ] [          ; use "previous" to recosntruct untill "previous" is -1
      set route fput [who] of dstn route
      set dstn intersection ([previous] of dstn)
    ]
  ]
  [
    set route []                                  ; if there was no path, return an empty list
  ]
  report route
end

; returns the who of an intersection in who_list with the lowest fscore
to-report Astar-smallest [ who_list ]
  let min_who 0
  let min_fscr 100000000
  foreach who_list [ [?1] ->
    let fscr [fscore] of intersection ?1
    if fscr < min_fscr [
      set min_fscr fscr
      set min_who ?1
    ]
  ]
  report min_who
end

; TURTLE FUNCTION: calculates the speed of the car based on general motors car-following model
;                  it incorporates the speed of the leading car as well as the space headway
to move-gm
  set car_ahead cars in-cone (150 / patch_to_feet) 20                                        ; get the cars ahead in 150ft (almost half a block) and in field of view of 20 degrees
  set car_ahead car_ahead with [self != myself]                                              ; that are not myself
  set car_ahead car_ahead with [not evacuated?]                                              ; that have not made it to the shelter yet (no congestion at the shelter)
  set car_ahead car_ahead with [not dead?]                                                   ; that have not died yet
  set car_ahead car_ahead with [moving?]                                                     ; that are moving
  set car_ahead car_ahead with [abs(subtract-headings heading [heading] of myself) < 160]    ; with relatively the same general heading as mine (not going the opposite direction)
  set car_ahead car_ahead with [distance myself > 0.0001]                                    ; not exteremely close to myself
  set car_ahead min-one-of car_ahead [distance myself]                                       ; and the closest car ahead
  ifelse is-turtle? car_ahead [                                                              ; if there IS a car ahead:
    set space_hw distance car_ahead                                                          ; the space headway with the leading car
    set speed_diff [speed] of car_ahead - speed                                              ; the speed difference with the leadning car
    ifelse space_hw < (6 / patch_to_feet) [set speed 0]                                      ; if the leading car is less than ~6ft away, stop
    [                                                                                        ; otherwise, find the acceleration based on the general motors car-following model
      set acc (alpha / fd_to_mph * 5280 / patch_to_feet) * ((speed) ^ 0) / ((space_hw) ^ 2) * speed_diff
                                                                                             ; converting mi2/hr to patch2/tick = converting mph*mi to fd*patch
                                                                                             ; m = speed componnent = 0 / l = space headway component = 2
      set speed speed + acc                                                                  ; update the speed
    ]
    if speed > (space_hw - (6 / patch_to_feet)) [                                            ; if the current speed will put the car less than 6ft away from the leading car in the next second,
      set speed min list (space_hw - (6 / patch_to_feet)) [speed] of car_ahead               ; reduce the speed in a way to not get closer to the leading car
    ]
    if speed > (max_speed / fd_to_mph) [set speed (max_speed / fd_to_mph)]                   ; cap the speed to max speed if larger
    if speed < 0 [set speed 0]                                                               ; no negative speed
  ]
  [                                                                                          ; if ther IS NOT a car ahead:
    if speed < (max_speed / fd_to_mph) [set speed speed + (acceleration / fd_to_ftps * tick_to_sec)]
                                                                                             ; accelerate to get to the speed limit
    if speed > max_speed / fd_to_mph [set speed max_speed / fd_to_mph]                       ; cap the speed to max speed if larger
  ]

  if speed > distance next_int [set speed distance next_int]                                 ; avoid jumping over the next intersection the car is heading to
end

; TURTLE FUNCTION: marks an agent as evacuee
to mark-evacuated
  if not evacuated? and not dead? [                              ; if the agents is not dead or evacuated, mark it as evacuated and set proper characteristics
    set color green
    set moving? false
    set evacuated? true
    set dead? false
    set ev_times lput ( ticks * tick_to_sec / 60 ) ev_times      ; add the evacuees evacuation time (in minutes) to ev_times list
    ask current_int [set evacuee_count evacuee_count + 1]        ; increment the evacuee_count of the shelter the agent evacuated to
  ]
end

; TURTLE FUNCTION: marks an agent as dead
to mark-dead                                                     ; mark the agent dead and set proper characteristics
  set color red
  set moving? false
  set evacuated? false
  set dead? true
end

; returns true if the general direction (north, east, south, west) and the heading (0 <= h < 360) are alligned
; used for removing one-way roads
to-report is-heading-right? [link_heading direction]
  if direction = "north" [ if abs(subtract-headings 0 link_heading) <= 90 [report true]]
  if direction = "east" [ if abs(subtract-headings 90 link_heading) <= 90 [report true]]
  if direction = "south" [ if abs(subtract-headings 180 link_heading) <= 90 [report true]]
  if direction = "west" [ if abs(subtract-headings 270 link_heading) <= 90 [report true]]
  report false
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SETUP INITIAL PARAMETERS ;:;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this function sets some initial value for an initial try to run the model
; if the user decides not to tweak any of the inputs
to setup-init-val
  set immediate_evacuation False  ; agents do not start evacuation immediately, instead they follow a Rayleigh distribution for their milling time
  set R1_HorEvac_Foot 25          ; 25% of the agents evacuate horizontally on foot
  set R2_HorEvac_Car 25           ; 25% of the agents evacuate horizontally with their car
  set R3_VerEvac_Foot 25          ; 25% of the agents evacuate on foot and are open to vertical evaucation if it is closer to them compared to a shelter outside the inundation zone
  set R4_VerEvac_Car 25           ; 25% of the agents evacuate with their car and are open to vertical evaucation if it is closer to them compared to a shelter outside the inundation zone
  set Hc 1.0                      ; the critical wave height that marks the threshold of casualties is set to 1.0 meter
  set Tc 120                      ; the time it takes for the inundation above Hc to kill an agent (seconds)
  set Ped_Speed 4                 ; the mean of the normal dist. that the walking speed of the agents are drawn from is set to 4 ft/s
  set Ped_Sigma 0.65              ; the standard deviation of the normal dist. that the walking speed of the agents are drawn from is set to 0.65 ft/s
  set max_speed 35                ; maximum driving speed is set to 35 mph
  set acceleration 5              ; acceleration of the vehicles is set to 5 ft/s2
  set deceleration 25             ; deceleration of the vehicles is set to 25 ft/s2
  set alpha 0.14                  ; alpha parameter of the car-following model is set to 0.14 mi2/hr (free-flow speed = 35 mph & jam density = 250 veh/mi/lane)
  set Rtau1 10                    ; minimum milling time for all decision categories is set to 10 minutes
  set Rtau2 10
  set Rtau3 10
  set Rtau4 10
  set Rsig1 1.65                  ; the scale factor parameter of the Rayleigh distribution for all decision categories is set to 1.65
  set Rsig2 1.65                  ; meaning that 99% of the agents evacuate within 5 minutes after the minimum milling time (between 10 to 15 mins in this case)
  set Rsig3 1.65
  set Rsig4 1.65
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; READ GIS FILES ;:;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; read the gis files that are used to populate the model:
;   1. road_network that contains the transportation network data
;   2. shelter_locations that contains the location of the horizontal and vertical shelters
;   3. population_distribution that contains the coordinates of the agents immediately before the evacuation
to read-gis-files
  gis:load-coordinate-system "road_network/road_network.prj"                                          ; load the projection system - WGS84 / UTM (METER) for your specific area
  set shelter_locations gis:load-dataset "shelter_locations/shelter_locations.shp"                    ; read shelter locations
  set road_network gis:load-dataset "road_network/road_network.shp"                                   ; read road network
  set population_distribution gis:load-dataset "population_distribution/population_distribution.shp"  ; read population distribution
  set tsunami_sample gis:load-dataset "tsunami_inundation/sample.asc"                                 ; just a sample inunudation wavefield to get the envelope (TODO: can be fixed later)
  let world_envelope (gis:envelope-union-of (gis:envelope-of road_network)                                ; set the real world bounding box the union of all the read shapefiles
                                            (gis:envelope-of shelter_locations)
                                            (gis:envelope-of population_distribution)
                                            (gis:envelope-of tsunami_sample))
  let netlogo_envelope (list (min-pxcor + 1) (max-pxcor - 1) (min-pycor + 1) (max-pycor - 1))             ; read the size of netlogo world
  gis:set-transformation (world_envelope) (netlogo_envelope)                                              ; make the transformation from real world to netlogo world
  let world_width item 1 world_envelope - item 0 world_envelope                                           ; real world width in meters
  let world_height item 3 world_envelope - item 2 world_envelope                                          ; real world height in meters
  let world_ratio world_height / world_width                                                              ; real world height to width ratio
  let netlogo_width (max-pxcor - 1) - ((min-pxcor + 1))                                                   ; netlogo width in patches (minus 1 patch padding from each side)
  let netlogo_height (max-pycor - 1) - ((min-pycor + 1))                                                  ; netlogo height in patches (minus 1 patch padding from each side)
  let netlogo_ratio netlogo_height / netlogo_width                                                        ; netlogo height to width ratio
  ; calculating the conversion ratios
  set patch_to_meter max (list (world_width / netlogo_width) (world_height / netlogo_height))             ; patch_to_meter conversion multiplier
  set patch_to_feet patch_to_meter * 3.281     ; 1 m = 3.281 ft                                           ; patch_to_feet conversion multiplier
  set tick_to_sec 1.0                                                                                     ; tick_to_sec ratio is set to 1.0 (preferred)
  set fd_to_ftps patch_to_feet / tick_to_sec                                                              ; patch/tick to ft/s speed conversion multipler
  set fd_to_mph  fd_to_ftps * 0.682            ; 1ft/s = 0.682 mph                                        ; patch/tick to mph speed conversion multiplier
  ; to calculate the minimum longitude and latitude of the world associated with min_xcor and min_ycor
  ; we need to check and see how the world envelope fits into that of netlogo's. This is why the "_ratio"s need to be compared againsts eachother
  ; this is basically the missing "get-transformation" premitive in netlogo's GIS extension
  ifelse world_ratio < netlogo_ratio [
    set min_lon item 0 world_envelope - patch_to_meter
    set min_lat item 2 world_envelope - ((netlogo_ratio - world_ratio) / netlogo_ratio / 2) * netlogo_height * patch_to_meter - patch_to_meter
  ][
    set min_lon item 0 world_envelope - ((world_ratio - netlogo_ratio) / world_ratio / 2) * netlogo_width * patch_to_meter - patch_to_meter
    set min_lat item 2 world_envelope - patch_to_meter
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; LOAD NETWORK ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; loads the transportation network, consisting of roads and intersections from "road_network" gis files
; that are places under "road_network" directroy. Note the "direction" attribute associated with each road
; which can either be "two-way" "north" "east" "south" or "west".
to load-network
  ; first remove the intersections and roads, if any
  ask intersections [die]
  ask roads [die]
  ; start loading the network
  foreach gis:feature-list-of road_network [ i ->                                      ; iterating through features to create intersections and roads
    let direction gis:property-value i "DIRECTION"                                     ; get the direction of the link to make either a one- or two-way road
    foreach gis:vertex-lists-of i [ j ->                                               ; iterating through the list of vertex lists (usually lengths of 1) of each feature
      let prev -1                                                                      ; previous vertex indicator, -1 if None
      foreach j [ k ->                                                                 ; iterating through the vertexes
        if length ( gis:location-of k ) = 2 [                                          ; check if the vertex is valid with both x and y values
          let x item 0 gis:location-of k                                               ; get x and y values for the intersection
          let y item 1 gis:location-of k
          let curr 0
          ifelse any? intersections with [xcor = x and ycor = y][                      ; check if there is an intersection here, if not, make one, and if it is, use it
            set curr [who] of one-of intersections with [xcor = x and ycor = y]
          ][
            create-intersections 1 [
              set xcor x
              set ycor y
              set shelter? false
              set size 0.1
              set shape "square"
              set color white
              set curr who
            ]
          ]
          if prev != -1 and prev != curr [                                             ; if this intersection is not the starting intersection, make roads
            ifelse direction = "two-way" [                                             ; if the road is "two-way" make both directions
              ask intersection prev [create-road-to intersection curr]
              ask intersection curr [create-road-to intersection prev]
            ][                                                                         ; if not, make only the direction that matches the direction requested, see is-heading-right? helper function
              if is-heading-right? ([towards intersection curr] of intersection prev) direction [ ask intersection prev [create-road-to intersection curr]]
              if is-heading-right? ([towards intersection prev] of intersection curr) direction [ ask intersection curr [create-road-to intersection prev]]
            ]
          ]
          set prev curr
        ]
      ]
    ]
  ]
  ; assign mid-x and mid-y variables to the roads that respresent the middle point of the link
  ask roads [
    set color black
    set thickness 0.05
    set mid-x mean [xcor] of both-ends
    set mid-y mean [ycor] of both-ends
    set traffic 0
    set crowd 0
  ]
  output-print "Network Loaded"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; LOAD SHELTERS ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; loads the shelters from from "shelter_locations" gis files that are under "shelter_locations" directory
; note the "type" attribute associated with each shelter in the gis file, which can either be "hor" or "ver"
; for horizontal and vertical shelters.
to load-shelters
  ; remove all the shelters before loading them
  ask intersections [
    set shelter? false
    set shelter_type "None"
    set color white
    set size 0.1
  ]
  ; start loading the shelters
  foreach gis:feature-list-of shelter_locations [ i ->     ; iterate through the shelters
    let curr_shelter_type gis:property-value i "TYPE"      ; get the type of the shelter
    foreach gis:vertex-lists-of i [ j ->
      foreach j [ k ->
        if length ( gis:location-of k ) = 2 [              ; check if the vertex has both x and y
          let x item 0 gis:location-of k
          let y item 1 gis:location-of k
          ask min-one-of intersections [distancexy x y][   ; turn the closest intersection to (x,y) to a shelter
            set shelter? true
            set shape "circle"
            set size 4
            if curr_shelter_type = "hor" [                 ; assign proper type based on "curr_shelter_type"
              set shelter_type "Hor"
              set color yellow
            ]
            if curr_shelter_type = "ver" [
              set shelter_type "Ver"
              set color violet
            ]
            st
          ]
        ]
      ]
    ]
  ]
  output-print "Shelters Loaded"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; LOAD TSUNAMI DATA ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; loads the tsunami inundation data from the flowdepth raster files under "tsunami_inundation" directory
; the details of inundation data (e.g., the increment, start, and data count) are read from "details.txt"
; if no tsunami data is provided, this function writes the coordinate boundaries of the study area into
; "coordinate_boundaries.txt" so it can be used to create the flowdepths later on.

to load-tsunami
  ask patches [set depths []]
  file-close-all
  ifelse file-exists? "tsunami_inundation/details.txt" [
    file-open "tsunami_inundation/details.txt"
    set tsunami_data_start file-read
    set tsunami_data_inc file-read
    set tsunami_data_count file-read
    file-close
    let files n-values tsunami_data_count [i -> i * tsunami_data_inc + tsunami_data_start ]
    set tsunami_max_depth 0
    set tsunami_min_depth 9999
    foreach files [? ->
      ifelse file-exists? (word "tsunami_inundation/" ? ".asc") [
        let tsunami gis:load-dataset (word "tsunami_inundation/" ? ".asc")
        gis:apply-raster tsunami depth
        ask patches [
          if not ((depth <= 0) or (depth >= 0)) [   ; If NaN
            set depth 0
          ]
          if depth > tsunami_max_depth [set tsunami_max_depth depth]
          if depth < tsunami_min_depth [set tsunami_min_depth depth]
          set depths lput depth depths
        ]
      ]
      [
        output-print (word "File tsunami_inundation/" ? ".asc is missing!")
      ]
      ask patches [set depth 0]
    ]
    output-print "Tsunami Data Loaded"
  ]
  [
    ; if the tsunami data is not provided, save coordinate boundaires to "coordinate_boundaries.text"
    let file_name "tsunami_inundation/boundaries.txt"
    if file-exists? file_name [file-delete file_name]         ; if there already is a file, delete it and make a new one
    file-open file_name
    file-print "top left (lon,lat)"
    file-print (word min_lon "," (min_lat + (world-height * patch_to_meter)))
    file-print "bottom right (lon,lat)"
    file-print (word (min_lon + (world-width * patch_to_meter)) "," min_lat)
    file-close
    output-print "Bounrdaries coordinates are saved to tsunami_inundation/boundaries.txt"
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; BREAK LINKS ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; removes both directions of a link with a mouse click to the mid point of the link
to break-links
  let mouse-is-down? mouse-down?
  if mouse-clicked? and timer > 0.1 [
    reset-timer
    let lnk min-one-of roads [(mouse-xcor - mid-x) ^ 2 + (mouse-ycor - mid-y) ^ 2]
    let ints sort [both-ends] of lnk
    if is-link? road [who] of item 0 ints [who] of item 1 ints [
      ask road [who] of item 0 ints [who] of item 1 ints [die]
    ]
    if is-link? road [who] of item 1 ints [who] of item 0 ints [
      ask road [who] of item 1 ints [who] of item 0 ints [die]
    ]
    display
  ]
  set mouse-was-down? mouse-is-down?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; PICK VERTICAL SHELTERS ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; turns an intersection into a vertical evacuation shelter with a mouse click
to pick-verticals
  let mouse-is-down? mouse-down?
  if mouse-clicked? [
    ask min-one-of intersections [distancexy mouse-xcor mouse-ycor][
      set shelter? true
      set shelter_type "Ver"
      set shape "circle"
      set size 4
      set color violet
    ]
    display
  ]
  set mouse-was-down? mouse-is-down?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; LOAD POPULATION ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; loads the evacuees from "population_distribution" gis files that are located under "population_distribution" directroy
; this gis shapefile contains the coordinates of the evacuees at the start of the evacuation
to load-population
  ; remove any residents, cars, or pedestrians before loading the population
  ask residents [ die ]
  ask pedestrians [die]
  ask cars [die]
  ; start loading the population
  foreach gis:feature-list-of population_distribution [ i ->           ; iterate through the points in the features
    foreach gis:vertex-lists-of i [ j ->
      foreach j [ k ->
        if length ( gis:location-of k ) = 2 [                          ; check if the vertex has both x and y
          let x item 0 gis:location-of k
          let y item 1 gis:location-of k
          create-residents 1 [                                         ; create the agent
            set xcor x
            set ycor y
            set color brown
            set shape "dot"
            set size 2
            set moving? false                                          ; they agents are staionary at the beginning, before they start the evacuation
            set init_dest min-one-of intersections [ distance myself ] ; the first intersection an agent moves toward to
                                                                       ; to get to the transpotation network
            set speed random-normal Ped_Speed Ped_Sigma                ; walking speed is randomly drawn from a normal distribution
            set speed speed / fd_to_ftps                               ; turning ft/s to patch/tick
            if speed < 0.001 [set speed 0.001]                         ; if speed is too low, set it to very small non-zero value
            set evacuated? false                                       ; initialized as not evacuated
            set dead? false                                            ; initialized as not dead
            set reached? false                                         ; initialized as not reached the transportation network
            make-decision                                              ; sets the evacuation mode and shelter decision and the corresponding milling time
            if immediate_evacuation [                                  ; if immediate_evacuation is toggled on, set all the milling times to 0
              set miltime 0
            ]
          ]
        ]
      ]
    ]
  ]
  output-print "Population Loaded"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; LOAD ROUTES ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; calcualtes routes for the intersections that need the shortest path information to a shelter, not all the intersections
to load-routes
  let origins find-origins
  ask turtles with [member? self origins] [
    let goals intersections with [shelter? and shelter_type = "Hor"]
    set hor-path Astar self (min-one-of goals [distance myself]) goals ; hor-path definitely goes to a horizontal shelter
    set goals intersections with [shelter?]
    set ver-path Astar self (min-one-of goals [distance myself]) goals ; ver-path can go to either a vertical shelter or
                                                                       ; a horizontal shelter, depending on which one was closer
  ]
  output-print "Routes Calculated"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; LOAD 1/2 ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; first part of loading the model, including transportation network, shelters, and tsunami data
; before breaking roads and adding vertical shelters
to load1
  ca
  print (word "Foot %: " R1_HorEvac_Foot " - Speed ft/s: " Ped_Speed " - Miltime min: " Rtau1)
  ask patches [set pcolor white]
  set ev_times []
  read-gis-files
  load-network
  load-shelters
  load-tsunami
  reset-timer
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; LOAD 2/2 ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; second part of loading the model, including population distribution and the routes
; after breaking the roads and adding the vertical shelters
; calculating roads is based on the vertical shelters and current state of the roads
to load2
  load-population
  load-routes
  reset-ticks
end

;######################################
;*************************************#
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;*#
;;;;;;;;;;;;;    GO    ;;;;;;;;;;;;;;*#
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;*#
;*************************************#
;######################################

to go
  if int(((ticks * tick_to_sec) - tsunami_data_start) / tsunami_data_inc) = tsunami_data_count - 1 [stop]  ; stop after simulation all the flow depths
  ; update the tsunami depth every interval seconds
  if int(ticks * tick_to_sec) - tsunami_data_start >= 0 and
     (int(ticks * tick_to_sec) - tsunami_data_start) mod tsunami_data_inc = 0 [
    if int(((ticks * tick_to_sec) - tsunami_data_start) / tsunami_data_inc) < tsunami_data_count [
      ask patches with [depths != 0][
        set depth item int(((ticks * tick_to_sec) - tsunami_data_start) / tsunami_data_inc) depths   ; set the depth to the correct item of depths list (depending on the time)
        if depth > max_depth [                                ; monitor the maximum depth observed at each patch, for future use.
          set max_depth depth
        ]
      ]
    ]    ; recolor the patches based on the tsunami depth, the deeper the darker the shade of blue
    set tsunami_min_depth 0 ; TODO: Find a better scaling scheme - With this line, white maps to 0 m and balck to tsunami_max_depth
    ask patches [
      set pcolor scale-color blue depth tsunami_max_depth tsunami_min_depth
    ]
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;; RESIDENTS ;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; ask residents, if they milling time has passed, to start moving
  ask residents with [not moving? and not dead? and miltime <= ticks][
    set heading towards init_dest
    set moving? true
  ]
  ; ask residents that should be moving to move
  ask residents with [moving?][
    ifelse (distance init_dest < (speed) ) [fd distance init_dest][fd speed]
    if distance init_dest < 0.005 [   ; if close enough to the next intersection, move the agent to it
      move-to init_dest
      set moving? false
      set reached? true
      set current_int init_dest
    ]
  ]
  ; check the residnet that are on the way if they have been caught by the tsunami
  ask residents with [not reached?][
    if [depth] of patch-here > Hc [ set time_in_water time_in_water + tick_to_sec ]
  ]
  ; ask residets who have reached the network to hatch into a pedestrian or a car depending on their decision
  ask residents with [reached?][
    let spd speed                ; to pass on the spd from resident to the hatched pedestrian
    let dcsn decision            ; to pass on the decision from the resident to either car or pedestrian
    if dcsn = 1 or dcsn = 3 [    ; horizontal (1) or vertical (3) evacuation - by FOOT
      ask current_int [          ; ask the current intersection of the resident to hatch a pedestrian
        hatch-pedestrians 1 [
          set size 2
          set shape "dot"
          set current_int myself ; myself = current_int of the resident
          set speed spd          ; the speed of the resident is passed on to the pedestrian
          set evacuated? false   ; initialized as not evacuated, will be checked immediately after being born
          set dead? false        ; initialized as not dead, will be checked immediately after being born
          set moving? false      ; initialized as not moving, will start moving immediately after if not evacuated and not dead
          if dcsn = 1 [          ; horizontal evacuation on foot
            set color orange
            set path [hor-path] of myself ; myself = current_int of the resident - Note that intersection hold the path infomration
                                          ; which passed to the pedestrians and cars
            set decision 1
          ]
          if dcsn = 3 [          ; vertical evacuation on foot
            set color turquoise
            set path [ver-path] of myself ; myself = current_int of the resident - Note that intersection hold the path infomration
                                          ; which passed to the pedestrians and cars
            set decision 3
          ]
          ifelse empty? path [set shelter -1][set shelter last path] ; if path list is not empty the who of the shelter is the last item of the path
                                                                     ; otherwise, there is no shelter destination, either the current_int is the shelter
                                                                     ; or due to network disconnectivity, there were no path available to any of the shelters
          if shelter = -1 [
            if decision = 1 and [shelter_type] of current_int = "Hor" [set shelter -99]  ; if the decision is horizontal evac and the list is empty since current_int is a horizontal shelter
            if decision = 3 and [shelter?] of current_int [set shelter -99]              ; if the decision is vertical evac and the list is empty since current_int is a shelter
                                                                                         ; basically if shelter = -99, we can mark the pedestrian as evacuated later
          ]
          st
        ]
      ]
    ]
    if dcsn = 2 or dcsn = 4 [   ; horizontal (2) or vertical (4) evacuation - by CAR
      ask current_int [         ; ask the current intersection of the resident to hatch a car
        hatch-cars 1 [
          set size 2
          set current_int myself ; myself = current_int of the resident
          set evacuated? false   ; initialized as not evacuated, will be checked immediately after being born
          set dead? false        ; initialized as not dead, will be checked immediately after being born
          set moving? false      ; initialized as not moving, will start moving immediately after if not evacuated and not dead
          if dcsn = 2 [          ; horizontal evacuation by car
            set color sky
            set path [hor-path] of myself ; myself = current_int of the resident
            set decision 2
          ]
          if dcsn = 4 [          ; vertical evacuation by car
            set color magenta
            set path [ver-path] of myself ; myself = current_int of the resident
            set decision 4
          ]
          ifelse empty? path [set shelter -1][set shelter last path]       ; if path list is not empty the who of the shelter is the last item of the path
          if shelter = -1 [
            if decision = 2 and [shelter_type] of current_int = "Hor" [set shelter -99] ; if the decision is horizontal evac and the list is empty since current_int is a horizontal shelter
            if decision = 4 and [shelter?] of current_int [set shelter -99]             ; if the decision is vertical evac and the list is empty since current_int is a shelter
                                                                                        ; basically if shelter = -99, we can mark the car as evacuated later
          ]
          st
        ]
      ]
    ]
    die
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;; PEDESTRIANS ;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; check the pedestrians if they have evacuated already or died
  ask pedestrians with [not evacuated? and not dead?][
    if [who] of current_int = shelter or shelter = -99 [mark-evacuated]
    if [depth] of patch-here >= Hc [set time_in_water time_in_water + tick_to_sec mark-dead]
  ]
  ; set up the pedestrians that should move
  ask pedestrians with [not moving? and not empty? path and not evacuated? and not dead?][
    set next_int intersection item 0 path   ; assign item 0 of path to next_int
    set path remove-item 0 path             ; remove item 0 of path
    set heading towards next_int            ; set the heading towards the destination
    set moving? true
    ask road ([who] of current_int) ([who] of next_int)[set crowd crowd + 1] ; add the crowd of the road the pedestrian will be on
  ]
  ; move the pedestrians that should move
  ask pedestrians with [moving?][
    ifelse speed > distance next_int [fd distance next_int][fd speed] ; move the pedestrian towards the next intersection
    if (distance next_int < 0.005 ) [                                 ; if close enough check if evacuated? dead? if neither, get ready for the next step
      set moving? false
      ask road ([who] of current_int) ([who] of next_int)[set crowd crowd - 1] ; decrease the crowd of the road the pedestrian was on
      set current_int next_int                                                 ; update current intersection
      if [who] of current_int = shelter [mark-evacuated]
    ]
  ]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;; CARS ;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; check the cars if they have evacuated already or died
  ask cars with [not evacuated? and not dead?][
    if [who] of current_int = shelter or shelter = -99 [mark-evacuated]
    if [depth] of patch-here >= Hc [set time_in_water time_in_water + tick_to_sec]
  ]
  ; set up the cars that should move
  ask cars with [not moving? and not empty? path and not evacuated? and not dead?][
    set next_int intersection item 0 path   ; assign item 0 of path to next_int
    set path remove-item 0 path             ; remove item 0 of path
    set heading towards next_int            ; set the heading towards the destination
    set moving? true
    ask road ([who] of current_int) ([who] of next_int)[set traffic traffic + 1] ; add the traffic of the road the car will be on
  ]
  ; move the cars that should move
  ask cars with [moving?][
    move-gm                 ; set the speed with general motors car-following model
    fd speed                ; move
    if (distance next_int < 0.005 ) [    ; if close enough check if evacuated? dead? if neither, get ready for the next step
      set moving? false
      ask road ([who] of current_int) ([who] of next_int)[set traffic traffic - 1] ; decrease the traffic of the road the pedestrian was on
      set current_int next_int           ; update current intersection
      if [who] of current_int = shelter [mark-evacuated]
    ]
  ]
  ; mark agents who were in the water for a prolonged period of time dead
  ask residents with [time_in_water > Tc][mark-dead]
  ask cars with [time_in_water > Tc][mark-dead]
  ask pedestrians with [time_in_water > Tc][mark-dead]
  ; update mortality rate
  set mortality_rate count turtles with [color = red] / (count residents + count pedestrians + count cars) * 100
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
228
11
940
724
-1
-1
3.5025
1
10
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
30.0

PLOT
946
342
1370
495
Percentage of Evacuated
Min
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Evacuated" 1.0 0 -10899396 true "" "plotxy (ticks / 60) (count turtles with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"
"Cars" 1.0 0 -13345367 true "" "plotxy (ticks / 60) (count cars with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"
"Pedestrians" 1.0 0 -14835848 true "" "plotxy (ticks / 60) (count pedestrians with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"

SWITCH
67
13
221
46
immediate_evacuation
immediate_evacuation
1
1
-1000

BUTTON
1294
10
1373
43
GO
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

TEXTBOX
8
54
217
82
Residents' Decision Making Probabalisties : (Percent)
11
0.0
1

INPUTBOX
8
87
109
147
R1_HorEvac_Foot
25.0
1
0
Number

INPUTBOX
8
150
109
210
R3_VerEvac_Foot
25.0
1
0
Number

MONITOR
962
47
1044
92
Time (min)
ticks / 60
1
1
11

INPUTBOX
113
214
163
274
Hc
1.0
1
0
Number

PLOT
945
158
1370
332
Percentage of Casualties
Min
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Dead" 1.0 0 -2674135 true "" "plotxy (ticks / 60) (count turtles with [color = red] / (count residents + count pedestrians + count cars) * 100)"
"Cars" 1.0 0 -5825686 true "" "plotxy (ticks / 60) (count cars with [color = red] / (count residents + count pedestrians + count cars) * 100)"
"Pedestrians" 1.0 0 -955883 true "" "plotxy (ticks / 60) ((count pedestrians with [color = red] + count residents with [color = red]) / (count residents + count pedestrians + count cars) * 100)"

BUTTON
946
12
1022
45
READ (1/2)
load1\noutput-print \"READ (1/2) DONE!\"\nbeep
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
5
215
121
257
Critical Depth and Time: (Meters and Seconds)
11
0.0
1

INPUTBOX
8
539
58
599
Rtau1
10.0
1
0
Number

INPUTBOX
58
539
108
599
Rsig1
1.65
1
0
Number

INPUTBOX
8
603
58
663
Rtau3
10.0
1
0
Number

INPUTBOX
58
603
108
663
Rsig3
1.65
1
0
Number

TEXTBOX
10
523
210
551
Evacuation Decsion Making Times:
11
0.0
1

TEXTBOX
18
274
67
302
On foot: (ft/s)
11
0.0
1

INPUTBOX
66
276
136
336
Ped_Speed
4.0
1
0
Number

INPUTBOX
144
276
215
336
Ped_Sigma
0.65
1
0
Number

MONITOR
1074
48
1156
93
Evacuated
count turtles with [ color = green ]
17
1
11

MONITOR
1165
48
1242
93
Casualty
count turtles with [ color = red ]
17
1
11

MONITOR
1166
101
1260
146
Mortality (%)
mortality_rate
2
1
11

BUTTON
1223
10
1289
43
Read (2/2)
load2\noutput-print \"READ (2/2) DONE!\"\nbeep
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
1122
10
1218
43
Place Verticals
pick-verticals
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1268
49
1355
94
Vertical Cap
sum [evacuee_count] of intersections with [shelter? and shelter_type = \"Ver\"]
17
1
11

INPUTBOX
117
87
217
147
R2_HorEvac_Car
25.0
1
0
Number

INPUTBOX
117
150
217
210
R4_VerEvac_Car
25.0
1
0
Number

INPUTBOX
114
539
164
599
Rtau2
10.0
1
0
Number

INPUTBOX
164
539
214
599
Rsig2
1.65
1
0
Number

INPUTBOX
116
604
166
664
Rtau4
10.0
1
0
Number

INPUTBOX
163
604
213
664
Rsig4
1.65
1
0
Number

INPUTBOX
66
340
137
400
max_speed
35.0
1
0
Number

TEXTBOX
13
340
53
368
by car:\n(mph)
11
0.0
1

INPUTBOX
66
401
139
461
acceleration
5.0
1
0
Number

INPUTBOX
143
401
218
461
deceleration
25.0
1
0
Number

TEXTBOX
8
413
57
447
(ft/s^2)
11
0.0
1

INPUTBOX
66
462
139
522
alpha
0.14
1
0
Number

TEXTBOX
5
476
65
517
(mi^2/hr)
11
0.0
1

BUTTON
1028
11
1116
44
Break Links
break-links
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
7
14
62
47
Initialize
setup-init-val
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
947
504
1370
725
Evacuation Time Histogram
Minutes (after the earthquake)
#
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Histogram" 1.0 1 -16777216 true "set-plot-x-range 0 60\nset-plot-y-range 0 count turtles with [ color = green ]\nset-histogram-num-bars 60\nset-plot-pen-mode 1 ; bar mode" "histogram ev_times"
"Mean" 1.0 0 -10899396 true "set-plot-pen-mode 0 ; line mode" "plot-pen-reset\nplot-pen-up\nplotxy mean ev_times 0\nplot-pen-down\nplotxy mean ev_times plot-y-max"
"Median" 1.0 0 -2674135 true "set-plot-pen-mode 0 ; line mode" "plot-pen-reset\nplot-pen-up\nplotxy median ev_times 0\nplot-pen-down\nplotxy median ev_times plot-y-max"

MONITOR
1043
101
1159
146
Per Evacuated (%)
count turtles with [ color = green ] / (count residents + count pedestrians + count cars) * 100
1
1
11

INPUTBOX
166
213
216
273
Tc
120.0
1
0
Number

@#$#@#$#@
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Exp" repetitions="5" runMetricsEveryStep="false">
    <setup>pre-read
turn-vertical intersection vertical_shelter_num
read-all</setup>
    <go>go</go>
    <metric>count turtles with [color = red] / (count residents + count pedestrians) * 100</metric>
    <metric>count turtles with [color = green and distance one-of intersections with [gate? and gate-type = "Ver"] &lt; 0.01]</metric>
    <enumeratedValueSet variable="tsunami-case">
      <value value="&quot;250yrs&quot;"/>
      <value value="&quot;500yrs&quot;"/>
      <value value="&quot;1000yrs&quot;"/>
      <value value="&quot;2500yrs&quot;"/>
      <value value="&quot;5000yrs&quot;"/>
      <value value="&quot;10000yrs&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immediate-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hc">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R3-VerEvac-Foot">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped-Speed">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped-Sigma">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Rtau3">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Rsig3">
      <value value="1.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vertical_shelter_num">
      <value value="82"/>
      <value value="74"/>
      <value value="486"/>
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
