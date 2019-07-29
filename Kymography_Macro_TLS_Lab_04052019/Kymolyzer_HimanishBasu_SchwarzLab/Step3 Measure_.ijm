// Step3 Measure macro
// Press run and select image folder
// resultfile save in the same folder

// initialize ImageJ
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black edm=Overwrite");

// parameters
// pixelscale : um/pixel   timegap : time between each frame   speed_limitL : lowest speed limit  um/s, if speed lower than this, consider puncta as still
// cal_gap  calcualte every "cal_gap"  time points  if cal_gap, only calculate time points 1,4,7,10,...

var dir, name, pixelscale, timegap, speed_limitL, cal_gap, width, height, track_index, track_name;

// start_T : start time point of selected puncta track,  end_T is the end time point.  total time points "count" is end_T - start_T +1
var start_T=0, end_T=0, count;

// X Y position of each track at time point, index 0 corresponding to start T point
var posX=newArray(5000), posY=newArray(5000), T=newArray(5000);

//x position Kymo graph indicate move direction.
var dirX=newArray(5000);

//------------------------------- start main function -------------------------------------

dir=getDirectory("Choose Data Folder");
list=getFileList(dir);

// User might have selected the parent data folder; In that case change "dir" variable to the dir + "rawPunctaFiles"
if (File.isDirectory(dir+File.separator+"RawPunctaFiles"+File.separator)){
	dir=dir+File.separator+"RawPunctaFiles"+File.separator;
}

 // input analyze parameters
 parameterinput();

 //print header for analysis result file for this puncta
 printheader();
 track_index=0;    
 for(f=0; f<list.length;f++)
  {
   name=list[f];
   if(indexOf(name, "_Puncta_")>0 && endsWith(name, "_raw.txt")){
     track_name = substring(name, indexOf(name, "_Puncta_")+8, indexOf(name, "_raw.txt"));
     
     // read into each timepoints with X Y position and Kymo x position 	
     readParameters();    
     
     // charactors array for each calculated time points.  
     // parameter of segment from timpoints i-1 to i    is save in Array[i] 
     Speed=newArray(count); Move=newArray(count); Direction=newArray(count); Distance=newArray(count); Stop=newArray(count); Reverse=newArray(count);
     forward_length=0; backward_length=0; move=0; still=0; forward=0; backward=0; stop=0; reverse=0;
     tmpspeed=0; tmp=0;

     // x0, y0 are the previous position  
     // in the loop x1, y1 is the current position
     x0=posX[0]; y0=posY[0];
     previous_dir=0;  dir_flag=0;
     // for every cal_gap points,  reall index in raw data is i
     for(i=1; i< count; i++)
      {
      	// x1 y1 is the current position  
        x1=posX[i]; y1=posY[i];
        
        // calculate distance
        Distance[i]=sqrt( (x1-x0)*(x1-x0) + (y1-y0)*(y1-y0) )*pixelscale;

        //calculate speed, if speed < speed limit, then speed as 0 
        tmpspeed=Distance[i]/(timegap*cal_gap);
        if( tmpspeed >= speed_limitL) 
          { 
            Speed[i]=tmpspeed ; 
            Move[i] = 1; move++;
            if( dirX[i] > dirX[i-1] ) { Direction[i]=1; forward++; forward_length=forward_length+Distance[i]; }
            if( dirX[i] < dirX[i-1] ) { Direction[i]=-1; backward++; backward_length=backward_length+Distance[i]; }
          }
          
        if( tmpspeed < speed_limitL) 
          { 
            Speed[i]=0 ; 
            Move[i] = 0; still++;
            Direction[i]=0; 
          }

        //calculate stop 
        //previous two period moves in same direction, and current is still then count as stop
         if( i>2 )
         if( Direction[i]==0 && Direction[i-1]*Direction[i-2] > 0 )
           { stop++; Stop[i]=1; }

        // calculate reverse;
        // two consective same direction set as previous direction.  
        // set first previous_dir
        if( i>=2 && dir_flag==0 )
         {
          if( Direction[i-1]*Direction[i] > 0 )
            {
             previous_dir = Direction[i];
             dir_flag = 1;
            }	
         }
        // count reverse
        if( i >= 4 && dir_flag == 1 )
         {
          if( Direction[i-1] * Direction[i] > 0 && Direction[i] != previous_dir )
           {
            reverse++; 
           	previous_dir = Direction[i];
           }
         }

     	x0=x1; y0=y1;  
      } // end  for(i=1; i< count ; i++)

     totalsegment=still+move;
     total_length=forward_length+backward_length; aveSpeed=total_length/(move*timegap*cal_gap); 
     
     if( forward > 0 ) 
       aveForwardSpeed=forward_length/(forward*timegap*cal_gap); 
     else
       aveForwardSpeed=0;

     if( backward > 0 ) 
       aveBackwardSpeed=backward_length/(backward*timegap*cal_gap);
     else
       aveBackwardSpeed=0;

     moveF=move/totalsegment*100; stillF=still/totalsegment*100;
     forwardF=forward/totalsegment*100;  backwardF=backward/totalsegment*100;  
     stopF=stop/totalsegment*100; reverseF=reverse/totalsegment*100 ;
     netmove= forward_length-backward_length;
     if( abs(netmove) < 0.0001 )  netmove = 0 ;
     //print("Puncta#	StartTimePoint	EndTimePoint	TotalSegment	Total_Move# Total_Move_Length(um)	Average Speed(um/s)	Move%	Still	Still%	Move_Forward# Forward_Length(um) Ave_Forward_Speed(um/s)	Forward%	Move_Backward#	Backward_Length(um)	Ave_Backward_Speed(u/s)	Backward%	Stop#	Stop%	Reverser#	Reverse% NetMovement(F-B)");
     print(list[f]+"	"+start_T+"	"+end_T+"	"+totalsegment+"	"+move+"	"+total_length+"	"+aveSpeed+"	"+moveF+"	"+still+"	"+stillF+"	"+forward+"	"+forward_length+"	"+aveForwardSpeed+"	"+forwardF+"	"+backward+"	"+backward_length+"	"+aveBackwardSpeed+"	"+backwardF+"	"+stop+"	"+stopF+"	"+reverse+"	"+reverseF+"	"+netmove);
     
    } // end if( indexOf(name, ".txt") >0 )
  } // end for(f=0; f<list.length;f++)

selectWindow("Log");
saveAs("Text", dir+"Summary.xls");
//saveAs("Text", dir+"Summary.csv");
run("Close");

roiManager("Save", dir+"Track_ROI.zip");
roiManager("reset");
selectImage("track");
close();

//---------------------------------------  function line ------------------------------------------------------

// input parameters for calculation
function parameterinput()   
  {
  directoryHavingKymoFile=replace(dir, "([a-zA-Z0-9_.-]+)\\"+File.separator+"$", ""); 
			fileList=getFileList(directoryHavingKymoFile);
			kymoImageFound=0;
			for (FileNumber=0; FileNumber<fileList.length; FileNumber++) {	
				if (endsWith(fileList[FileNumber], "_kymo.tif")==1){
					open(directoryHavingKymoFile+fileList[FileNumber]);
				kymoImageFound=1;
				}
			}
			if (kymoImageFound==1){
				getPixelSize(unit, PixelScaleDefault, TimeScaleDefault);
				KymoHeightDefault=getHeight();
				KymoWidthDefault=getWidth();
				close();
			}
			if (kymoImageFound==0){
				PixelScaleDefault=1;
				TimeScaleDefault=1;
				KymoHeightDefault=1;
				KymoWidthDefault=1;				
			}
			
   Dialog.create("Scale Parameter"); 
   Dialog.addNumber("PixelScale (um/pixel):", PixelScaleDefault);
   Dialog.addNumber("TimeScale (s):", TimeScaleDefault);
   Dialog.addNumber("Kymo width (pixel):", KymoWidthDefault);
   Dialog.addNumber("Kymo height (pixel):", KymoHeightDefault);
   Dialog.show();
   
   pixelscale = Dialog.getNumber();
   timegap = Dialog.getNumber();
   width = Dialog.getNumber();
   height = Dialog.getNumber();
   stepGapInSeconds=5;
   stepGapInFrames=round(stepGapInSeconds/timegap+0.1);

   Dialog.create("Analyze parameter"); 
   Dialog.addMessage("Default Speed Limit Low will exclude one pixel movement");
   Dialog.addNumber("Speed Limit Low(um/s):", 0.15);
   Dialog.addNumber("Calculate step (every ?? time points):", stepGapInFrames);
   Dialog.show();
   speed_limitL = Dialog.getNumber();
   cal_gap = Dialog.getNumber();

   newImage("track", "8-bit black", width, height, 1);
  }

// read XY coordinates and x pisition on kymo fro raw txt file
function readParameters()
 {
  data = File.openAsString(dir+name);
  datapoints = split(data, "\n");
  count=0; i=0;
  // get data every cal_gap time points. total of "count" data points
  for (j = 0; j < datapoints.length; j=j+cal_gap)
   {
    tmp = split(datapoints[j], "\t");
    if( i== 0 ) start_T = parseFloat(tmp[0]);
    T[i]=parseFloat(tmp[0]);
    posX[i]=parseFloat(tmp[1]);
    posY[i]=parseFloat(tmp[2]);
    dirX[i]=parseFloat(tmp[3]);
    count++;

    if( i>0 )
      //drawLine( dirX[i-1], T[i-1], dirX[i], T[i]);
      drawLine( dirX[i-1], T[i-1], dirX[i], T[i]);
    i++;  
   }

  // create roi for this track
  selectImage("track");
  run("Analyze Particles...", "size=0-infinity add");
  roiManager("Select", track_index);
  roiManager("Rename", track_name);
  roiManager("Select", track_index);
  roiManager("Deselect");
  run("Select None");
  run("Multiply...", "value=0");
  track_index++;
     
  tmp = split(datapoints[datapoints.length - 1], "\t");
  end_T = parseFloat(tmp[0]);
 }


// print Log window header for each pucnta track
function printheader()
 {
  print("\\Clear");  // clear Log window 	
  print("TrackRawFileFolder:	"+dir);
  print("XY Unit(um):	"+pixelscale+"	T Unit(s):	"+timegap+"	Speed_Limit_Low(um/s):	"+speed_limitL+"	CalGap:	"+cal_gap);
  print("\n");

  print("Puncta#	StartTimePoint	EndTimePoint	TotalSegment	Total_Move#	Total_Move_Length(um)	Average Speed(um/s)	Move%	Still	Still%	Move_Forward#	Forward_Length(um)	Ave_Forward_Speed(um/s)	Forward%	Move_Backward#	Backward_Length(um)	Ave_Backward_Speed(u/s)	Backward%	Stop#	Stop%	Reverser#	Reverse%	NetMovement(F-B)");
 }
   



