batchCount();
function batchCount() {
	 // Get directories for input images and output results	
	dir1 = getDirectory("Choose Image Folder to Analyze");
	dir2 = getDirectory("Choose Folder to save results");
	
	// Get the list of files in the chosen directory
	list = getFileList(dir1);
	n = list.length; // Total number of files
	
	// Set batch mode to false (not necessary if processing files one at a time)
	setBatchMode(false);
	
	for (i = 0; i < n; i++) {
		showProgress(i + 1, n); // Show progress
		
		// Open the image file
		open(dir1 + list[i]);
		
		// Get the title of the opened image
		original = getTitle();

width = getWidth();
height = getHeight();
run("Subtract Background...", "rolling=8 light");
run("Colour Deconvolution", "vectors=[User values] [r1]=0.01599332 [g1]=0.87389725 [b1]=0.48584756 [r2]=0.95400476 [g2]=0.29035908 [b2]=0.0746088 [r3]=0.63662606 [g3]=0.77040774 [b3]=0.034339726");

//Red ISH Stain
selectImage(original + "-(Colour_1)");
w1 = getTitle();

//Blue ISH Stain
selectImage(original + "-(Colour_2)");
w2 = getTitle();

//Purple Stain (Nuceli)
selectImage(original + "-(Colour_3)");
w3 = getTitle();

//Identifying Red Staining Locations
selectImage(w1);
run("Duplicate...", "title=color1");
selectImage(w1);
setAutoThreshold("Intermodes");
run("Convert to Mask");
run("Despeckle");

//Identifying Blue Staining Locations
selectImage(w2);
run("Duplicate...", "title=color2");
selectImage(w2);
setAutoThreshold("Intermodes");
run("Convert to Mask");
run("Despeckle");

//Identifying Nuclei
selectImage(w3);
run("Duplicate...", "title=color3");
selectImage(w3);
setAutoThreshold("Default");
run("Convert to Mask");
run("Despeckle");
run("Despeckle");
run("Despeckle");
rename("org.dapi.mask");
run("Analyze Particles...", "size=300-Infinity circularity=0.0-1.00 exclude include show=Masks");	
run("Convert to Mask");
rename("DAPI");

//Run Adjustable Watershed (will separate adejent nuclei)  
//Will first pull out only those objects deemed large enough to be clustered nuclei
	selectWindow("DAPI");
	run("Analyze Particles...", "size=5000-Infinity show=Masks");
	selectWindow("Mask of DAPI");
	imageCalculator("AND create", "DAPI","Mask of DAPI");
	selectImage("Result of DAPI");
	run("Adjustable Watershed", "tolerance=0.5");
	run("Analyze Particles...", "size=150-Infinity show=Masks");
	rename("watershed_clustered_nuclei_mask");
	close("Mask of DAPI");
	//selectWindow("watershed_clustered_nuclei_mask");
	
	selectWindow("DAPI");
	run("Analyze Particles...", "size=150-5000 show=Masks");
	rename("small_nuclei");
	selectWindow("small_nuclei");
	run("Analyze Particles...", "circularity=0.25-0.59 show=Masks");
	rename("irregular_nuclei");
	selectWindow("small_nuclei");
	run("Analyze Particles...", "circularity=0.60-1.00 show=Masks");	
	rename("small_circular_nuclei");	
	selectWindow("small_circular_nuclei");
	run("Adjustable Watershed", "tolerance=1");
	run("Analyze Particles...", "size=150-Infinity show=Masks");
	rename("watershed_small_nuclei");
	selectWindow("irregular_nuclei");
	run("Adjustable Watershed", "tolerance=1.5");
	//run("Analyze Particles...", "size=15-Infinity show=Masks");
	
	imageCalculator("OR create", "watershed_small_nuclei","irregular_nuclei");
	rename("watershed_small_nuclei_2");

	imageCalculator("OR create", "watershed_clustered_nuclei_mask","watershed_small_nuclei_2");
	selectWindow("Result of watershed_clustered_nuclei_mask");
	rename("all_nuclei");
	imageCalculator("AND create", "org.dapi.mask","all_nuclei");
	selectImage("Result of org.dapi.mask");
	run("Analyze Particles...", "size=5000-Infinity show=Masks");
	run("Adjustable Watershed", "tolerance=0.5");
	rename("large");
	run("Convert to Mask");
	selectImage("Result of org.dapi.mask");
	run("Analyze Particles...", "size=100-5000 show=Masks");
	rename("small");
	run("Convert to Mask");
	imageCalculator("OR create", "large","small");
	selectImage("Result of large");
	w3 = getTitle();

	run("Select None");
	close("Results");
	
	///pick out red nuclei
run("Analyze Particles...", "size=100-Infinity add");
run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");

    selectImage(w1);
	run("Select None");
	close("Results");
	
//select only those nuclei that colocalize with the gross binary mask of red
	if (roiManager("count") > 0) {
			
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

///look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)==0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");
	
}
 
    close("Results");
  	run("Select None");	

if (roiManager("count")>0) {

// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}


//creating a new mask of the red ish nuclei 
	newImage("red_nuclei", "8-bit black", width, height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("red_nuclei");
	selectWindow("Mask");
	rename("red_nuclei") ;
	run("Duplicate...", "title=[red_nuclei]");
	selectWindow("red_nuclei");
	
}
else {
	newImage("red_nuclei", "8-bit black", width, height, 1);
	run("Duplicate...", "title=[red_nuclei]");
	selectWindow("red_nuclei");
}
//clear the roi manager
if (roiManager("count") > 0) {
	roiManager("delete");
	}
	run("Select None");
	close("Results");
	
	
//include the below saveAs function if you are spot-checking the macro	
	saveAs("jpg", dir2+"red_nuclei+" + list[i] + ".jpg");


/// pick out blue nuclei
selectImage(w3);	
run("Select None");
run("Remove Overlay");
close("Results");
run("Analyze Particles...", "size=100-Infinity add");
run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");

    selectImage(w2);
	run("Select None");
	close("Results");
	
// select only those nuclei that colocalize with the gross binary mask of blue
	if (roiManager("count") > 0) {
			
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)==0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");
	
}
 
    close("Results");
  	run("Select None");
  	
  	selectImage("color2");
  	
  	run("Select None");
	close("Results");

if (roiManager("count")>0) {

// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}


// creating a new mask of the blue ish nuclei 
	newImage("blue_nuclei", "8-bit black", width, height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("blue_nuclei");
	selectWindow("Mask");
	rename("blue_nuclei") ;
	run("Duplicate...", "title=[blue_nuclei]");
	selectWindow("blue_nuclei");
	
}
else {
	newImage("blue_nuclei", "8-bit black", width, height, 1);
	run("Duplicate...", "title=[blue_nuclei]");
	selectWindow("blue_nuclei");
}
// clear the roi manager
if (roiManager("count") > 0) {
	roiManager("delete");
	}
	run("Select None");
	close("Results");
	
// include the below saveAs function if you are spot-checking the macro	
	saveAs("jpg", dir2+"blue_nuclei+" + list[i] + ".jpg");	
	
	selectImage("red_nuclei");	
run("Select None");
run("Remove Overlay");
close("Results");
run("Analyze Particles...", "size=0-Infinity add");
run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");


    selectImage("blue_nuclei");
	run("Select None");
	close("Results");
	
	if (roiManager("count") > 0) {
		
	}
// create a new array that is equal in length to the number of rois contained in the roi manager. then measure all of the rois in the array
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}
	Array.print(array);

/// creat a new array. populate it with all of those rois that do not meet our criteria. using the new array, delete all of those rois from the manager. 
/// make adjustments here. 
	measurements = newArray(getValue("results.count"));
	print(measurements.length);
	for (l=0; l<measurements.length; l++) {
	      if (getResult("%Area", l)==0 ) {
		      measurements[l] = l;
		  }
	}
			Array.print(measurements);
	Array.getStatistics(measurements, min, max, mean, stdDev);
	array_max = max;
	array_mean = mean;
	print(max);
	print(mean);
	close("Results");

	if (array_max == 0) {
		roiManager("Select", 0);
		roiManager("Measure");
		 if (getResult("%Area", 0)==0 ) {
		 		roiManager("select", 0);
		 		roiManager("Delete");
		 }
	} else {

		roiManager("select", measurements);
	//	waitForUser;

		roiManager("Delete");
	}
    
    close("Results");
  	run("Select None");

if (roiManager("count")>0) {

// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}


// creating a new mask of your blue ish nuclei
	newImage("both_colors_nuclei", "8-bit black", width, height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("both_colors_nuclei");
	selectWindow("Mask");
	rename("both_colors_nuclei") ;
	run("Duplicate...", "title=[both_colors_nuclei]");
	selectWindow("both_colors_nuclei");
	
}
else {
	newImage("both_colors_nuclei", "8-bit black", width, height, 1);
	run("Duplicate...", "title=[both_colors_nuclei]");
	selectWindow("both_colors_nuclei");
}
// clear the roi manager
if (roiManager("count") > 0) {
	roiManager("delete");
	}
	run("Select None");
	close("Results");
	
	selectImage("red_nuclei");
	run("Select None");
	run("Remove Overlay");
	run("Analyze Particles...", "summarize");
	
	selectImage("blue_nuclei");
	run("Select None");
	run("Remove Overlay");
	run("Analyze Particles...", "summarize");
	
	selectImage("both_colors_nuclei");
	run("Select None");
	run("Remove Overlay");
	run("Analyze Particles...", "summarize");
	
	selectImage("all_nuclei");
	run("Select None");
	run("Remove Overlay");
	run("Analyze Particles...", "summarize");
	
	/// should normalize for region area here. i dont know what kind of cropping will be done.
	
	
/// need to include a step that counts the final number of red, blue, and red+blue nuclei.

	selectWindow("Summary");
	saveAs("results", dir2+"+" + list[i] + ".txt");
	close("Results");
	close("Summary");
	close("Threshold");  
	close("ROI Manager");
    close("*");
    close("*.txt");
          first += 1;
      }
      
Dialog.create("DONE");
Dialog.show();
exit;



