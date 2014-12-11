// BIOP Functions Library v1.0

/*
 * Returns the name of the parameters window, as we cannot use global variables, 
 * we just define a function that can act as a global variable
 */
function getWinTitle() {
    	win_title= toolName();
    	// If something is already open, keep it as-is.
	if(!isOpen(win_title)) {
		run("New... ", "name=["+win_title+"] type=Table");
		print("["+win_title+"]", "\\Update0:This window contains data "+win_title+" needs.");
		print("["+win_title+"]", "\\Update1:Please do not close it.");
	}
	return win_title;
}
    
/*
 * Based on an example by Wayne Rasband, we use the "getData" and "setData" functions to 
 * read and write data to and from an opened text window. This allows us to save parameters
 * for an ActionBar in a visible way for the user, instead of relying on IJ.prefs.
 */
function getData(key) {

	winTitle = getWinTitle();
	win = "["+winTitle+"]";

	selectWindow(winTitle);
	lines = split(getInfo(),'\n');
	i=0;
	done=false;
	value = "";
	while (!done && i < lines.length) {
		// The structure for the data is "key : value", so we use a regex to find the key and place ourselves after the " : "
		if(matches(lines[i], ".*"+key+".*")) {
			value = substring(lines[i], indexOf(lines[i]," : ")+3,lengthOf(lines[i]));
			done = true;
		
		} else {
			i++;
		}	
	}

	return value;
}

/* Like getData, but takes a default argument
 * and returns it if the key is not found
*/
function getDataD(key, default) {
	value = getData(key);
	if (value == "") {
		return default;
	} else {
		return value;
	}
}

/* 
 *  See Above Comment
 */
function setData(key, value) {
    	//Open the file and parse the data
	winTitle = getWinTitle();
	win = "["+winTitle+"]";

	selectWindow(winTitle);
	lines = split(getInfo(),'\n');
	i=0;
	done=false;
	if (lines.length > 0) {
		while (!done && i < lines.length) {
			if(matches(lines[i], ".*"+key+".*")) {
				done=true;
			} else {
				i++;
			}		
		}
			print(win, "\\Update"+i+":"+key+" : "+value);
	} else { 
		// The key did not exist
		print(win, key+" : "+value);
	}
}

/*
 * Setter and getter for boolean values
 */
function setBool(key, bool) {
	if (bool) {
		setData(key, "Yes");
	} else {
		setData(key, "No");
	}
}

function getBool(key) {
	val = getData(key);
	if (val == "Yes") {
		val = true;
	} else {
		val=false;
	}
	return val;
}

/*
 * Functions to read and write from a text file to a parameters window
 * These are sued by the Save Parameters and Load Parameters Buttons
 */
function loadParameters() {
	// Get the file
	file = File.openDialog("Select Parameters File");
	
	//Get the contents
	filestr = File.openAsString(file);
	lines = split(filestr, "\n");
	
	//Open the file and parse the data
	settingName = getWinTitle();;
	
	t = "["+settingName+"]";
	
	// If something is already open, keep it as-is.
	if(!isOpen(settingName)) {
		run("New... ", "name="+t+" type=Table");
	}
	selectWindow(settingName);
	for (i=0; i<lines.length; i++) {
		print(t, "\\Update"+i+":"+lines[i]);
	}
}
/*
 * Helper function
 */
function openParamsIfNeeded() {
	winTitle = getWinTitle();
	t = "["+winTitle+"]";
	// If something is already open, keep it as-is.
	if(!isOpen(winTitle)) {
		run("New... ", "name="+t+" type=Table");
		print(t, "\\Update0:This window contains data the macro needs. Please don't close it");
	}
}

/*
 * Same as above.
*/
function saveParameters() {
	winName = getWinTitle();
	selectWindow(winName);
	saveAs("Text", "");
}

/* 
 *  isImage lets you know whether the current file is an image. Useful below
 */
function isImage(filename) {
	extensions= newArray("lsm", "lei", "lif", "tif", "ics", "bmp", "jpg", "png", "TIF", "tiff", "czi", "zvi");
	for (i=0; i<extensions.length; i++) {
		if(endsWith(filename, "."+extensions[i])) {
			return true;
		}
	}
	return false;
}


/*
 *  getImageFolder returns the current value of the 'Image Folder' key 
 *  in the parameters window. If it's not set, it calls setImageFolder below.
 */ 
function getImageFolder() {
	dir = getData("Image Folder");
	if(dir=="") {
		dir = setImageFolder("Image Folder");

	}
	return dir;
}

/* 
 * Display a getDirectory dialog box and save the value under the 
 * 'Image Folder' key in the parameters window.
*/
function setImageFolder(title) {
	dir = getDirectory(title);
	setData("Image Folder", dir);
	setSaveFolder();
	return dir;
}

 /*
  * getSaveFolder returns the current value of the 'Save Folder' key 
  * in the parameters window. If it's not set, it calls setSaveFolder below.
  */
function getSaveFolder() {
	dir = getData("Save Folder");
	if(dir=="") {
		dir = setSaveFolder();
	}
	return dir;
}

/*
 * Sets the Save folder as a subfolder of the Image Folder
 * 'Save Folder' key in the parameters window.
 */
function setSaveFolder() {
	dir = getImageFolder();
	saveFolder = dir+"Processed"+File.separator;
	setData("Save Folder", saveFolder);
	File.makeDirectory(saveFolder);
	return dir;
}

/*
 * By using isImage above, this function counts how many images are currently in the selected
 * image folder (The folder is defined in the parameters window 
 */ 
function getNumberImages() {
	dir = getImageFolder();
	file = getFileList(dir);
	n=0;
	for (i=0; i<file.length;i++) {
		if (isImage(file[i])) {
			n++;
		}
	}
	return n;
}

/*
 * By using isImage and getNumberImages, we can now open the ith image from a folder easily
 * This is useful when running a batch on a folder
*/
function openImage(n) {
	nFiles=-1;
	dir = getImageFolder();
	file = getFileList(dir);
	nI = getNumberImages();
	for (i=0; i<file.length; i++) {
		if(isImage(file[i])) {
			 nFiles++;
			 if (nFiles==n) {
				open(dir+file[i]);
				//Check if the image has a ROI set and open it
				openRoiSet(file[i]);
			}
		}
	}
}

/*
 * Mainly used for the selectImageDialog function, 
 * this function returns a list of image names from
 * the current image folder. Again using isImage
 */
function getImagesList() {
	dir = getImageFolder();
	
	list = getFileList(dir);

	images = newArray(list.length);
	k=0;
	// Check things in the list
	for (i=0; i<list.length; i++) {
		if(isImage(list[i])) {
			images[k] = list[i];
			k++;
		}
	}
	images = Array.trim(images,k);
	return images;
	
}


/*
 * Simple dialog to open images and RoiSets in the current folder.
 */
function selectImageDialog() {
	//Find out how many images there are
	dir = getImageFolder();
	
	list = getImagesList();

	// Also check for associated ROI sets
	roiDir = getRoiFolder("Open");

	// Account for the option "None"
	images = newArray(list.length+1);
	images[0] = "None";
	// Build the dialog
	Dialog.create("Select File To Open");
	
	for (i=0; i<list.length; i++) {
		
		images[i+1] =  list[i];
		
		//Check if it has an associated ROI Set and show it.
		hasRoi = hasRoiSet(list[i]);	
		if(hasRoi)
			images[i+1] = images[i+1]+" (Has ROI Set)";
			
	}
	Dialog.addChoice("Label", images) ;

	// Show it
	Dialog.show();
	file = Dialog.getChoice();

	// Now openthe images, if the user selected something other than "None"
	if (!matches(file, "None")) {
		if(endsWith(file,"(Has ROI Set)") ) {
			
			// Remove the "(Has ROI Set)" text to recover the filename
			fileName = substring(file,0,lengthOf(file)-14);
			// Open the file and its ROI set
			open(dir+fileName);
			openRoiSet(fileName);
		
		} else {
			fileName = file;
			open(dir+fileName);
		}
	}
}

/* 
 * Simple function to check the presence of a ROI set
 * The macros here use a function called getRoiDir to get which is the folder that should contain the ROI sets
 * The ROI set must have EXACTLY the same name as the filename and end in '.zip'
*/
function hasRoiSet(file) {
	
	roiDir = getRoiFolder("Open");
	file = getFileNameNoExt(file);
	
	if (File.exists(roiDir+file+".zip")) {
		return true;
	} else {
		return false;

}

/*
 * openRoiSet simply opens the ROIs associated with the image 'file' if it exists
 */ 
function openRoiSet(file) {
	if (hasRoiSet(file)) {
		roiDir = getRoiFolder("Open");
		//Load ROI. set
		file = getFileNameNoExt(file);
		roiManager("reset");
		roiManager("Open", roiDir+file+".zip")
		roiManager("Show All");
	}
}

/*
 * returns the directory where the ROIs are stored, a subfolder of the image folder.
 */
function getRoiFolder(mode) {
	// Feel free to rename it if you like that sort of thing.
	dirName = "ROI Sets";
	if (mode == "Open") {
		dir = getImageFolder();
	} else {
		dir = getSaveFolder();
	}
	roiDir = dir+dirName+File.separator;
	File.makeDirectory(dir);
	File.makeDirectory(roiDir);
	
	return roiDir;
}


/*
 * Saves the ROIs of the current image
 */ 
function saveRois(mode) {
	name = getTitle();
	roiDir = getRoiFolder(mode);
	// If image has an extension, remove it.
	name = getFileNameNoExt(name);
	nR = roiManager("Count");

	// if there are ROIs save them
	if (nR > 0) {
		//Save Roi Set
		File.makeDirectory(roiDir);
		roiManager("Save", roiDir+name+".zip");
		print("ROI Set Saved for image "+name);
	}
}
/*
 * Allows for easily renaming the last added ROI
 */
function renameLastRoi(name) {
	nRois = roiManager("Count");
	roiManager("Select", nRois-1);
	roiManager("Rename", name);
}

/* add on 2014.12.01
 * Allows for easily renaming ROIs , 
 * from the firtROI to the lastRoi(included)
 * using patternName
 */
function renameROI(firtROI,lastRoi,patternName, separator){
	counter=1;
	for (currentROI = firtROI ; currentROI <= lastRoi ;currentROI++){
		roiManager("select", currentROI);
		roiManager("Rename", patternName+separator+counter);
		counter++;
	}
}


/*
 * Saves the current image as a TIFF in the currentImage Folder
 */ 
function saveCurrentImage() {
	name = getTitle();
	print(name);
	dir = getSaveFolder();
	print(dir);
	File.makeDirectory(dir);
	name = getFileNameNoExt(name);
	saveAs("TIFF", dir+name+".tif");
}

/*
 *  Returns the file name witout the extension
 */ 
function getFileNameNoExt(file) {
		// Get the file name without the extension, regex
	if (matches(file,".+\\.\\w{3,4}")) {
		file = substring(file,0,lastIndexOf(file,"."));
	}
	return file;
}

/*
 * Generic function to calculate the calibration of the image based on the 
 * CCD Pixel size, Magnification, c-mount and binning
*/
function setCalibration() {
	go = true;
	
	// Check if the image is calibrated already
	getVoxelSize(width, height, depth, unit);
	if( unit != "pixel") {
		go = getBoolean("Image already has a calibration. Continue?");
	}

	// Prompt for acquisition details to set calibration
	if (go) {
   	//Calibration for the image
   	Dialog.create("Set Pixel Size for your data");
	Dialog.addNumber("Magnification", 63, 0,5,"x");
	Dialog.addNumber("Binning", 1,0,5,"x");
	Dialog.addNumber("CCD Size", 6.45, 2,5,"microns");
	Dialog.addNumber("c-Mount Size", 1.0, 1,5,"x");		
	
	Dialog.show();

	// Recover the values for magnification
	mag = Dialog.getNumber();
	bin = Dialog.getNumber();
	ccd = Dialog.getNumber();
	cm = Dialog.getNumber();

	// Basic formula for calculating pixel size of a camera
	pixelSize=(ccd*bin)/(mag*cm);

	// If we decided not to set the calibration but use the already existing one
	} else {
		pixelSize=width;
	}

	// Set the Pixel Size in the Log Window and return it if needed.
	setData("Pixel Size", pixelSize);
	return pixelSize;
	//Does nothing to the image. 
}

/*
 * This function writes a result to a results table called 'tableName', at :
 *  - a specified row (specify a number)
 *  or
 *  - the current row (nResults-1)
 *  or 
 *  - the next row (nResults)
 */
function writeResults(tableName, column, row, value) {
	if(isOpen("Results")) {
		IJ.renameResults("Results","Temp");
	}
	if(isOpen(tableName)) {
		// The only way to write to a results table in macro language is to 
		// have the table be called "Results", so we rename it if it already exists
		IJ.renameResults(tableName,"Results");
	}else{
		run("Set Measurements...", "  display redirect=None decimal=5");
		run("Measure");
		IJ.deleteRows(0, 0);
		updateResults();
	}	
	
		
		// Now we can set the data
		if(row == "Current"){
			setResult(column, (nResults-1),value);
		} else if(row == "Next"){
			setResult(column, nResults,value);
		} else {
			setResult(column, row,value);
		}	
		// Call updateResults to have the table appear if it's new
		updateResults();

		// And rename the results to 'tableName'
		IJ.renameResults("Results", tableName);
		
	if(isOpen("Temp")) {
		IJ.renameResults("Temp","Results");
	}
		
}

/*
 * Prepare a new table or an existing table to receive results.
 */
function prepareTable(tableName) {
		updateResults();
		if(isOpen("Results")) { IJ.renameResults("Temp"); updateResults();}
		if(isOpen(tableName)) { IJ.renameResults(tableName,"Results"); updateResults();}

}

/*
 * Once we are done updating the results, close the results table
 */
function closeTable(tableName) {
		updateResults();
		if(isOpen("Results")){ IJ.renameResults(tableName); updateResults();}
		if(isOpen("Temp")) { IJ.renameResults("Temp","Results"); updateResults();}
}
