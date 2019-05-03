# Road Netowk

This directory contains the GIS files that have transportation network data. As shown in the Figure below, the file is very basic and can be readily downloaded from (OpenStreetMap)[https://www.openstreetmap.org]. The only attribute that needs to be added or manually modifed is the *direction* of the link which is a string that can be either "two-way", or "north", "east", "south", "west". This attribute defines if the link is two-way or on-way, and if one-way, to which direction. This can be used to resrtrain the evacuees not to move back towards the ocean under any circumstances (e.g., vertical evacuation) or to simply mark one-way roads.

Please not that it is **crucial** to have the projection of all the GIS files, as well as the coordinates of the tsunami inundation file, in *meter* unit. I recommend **WGS 84 / UTM ZONE XXY** as the projection for all the GIS files, where XXY is the zone of your study site.

![Transportation Network](../figs/road_network.png?raw=true "Road Network")
