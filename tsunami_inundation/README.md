# Tsunami Inundation

This directory contains the tsunami inundation data in form of a csv file, as shown in the figure below. The *tsunami_inundation.csv* file contains the water depth time series for different locations in the study cite. The first two columns are longitude and latitude of the centroid of a grid (shown in figure below). Note that the projectionfor these coordinates are the same as the provided projection for the rest of the GIS files. Please note that it is **crucial** to have the projection of all the GIS files, as well as the coordinates of the tsunami inundation file, in *meter* unit. I recommend **WGS 84 / UTM ZONE XXY** as the projection for all the GIS files, where XXY is the zone of your study site. The rest of the columns are 120 water depths in meters for every 30 seconds (1 hour of inundation data in total). As shown in the figure, the coordinates of the discretized grid is set up in a way to cover the entire study area. More accurately, these coordinates are associated with the *patches* in netlogo model.


![Sample Tsunami Inundation File](tsunami_inundation.png?raw=true "Sample Tsunami Inundation File")
![Tsunami Inundation Grid](tsunami_inundation_grid.png?raw=true "Tsunami Inundation Grid")

Current tsunami inunudation provided for the city of Seaside is created by Dr. Hyoungsu Park and [Dr. Dan Cox](https://cce.oregonstate.edu/cox). The inundation modeling comes from the ComMIT/MOST model developed by NOAA calibrated for Cascadia Subduction Zone with an extreme return interval of 10,000 years. Please refer to our list of publications for more infromation. In addition, different inundation files with less extreme return intervals are provided in [extra_cases](extra_cases/) directory. Simply replace and rename the file to *tsunami_inundation.csv* in the current directory if you wish to simulate a less severe evacuation scenario.

## Proposed work flow

If you do not have the tsunami inundation data or you wish to use this model for other types of hazards, simply do not provide *tsunami_inundation.csv*. Doing so will ignore the hazard, and you can only use the *evacuation times* as a measurement for evaucation efficiency.

If you are able to provide inundation data, running the model one time without providing *tsunami_inundation.csv* creates *coordinates.csv* file as shown below, that contains the coordinates for which the model needs water depths. You can use *coordinates.csv* to create the inundation files, simply filling 120 water depths for every 30 seconds and for every coordinate.

For more information on how to adapt this model for other types of hazards or an inquery regarding how to provide different types of inunudation data, contact [armostafizi](https://github.com/armostafizi).


![Coordinates](coordinates.png?raw=true "Coordinates")


