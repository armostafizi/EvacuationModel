# Vertical Evacuation Tsunami Evacuation Model

This is an agent based modeling of vertical evacuation for the city of Seaside, OR.

## Getting Started

Clone this repo and open the .nlogo file with Netlogo 5.1.0. Do not attempt opening/translating this script to Netlogo 6. Some functionalities may be lost.

### Prerequisites

You must have Netlogo 5.1.0.

### Instructions

Here is a brief instruction on how to run the model:

1. Set the parameters on the left panel:
  immediate evacuation: if on, people start the evacuation right away. If not, they start with a delay, coming from a Rayleigh distribution. The detailed explanation is documented [here](https://ir.library.oregonstate.edu/concern/graduate_thesis_or_dissertations/bv73c493x) and [here](https://www.sciencedirect.com/science/article/pii/S0968090X15004106).

  Tsunami-case: the return interval of the tsunami. 2500-year return interval is the most intensive tsunami model used with this model.

  R(1/2/3/4)-(Ver/Hor)Evac-(Car/Foot): the percentages of different evacuation mode categories. These should add up to 100. Evacuees can evacuate either by foot or by car to either a horizontal or a vertical evacuation shelter.

  Hc: critical inundation depth, used for estimating casualties. Normally 0.5m is suggested. This can relate to the resiliecncy of the population towards the inundation force. 

  Ped-speed, ped-sigma: the normal distribution parameters, used for random drawing of the walking speed of the evacuees. Normally walking speed ranges from 3 to 5 ft/s depending on dempgraphic and physical charactersistics of the evacuee.

  Max-speed, acceleration, deceleration, and alpha: Driving and car-following model parameters. Recommend values are 35, 5, 25, and 0.14 respectively. For detailed explanation on the car-following behavior, please refer [this](https://ir.library.oregonstate.edu/concern/graduate_thesis_or_dissertations/bv73c493x) and [this](https://link.springer.com/article/10.1007/s11069-017-2927-y).

  Rtau(1/2/3/4) and Rsig(1/2/3/4): The Rayleigh distribution parameters, governing the delay of the evacuees in each group. if set to 0 and 1.65 respectively, it means that 99% of the people evacuate in first 5 minutes. The detailed explanation is documented [here](https://ir.library.oregonstate.edu/concern/graduate_thesis_or_dissertations/bv73c493x).

2. Click on "READ(1/2)
  You MUST click on this, and reload the model every time you change the parameters on the left panel. Otherwise your changes won't go into effect.

3. Click on "Place Verticals" and use your mouse and click on the intersections you want the vertical evacuation shelters to be placed, and then click on the button one more time to turn it off.

4. Click on "Read(2/2)"

5. "GO"

Agents walk towards the transportation netwrok, depending on their preparation/milling time and their walking speed. Afterwards, they switch colors based on their decisions. Blue for the horizontal evac by car, purple for vertical evac by car, orange for horizontal evac by foot, and brown for vertical evac by foot. Refere to [this](https://ir.library.oregonstate.edu/concern/graduate_thesis_or_dissertations/bv73c493x), [this](https://link.springer.com/article/10.1007/s11069-017-2927-y), and [this](https://www.sciencedirect.com/science/article/pii/S0968090X15004106) for thorough discussion on the simulated evaucation process. 

## Snapshots

![Alt text](snapshot_1.png?raw=true "Snapshot 1 - time = 6min")
![Alt text](snapshot_2.png?raw=true "Snapshot 2 - time = 44min")

## Authors

* **Alireza Mostafizi** - [armostafizi](https://github.com/armostafizi)
