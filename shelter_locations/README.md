# Shelter Locations

This directory contains the GIS files that have shelter locations data. As shown in Figure below, the gis data should be in simple point shapefile format, where each point represents a shelter and needs to have an attribute *type*. This attribute is a string that can either be *hor* or *ver*, indicating if the shelter is a horizontal or a vertical shelter respectively. The model picks the closest intersection in the transportation network as the shelter for each point, therefore, it is recommended that the user uses the transportation network GIS file, and pick its vertices to generate the shelter locations.

Please not that it is **crucial** to have the projection of all the GIS files, as well as the coordinates of the tsunami inundation file, in *meter* unit. I recommend **WGS 84 / UTM ZONE XXY** as the projection for all the GIS files, where XXY is the zone of your study site.

![Shelter Locations](shelter_locations.png?raw=true "Shelter Locations")
