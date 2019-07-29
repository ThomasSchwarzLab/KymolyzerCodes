// Step2 Track macro
// Select image folder

// initialize ImageJ
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black edm=Overwrite");
run("Line Width...", "line=1");

// parameters 
var dir, name, tmpname, bit,  kymolength, t_dim, boxsize, maxkymolength=10000;
var cor_X=newArray(maxkymolength), cor_Y=newArray(maxkymolength);
var doNotShowBox = 0;

// start : start time point of selected puncta track,  t_duration  number of time points for the puncta track
var start=0,  end=0, t_duration=0;
var total_puncta=0, puncta_count, flag, colorflag;

// X Y position of each track at time point, for selected point in kymo graph at (x,t), 
//the corresponding xy position in real image is posX[t]=cor_X[x], posY[t]=cor_Y[x]
var posX=newArray(maxkymolength), posY=newArray(maxkymolength);

// x y position of individual puncta track in kymograph.
// x value is used to extract X Y position in real image based on cor_X. cor_Y array
var tmpX=newArray(maxkymolength);

// for use of mouse cursor track
leftButton=16;  rightButton=4;  shift=1;  ctrl=2; alt=8; x2=-1; y2=-1; z2=-1; flags2=-1; logOpened = false;     
  
//------------------------------- start main function -------------------------------------


// opening image if not open already 
if (nImages==0){
	// Asking User to select folder //
	dir=getDirectory("Choose Data Folder");
	list=getFileList(dir);
	for(f=0; f<list.length;f++){
		name=list[f];
		if ((endsWith(name, "_kymo.tif")) & ~(endsWith(name, "/"))){
			path = dir+name;
			run("Bio-Formats Importer", "open=[path] color_mode=Default view=Hyperstack stack_order=XYCZT");
			kymoName=name;
			getVoxelSize(pixelResolution, timeResolution, depth, unit);
		}
	}
	imageName=substring(kymoName, 0, indexOf(kymoName, "_kymo.tif"));
	
		
	selectWindow(kymoName);
	applyMaxMinToImage(getImageID());
	setVoxelSize(pixelResolution, timeResolution, 0, unit);
	saveAs("Tiff", dir+imageName+"_kymo.tif");
}



// Processing image
 getVoxelSize(pixelResolution, timeResolution, depth, unit);
 dir=getInfo("image.directory");
 name=getInfo("image.filename");
 t_dim=getHeight(); kymolength=getWidth();

 

 // read XY coordinates.  XY coordinates file is names as filename_kymoline.txt.
 readXYcoordinates();

 // initialization before each puncta selection.
 start_up();

 // input analyze parameters
 parameterinput();

 flag=true;
 while( flag )
  {
    kymo_cal();
    // wait for user to decide if 
    title = "Choice";
    msg = "Check the show window and mito window to see if track result, then click OK \"OK\".";
    if (doNotShowBox==0){
    	waitForUser(title, msg);
    }
    
    flag1=getBoolean("want save this mito track as Puncta Track #"+puncta_count+" ?");
    if( flag1 ) 
       {
        savepuncta();
        puncta_count++;
        
        if( colorflag=="red")   colorflag="green";       
        else if( colorflag=="green")   colorflag="blue"; 
        else colorflag="red"; 

        open(dir+name+"_select.tif");
        if (nSlices>1){
        	MultiChannelRGBImage=getTitle;
        	run("Stack to RGB");
        	close(MultiChannelRGBImage);
        }
        rename("select");
       }
    else
     {
      //close "select.tif, reopen it. 
      selectImage("select"); close();
      if( File.exists(dir+name+"_select.tif") == 1 )
      {
        open(dir+name+"_select.tif");
        if (nSlices>1){
        	MultiChannelRGBImage=getTitle;
        	run("Stack to RGB");
        	close(MultiChannelRGBImage);
        }
        rename("select");
      }
      else
       {  
        // create "select" image" 	
        selectWindow(name);
        run("Duplicate...", "title=1");
        selectWindow(name);
        run("Duplicate...", "title=2");
        selectWindow(name);
        run("Duplicate...", "title=3");
        run("Merge Channels...", "c1=1 c2=2 c3=3");
        selectImage("RGB");
        rename("select");
       }
     }
     
    roiManager("reset");   
    flag=getBoolean("For another track yes/ quit no ?");
  } 
  
 selectWindow("select");
 saveAs("Tiff", dir+name+"_select.tif");
 run("Close All"); 
 
 //---------------------------------------  function line ------------------------------------------------------

// input parameters for calculation
function parameterinput()   
  {
   Dialog.create("Parameter"); 
   Dialog.addNumber("puncta_count start with:", 1);
   Dialog.addChoice("Show Box Size", newArray(15, 10, 5));
   Dialog.show();
   puncta_count = Dialog.getNumber();
   boxsize = Dialog.getChoice();
   
   // set box color for different puncta
   tmp=puncta_count - floor(puncta_count/3)*3;
   if(tmp==1)  colorflag="red";
   if(tmp==2)  colorflag="green";
   if(tmp==0)  colorflag="blue";
  }

// read XY coordinates from the filename_kymoline.txt file.
function readXYcoordinates()
 {
  tmpname=substring(name,0, indexOf(name, "_kymo.tif") );
  tmpname=tmpname+"_kymoline.txt";	
  data = File.openAsString(dir+tmpname);
  datapoints = split(data, "\n");
  
  for (i = 0; i < kymolength; i++)
   {
    tmp = split(datapoints[i], "\t");
    cor_X[i]=parseFloat(tmp[0]);
    cor_Y[i]=parseFloat(tmp[1]);
   }
 }

// set up analyze, 
// duplicate kymo image to "select"
// open raw image for showing the actauly track "show"
function start_up()   
  {
   if( File.exists(dir+name+"_select.tif") == 1 )
    {
     open(dir+name+"_select.tif");
     if (nSlices>1){
        	MultiChannelRGBImage=getTitle;
        	run("Stack to RGB");
        	close(MultiChannelRGBImage);
        }
     rename("select");
    }
   else
    {  
     // create "select" image" 	
     selectWindow(name);
     run("Duplicate...", "title=1");
     selectWindow(name);
     run("Duplicate...", "title=2");
     selectWindow(name);
     run("Duplicate...", "title=3");
     run("Merge Channels...", "c1=1 c2=2 c3=3");
     selectImage("RGB");
     rename("select");
    }
   
   // create "show" image
   tmpname=substring(name,0, indexOf(name, "_kymo.tif") );
   tmpname=tmpname+"_forAnalysis.tif";	
   open(dir+tmpname);
   selectWindow(tmpname);
   run("Thermal");
	run("Enhance Contrast", "saturated=0.5");
   rename("show");
   
   
   for(i=0;i<5000;i++)
    tmpX[i]=-1;
  }

//main analyze kymo
function kymo_cal()
 {
  setTool("hand");
  quit=0;  t_last=-1; doNotShowBox=0;
  selectImage("select");
  showText("Instructions", "Shift+lft Click to add points \n Cntrl+rght click to quit (after adding last point) \n alt+lft click to drop straight line (stationary objects)"); // telling user about click action
  //selectImage(ID_show);
  start_flag=0;
      
  if(getVersion>="1.37r")
    setOption("DisablePopupMenu", true);
    
  while ( quit==0   ) 
   {
    // track cursor position
    getCursorLoc(x, y, z, flags);
    if (x!=x2 || y!=y2 || z!=z2 || flags2!=flags) 
     {    
      // shift+left click: use click the point record the position
      if (flags&shift!=0  && flags&leftButton!=0 ) 
       {     
        if( y <= t_last )
         {
          //print(" please select lager T");
         }  
        
        // if it is the first click  (start_flag)
        if( start_flag==0 )
         {
          
          start=y;   //record start y (mean in t dimention)
          start_flag=1;   // reset start_flag
          tmpX[start]=x;  // x position for start point 

          // set color by colorflag
          if( colorflag=="red")  setColor(255,0,0); 
          if( colorflag=="green") setColor(0,255,0); 
          if( colorflag=="blue")  setColor(0,0,255);
          selectImage("select");
          temp=floor(boxsize/2);
          drawRect(x-temp,y-temp,boxsize,boxsize);    // draw box on user click point the show image    
          t_last=y;  // last point of track (t_last) set here.
         }  // end if( y > t_last  )

        // if it is not he first click, and y (t dimention) is later than the previous t set. 
        if( y > t_last  )
         {
          tmpX[y]=x;   // record y(t) and x postion 
          if( colorflag=="red")  setColor(255,0,0); 
          if( colorflag=="green") setColor(0,255,0); 
          if( colorflag=="blue")  setColor(0,0,255);
          selectImage("select");
          temp=floor(boxsize/2);
          drawRect(x-temp,y-temp,boxsize,boxsize);  //  draw user clicked box on "show"
          // interpolate postion between tow user clicked positions
          for(i=t_last+1; i<y; i++)
           {
            tmpX[i] =round( tmpX[t_last]- (i-t_last)*(tmpX[t_last]-tmpX[y])/(y-t_last) );        
           } 
          t_last=y;
          end=t_last;  // end is the end of the track
         }  // end if( y > t_last  )
       }  // end  if (flags&shift!=0  && flags&leftButton!=0 ) 

      // ctr0l+right click stop the selection 
      if (flags&ctrl!=0 && flags&rightButton!=0   )  
        quit=1;   
        
        
//////////////// Himanish Basu Addition to allow alt + left click///////////////////////////////////////////////////////////////////////////////////////////////////////////


																	     // alt+left click: use click the point record the position
																	      if (flags&alt!=0  && flags&leftButton!=0 ) 
																	       {     
																	        if( y <= t_last )
																	         {
																	          //print(" please select lager T");
																	         }  
																	
																	        
																	        // if it is the first click  (start_flag)
																	        if( start_flag==0 )
																	         {
																	          doNotShowBox=1; // stopping show box feature for stationary mitos
																	          start=y;//record start y (mean in t dimention)
																	          start_flag=1;// reset start_flag
																	   		  tmpX[start]=x;
																	  // x position for start point 
																	
																	          // set color by colorflag
																	          if( colorflag=="red")  setColor(255,0,0); 
																	          if( colorflag=="green") setColor(0,255,0); 
																	          if( colorflag=="blue")  setColor(0,0,255);
																	          selectImage("select");
																	          temp=floor(boxsize/2);
																	          drawRect(x-temp,y-temp,boxsize,boxsize);    // draw box on user click point the show image   
																	 
																	          t_last=y;

																	  // Set Y location as the image height
																	  		y=getHeight()-1;
																	  		t_last=y;
																	        end=t_last;
																	  // interpolate a straight line till bottom of kymograph
																	  		for(i=start+1; i<=y; i++){
																	        	tmpX[i] =x;        
																	           }

																	  // Quit Track
																	  		quit=1;

																	  // last point of track (t_last) set here.
																	         }
																	  // end if( y > t_last  )
																	
																	        
																	        
																	 // if it is not the first click, and y (t dimention) is later than the previous t set. 
																	        if( y > t_last  )
																	         {
																	          tmpX[y]=x;
																	   // record y(t) and x postion 
																	          if( colorflag=="red")  setColor(255,0,0); 
																	          if( colorflag=="green") setColor(0,255,0); 
																	          if( colorflag=="blue")  setColor(0,0,255);
																	          selectImage("select");
																	          temp=floor(boxsize/2);
																	          drawRect(x-temp,y-temp,boxsize,boxsize);  //  draw user clicked box on "show"
																	          // interpolate postion between tow user clicked positions
																	          for(i=t_last+1; i<y; i++)
																	           {
																	            tmpX[i] =round( tmpX[t_last]- (i-t_last)*(tmpX[t_last]-tmpX[y])/(y-t_last) );        
																	           } 
																	          t_last=y;
																	          end=t_last;
																	  // end is the end of the track

																	  // Set Y location as the image height
																	  		y=getHeight()-1;
																	        end=y;
																	        
																	  // interpolate a straight line till bottom of kymograph
																	  		for(i=t_last+1; i<=y; i++){
																	        	tmpX[i] =x;        
																	           }

																	  // Quit Track
																	  		quit=1;
																	         }
																	       }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// /////////////////////////

        
        
        
        
     } // end  if (x!=x2 || y!=y2 || z!=z2 || flags2!=flags) 

    x2=x; y2=y; z2=z; flags2=flags;
    wait(10);

   }  // end while ( quit==0   ) 
   
  // record XY positions for this puncta track to posX and posY
  for(i=start;i<=end;i++)
   {
    posX[i]=cor_X[tmpX[i]];
    posY[i]=cor_Y[tmpX[i]];
    //drawRect(tmpX[i],i,1,1); 
   }
    selectWindow("Instructions");
    run("Close");
  // create visual track file in "show" ; 
  	show_box();
   
 }  // end function 


function show_box()
 {
  roiManager("reset");
  selectImage("show");
  setBatchMode("hide");
  for(i=start;i<=end;i++)
   {
    selectImage("show");
    setSlice(i+1);
    x=posX[i]; y=posY[i];
    temp=floor(boxsize);
    makeOval(x-temp,y-temp,temp*2,temp*2);
    roiManager("Add");
   }
  selectImage("show");
  setBatchMode("exit and display");
  roiManager("Associate", "true"); 
  roiManager("Show All without labels");
 }

// user decide t osave the puncta track.
// draw dots on the puncta track on "select"
// save roi.zip on the "show"     
function savepuncta()
 {
  // draw track dots on "select"
  selectImage("select");
  if( colorflag=="red")  setColor(255,0,0); 
  if( colorflag=="green") setColor(0,255,0); 
  if( colorflag=="blue")  setColor(0,0,255);
  for(i=start;i<=end;i++)
   {
    temp=floor(boxsize/2);
    drawRect(tmpX[i]-temp,i-temp,boxsize,boxsize); 
   }

  // save Puncta roi .zip
  roiManager("Save", dir+name+"_PunctaTrack_"+puncta_count+".zip");
  roiManager("reset");

  selectImage("select");
  saveAs(dir+name+"_select.tif");
  close();
  
  // raw data format is 4 column as
  // timepoint - X position - Y position - x position in Kymograph (use to decide move direction)
  print("\\Clear");
  for(i=start;i<=end;i++)
   print(i+"	"+posX[i]+"	"+posY[i]+"	"+tmpX[i]);
  selectWindow("Log");
  saveAs("Text", dir+name+"_Puncta_"+puncta_count+"_raw.txt");
  selectWindow("Log");
  NewDirForPuntaFiles = dir+"RawPunctaFiles"+File.separator;
  File.makeDirectory(NewDirForPuntaFiles);
  saveAs("Text", NewDirForPuntaFiles+name+"_Puncta_"+puncta_count+"_raw.txt");
  selectWindow("Log"); run("Close");
 }
//////////////////////////HB Functions///////////////////////////////////
 // Function to apply brightness and contrast to image///////////////////
function applyMaxMinToImage(imageID){
	selectImage(imageID);
	bit=bitDepth();
	name=getTitle();
	metadata=getMetadata("Info");
	run("Copy to System");
	run("System Clipboard");
	run(bit+"-bit");
	setMetadata("Info", metadata);
	selectImage(imageID);
	close();
	rename(name);
}