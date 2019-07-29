// Step One : Macro for creating Kymograph 

//How to run the macro
//Press run on macro: it will ask user to open image file
//macro generates a maximum projection of the time series and ask user to draw teh track path. 
//the line width of the track path is set default as 5 pixels (variable linewidth)
//macro assume the track path is less than 10000 pixels  (variable maxkymolength)

//all result files will be saved in the same folder as raw image.

// initialize ImageJ
run("Bio-Formats Macro Extensions");
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black edm=Overwrite");

//raw data parameters
var dir, name, bit, t_dim, kymolength, maxkymolength=10000;
//width of user drew line, take more average.
var linewidth=10;  




//global recording parameters.  assume the track line is less than 2,000 points
var cor_X=newArray(maxkymolength);
var cor_Y=newArray(maxkymolength);




// opening image if not open already 
if (nImages==0){
      	filepath=File.openDialog("Select an image File");
		run("Bio-Formats Importer", "open=["+filepath+"] color_mode=Default view=Hyperstack stack_order=XYCZT");
}

// getting resolution info from figure if possible
getPixelSize(unit, pixelWidth, pixelHeight);
pixelResolution=(pixelWidth+pixelHeight)/2;
// preping image for running kymo
dir=getInfo("image.directory");
name=getInfo("image.filename");
name=RemoveFileExtensionFromString (name);
PrepingforKymo();
NewDirForAnalysisFiles = dir+name+File.separator;
File.makeDirectory(NewDirForAnalysisFiles);




// Saving single channel 8-bit image //
saveAs("Tiff", NewDirForAnalysisFiles+name+"_forAnalysis.tif");
close();


// Re-Opening saved image (single channel)
filepath=dir+name+File.separator+name+"_forAnalysis.tif";
run("Bio-Formats Importer", "open=["+filepath+"] color_mode=Default view=Hyperstack stack_order=XYCZT");
mitoChannel=getImageID();
Ext.setId(filepath);





// Getting Time resolution //
//Trying through bioformats
Ext.getImageCount(numberOfSlices);
deltaT=newArray(numberOfSlices);
frameInterval=newArray(numberOfSlices);
for (sliceNumber=0; sliceNumber<numberOfSlices; sliceNumber++){
		if (sliceNumber==0){frameInterval[sliceNumber]=deltaT[sliceNumber];}
		if (sliceNumber>0){frameInterval[sliceNumber]=deltaT[sliceNumber]-deltaT[sliceNumber-1];}
	}
Array.getStatistics(frameInterval, min, max, meanFrameInterval, std);

// If Bioformats fail
if (meanFrameInterval==0){meanFrameInterval=Stack.getFrameInterval();} // If bioformats fials, then try imageJ's own reader
timeResolution=meanFrameInterval;




// Getting Time resolution (only if above code is not working)//
//timeResolution=("Time gap inbetween two frames (in secs)", 0.5);
//timeResolution=getFrameIntervalFromND2File(getImageID()); // This only works if file is ND2. Comment out this line the use the above two lines if file is not ND2



// Checking whether time interval got is fine
totalTime=getNumber("Full Time length of Image (in secs)", timeResolution*nSlices); // Just for chacking 

// Get bit depth and total time points
bit=bitDepth(); t_dim=nSlices;



// printing and saving Results//
  title1 = "Text Window";
  title2 = "[results of "+name+"]";
  f = title2;
  if (isOpen(title1))
     print(f, "\\Update:"); // clears the window
  else
   run("Text Window...", "name="+title2+" width=72 height=8 menu");
  print(f, "name= "+name+" \n");
  print(f, "Frame Interval= "+timeResolution+" \n");
  print(f, "Pixel Size= "+ pixelResolution+" \n");
  print(f, "Bit Depth= "+ bit+" \n");
  print(f, "No Of Slices= "+ t_dim+" \n");
  saveAs("Text", dir+name+File.separator+name+"_ImageCharecteristics.txt");
  run("Close");


//create and save kymo image
kymo_make();
run("Close All");






// opening Image for enhancing kymo
open(dir+name+File.separator+name+"_kymo.tif");
run("32-bit");
kymoImage=getImageID();
logWindowName="[Enhancing Contrast]";
run("New... ", "name="+logWindowName+" type=Table");
f = logWindowName;
print(f, "\\Clear");
print(f, "Enhancing Kymograph Contrast... Please Wait");
run("Enhance Local Contrast (CLAHE)", "blocksize=63 histogram=2048 maximum=30 mask=*None*");
selectWindow("Enhancing Contrast");
run("Close");

// Telling user to change contrast as desired
selectImage(kymoImage);
run("Brightness/Contrast...");
title = "Adjust Contrast";
msg = "Adjust Contrast and press OK";
waitForUser(title, msg);
run("8-bit");
resetMinAndMax();
kymoImage=getImageID();

// Resetting pixel resolution
selectImage(kymoImage);
setVoxelSize(pixelResolution, timeResolution, 0, unit);

// over-writing original kymo image
selectImage(kymoImage);
saveAs("Tiff", dir+name+File.separator+name+"_kymo.tif");
close();



// Telling user to run step 2
title = "step1 finished! \n Run step 2";
msg = "Run step 2 and select the the data folder named with the image name";
showMessage(title, msg);











//-----------------------------------------   functions ----------------------------------

function kymo_make()
  {
   rename("raw");
   //rescale image to pixel unit
   run("Properties...", "channels=1 slices=1 frames="+t_dim+" unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1 frame=[0 sec] origin=0,0");
   run("Z Project...", "projection=[Max Intensity]");
   mitoChannelMax=getImageID();
   userdrawline();
   readXYcoordinates();

   createkymo();
  }

// user draw track path
function userdrawline()
 {
   setTool("polyline"); roiManager("reset");
   run("Line Width...", "line="+linewidth);

   // asking user for cyto channel //
   otherChannel=-999999999;
    if (getBoolean("Open other channels for drawing kymo?")==true){
	  	filepath=File.openDialog("Select an image File");
		run("Bio-Formats Importer", "open=["+filepath+"] color_mode=Default view=Hyperstack stack_order=XYCZT");
		run("Enhance Contrast", "saturated=0.35");
		otherChannel=getImageID();
		getDimensions(tmp, tmp, nChannels, tmp, tmp);
		if (nChannels>1){
			for (channelNumber=0; channelNumber<nChannels; channelNumber++){
				Stack.setChannel(channelNumber+1);
				run("Enhance Contrast", "saturated=0.35");
			}
		}
		setTool("polyline");
		//run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1 frame=[0 sec] origin=0,0");
		// Resizing otherChannel to mitoChannel //
		matchImageSize(otherChannel, mitoChannelMax);
	}
	
   title = "User draw track path";
   msg = "User draw track path (from minus end to plus end), then click \"OK\".";
   waitForUser(title, msg);
   while (selectionType()==-1){
   	beep();
   	waitForUser(title, msg);
   }
   run("Fit Spline"); // fitting spline to freeline		
   roiManager("reset"); // remove any previous points from the ROI manager
   roiManager("Add"); // automatically adds to ROI manager after clicking OK

   // applying selection line to mito channel if other channel was used//
   if (isOpen(otherChannel)==true){
   		selectImage(otherChannel);
   		run("Select None");
   		selectImage(mitoChannelMax);
   		run("Select None");
   		roiManager("Select", 0);
   		msg = "Fine tune draw track path, then click \"OK\".";
   		waitForUser(title, msg);
   		roiManager("Update");
   		selectImage(otherChannel);
   		close();
   }
   run("Interpolate", "interval=1");
   saveAs("XY Coordinates", dir+name+File.separator+name+"_kymoline.txt");
   roiManager("save", dir+name+File.separator+name+"_kymoline.zip");
   roiManager("reset");
 }


// read X and Y coordinates from each pixel in the track path. 
function readXYcoordinates()
 {
  data = File.openAsString(dir+name+File.separator+name+"_kymoline.txt");
  datapoints = split(data, "\n");
  kymolength=datapoints.length;
  
  for (i = 0; i < (datapoints.length); i++)
   {
    tmp = split(datapoints[i], "\t");
    cor_X[i]=tmp[0];
    cor_Y[i]=tmp[1];
   }
 }

 
function createkymo()
 {
  if(bit==8)
   newImage("kymo", "8-bit Black", kymolength, t_dim,1);
  if(bit==16)
   newImage("kymo", "16-bit Black", kymolength, t_dim,1);

  selectImage("raw");
  setBatchMode(true);
       
  for(t=0;t<t_dim;t++)
   {
    for( j=0;j<kymolength;j++)
     {
      selectImage("raw");
      setSlice(t+1);
      tmp=getPixel(cor_X[j], cor_Y[j]);
      
      selectImage("kymo");
      setPixel(j,t,tmp);
     }
   }

  selectImage("kymo");
  setVoxelSize(pixelResolution, timeResolution, 0, unit);
  saveAs("Tiff", dir+name+File.separator+name+"_kymo.tif");
  close();
  setBatchMode(false);
  updateDisplay();
 }



















//------------------------HB Functions-------------------------//
function PrepingforKymo(){

// preping image for running kymo
getDimensions(width, height, channels, slices, frames);
// If not single channel, then asking user to input channel to work with
if (channels>1){
			rows = 1;
		columns = channels;
		labels = newArray(channels);
		defaults = newArray(channels);
		for (LabelNumber=0; LabelNumber<channels; LabelNumber++) {
		  labels[LabelNumber] = "Channel "+LabelNumber+1;
		  if (LabelNumber==0)
		     defaults[LabelNumber] = true;
		  else
		     defaults[LabelNumber] = false;
		}
		
		
		totalChannelsSelected=0;
		while (totalChannelsSelected!=1){
			totalChannelsSelected=0;
			Dialog.create("Please select only one channel to use for analysis");
			Dialog.addCheckboxGroup(rows,columns,labels,defaults);
			Dialog.show();
				for (selection=0; selection<channels; selection++){
			   if (Dialog.getCheckbox==1){
			   	totalChannelsSelected=totalChannelsSelected+1;
			   selectedChannel=selection+1;
			   }
			}
		}

// Removing Other channels
		channelsToRemove=newArray();
		for  (channelNumber=0; channelNumber<channels; channelNumber++){
			if (channelNumber+1!=selectedChannel){
				channelsToRemove=Array.concat(channelsToRemove, channelNumber+1);
			}
		}

	
		for  (channelNumber=0; channelNumber<channelsToRemove.length; channelNumber++){
			Stack.setChannel(channelsToRemove[channelNumber]);
			run("Delete Slice", "delete=channel");
			run("Make Composite");
		}
}
// Stretching Contrast
run("Enhance Contrast", "saturated=0.5");

// Asking user to fix contrast 
title = "Fix brightness contras if necessary";
   msg = "Fix brightness contras if necessary";
   waitForUser(title, msg);
   
// Making image 8 bit
run("8-bit");
}








// Remove any file extension from string /////////////////////////////
function RemoveFileExtensionFromString (string){					// The input is a string 
	for (ExtNumber=0; ExtNumber<1000; ExtNumber++) {				// Does a for loop thousand times to check for multiple extensions
		  string=replace(string, "[.][a-z][a-z][a-z0-9]$","");		// At every loop, it removes any 3 letter extension at the end of the string by regex
	}																//
	return string;													// Returns the trimmed string to the user
}																	//
//////////////////////////////////////////////////////////////////////








// automatically get frame intervals if file is ND2 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function getFrameIntervalFromND2File(imageID){
	selectImage(imageID);
	fullMetadata=split(getInfo(),'\n');
	timeStamps=newArray(0);
	for (metadataLine = 0; metadataLine<lengthOf(fullMetadata)-1; metadataLine++){
		if (startsWith(fullMetadata[metadataLine], "timestamp #")==true){
			timeStamps=appendToArray(parseFloat(substring(fullMetadata[metadataLine], lengthOf("timestamp #"+nSlices+" = "))),timeStamps);
		}
	}
	
	frameIntervals=newArray(lengthOf(timeStamps)-1);
	for (timeStampIndex=1; timeStampIndex<lengthOf(timeStamps); timeStampIndex++){
		frameIntervals[timeStampIndex-1]=(timeStamps[timeStampIndex]-timeStamps[timeStampIndex-1]);
	}
	Array.getStatistics(frameIntervals, min, max, frameInterval, stdDev); 
	return (frameInterval);
}

//Appends the value to the array
//Returns the modified array
function appendToArray(value, array) {
    temparray=newArray(lengthOf(array)+1);
    for (i=0; i<lengthOf(array); i++) {
        temparray[i]=array[i];
    }
    temparray[lengthOf(temparray)-1]=value;
    array=temparray;
    return array;
}



// automatically get frame intervals from image ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function getFrameIntervalFromImage(imageID){
	selectImage(imageID);
}




////// Match image sizes   ///////////////
function matchImageSize(imageID1, imageID2){// changes the size of imageID1 to match the size of imageID2
	selectImage(imageID2);
	getDimensions(width, height, channels, slices, frames);
	selectImage(imageID1);
	run("Size...", "width="+width+" height="+height+" depth="+nSlices+" interpolation=Bicubic");
}