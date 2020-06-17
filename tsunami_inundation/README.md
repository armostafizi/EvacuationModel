# Tsunami Inundation

This directory contains the tsunami inundation data in form of multiple *X.asc* raster files, where each represent the tsunami wavefield at a certain time (X seconds) after the earthquake. The reference point for the wavefiled for the ocean grids is the sea level and for the land grids is the ground level. Note that the projection of each raster file should exist in this directory as *X.prj*. The file *details.txt* must include the start of the tsunami data provided in seconds, the increment of the data provided in seconds, and the number of wavefield files provided. It is **crucial** to have the projection of all the GIS files, as well as the coordinates of the tsunami inundation file, in *meter* unit. I recommend **WGS 84 / UTM ZONE XXY** as the projection for all the GIS files, where XXY is the zone of your study site.



Current tsunami inunudation provided for the city of Seaside is created by Dr. Hyoungsu Park and [Dr. Dan Cox](https://cce.oregonstate.edu/cox). The inundation modeling comes from the ComMIT/MOST model developed by NOAA calibrated for Cascadia Subduction Zone with an extreme return interval of 10,000 years. Please refer to our list of publications for more infromation.

## Proposed work flow

If you do not have the tsunami inundation data or you wish to use this model for other types of hazards, simply leave the *tsunami_inundation* directory empty. Doing so will ignore the hazard, and you can only use the *evacuation times* as a measurement for evaucation efficiency. If you are able to provide inundation data, running the model one time without providing the inundation data creates *boundaries.txt* that represent the coordinates of the corners of the study area. You can use these coordinates to generate the necessary wavefileds. file as shown below, that contains the coordinates for which the model needs water depths.

For more information on how to adapt this model for other types of hazards or an inquery regarding how to provide different types of inunudation data, contact [armostafizi](https://github.com/armostafizi).


