# Population Distribution

This directory contains the GIS files that have population distribution data. As shown in the figure below, these GIS files are point shapefiles indicating the initial position of the evacuees (lat/lon). There is no specific attribute needed for the points. At a basic level, these data can be compiled from [census data](https://www.census.gov/data.html) by randomly distributing the number of residents to each census block/tract. Alternatively, the population distribution can be manually created based on specific characteristics of the city of interest, e.g. higher density of the residents and tourists in downtown or beach area.

Please not that it is **crucial** to have the projection of all the GIS files, as well as the coordinates of the tsunami inundation file, in *meter* unit. I recommend **WGS 84 / UTM ZONE XXY** as the projection for all the GIS files, where XXY is the zone of your study site.

![Population Distribution](population_distribution.png?raw=true "Population Distribution")
