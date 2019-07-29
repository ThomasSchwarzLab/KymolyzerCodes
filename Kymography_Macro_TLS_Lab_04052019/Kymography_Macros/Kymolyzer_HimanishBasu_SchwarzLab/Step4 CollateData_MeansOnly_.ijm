print("\\Clear");  // clear Log window 
print("Name	Move%	Average Speed(um/s)	Forward%	Backward%	Pixel Size(um)	Frame Rate (fps)	Lower Speed Limit (um/s)	Frame Skip Gap (frames)	Frame Skip Gap (seconds)	First Line of Headers in Summary Table (line number)");
moreFiles=true;
while (moreFiles==true){
	if(moreFiles==true){
		path=getDirectory("choose data folder");	
		path=path+"RawPunctaFiles"+File.separator+"Summary.xls";
		if (File.exists(path)==true){
			lineseparator = "\n";
		    cellseparator = ",\t";
			
			
			lines=split(File.openAsString(path), lineseparator);
			
		
		     // reading name of file, pixel size, frame Rate, lower speed limit, and frame skip gap  and deleting first few gap lines
		     //Name
		     name=split(lines[0], cellseparator);
		     name=File.getParent(name[1]);
		     //other info
		     otherInfo=split(lines[1], cellseparator);
		     pixelSize=parseFloat(otherInfo[1]);
		     frameRate=1/parseFloat(otherInfo[3]);
		     lowerSpeedLimit=parseFloat(otherInfo[5]);
		     frameSkipGap=parseFloat(otherInfo[7]);
		     frameSkipGapInSeconds=frameSkipGap/frameRate;

		     
			 name=File.getName(name);
		     
		     
		     // Deleting gap lines
		     firstLineOfHeaders=3; // considering the first line of header to be the third line
		     lines= Array.slice(lines,(firstLineOfHeaders-1)); // removing first two lines (containg meta info)
		     while (lengthOf(lines[0])<3){ // while the first line of the table doesnt contain anything (i.e. length is less than 3)
		     	firstLineOfHeaders=firstLineOfHeaders+1; // setting the line of header to be the next line
		     	lines= Array.slice(lines,1); // removing the first line from the table
		     }
		     
			 
		     
		     
		     // reading rest of the lines into table format with first line as headers
		
		     
			 // recreates the columns headers
		     labels=split(lines[0], cellseparator);
		     if (labels[0]==" ")
		        k=1; // it is an ImageJ Results table, skip first column
		     else
		        k=0; // it is not a Results table, load all columns
		     for (j=k; j<labels.length; j++)
		        setResult(labels[j],0,0);
		
		     // dispatches the data into the new RT
		     run("Clear Results");
		     for (i=1; i<lines.length; i++) {
		        items=split(lines[i], cellseparator);
		        for (j=k; j<items.length; j++){
		        	if (j==k){setResult(labels[j],i-1,items[j]);}
		        	if (j>k){setResult(labels[j],i-1,parseFloat(items[j]));}
		        }
		     }
		     updateResults();
		     numberOfResultLines=nResults;
		
		
	
		     
		    // Means for movement percent //
			column="Move%";
			tmpArr=newArray();
			for (i=1; i<lines.length; i++) {
				tmpVar=getResult(column,i-1);
				if (isNaN(tmpVar)==0){tmpArr=Array.concat(tmpArr,tmpVar);}
			}
			Array.getStatistics(tmpArr, tmpArrMin,tmpArrMax,tmpArrMean,tmpArrSD);
			MovPercent=tmpArrMean;
			////////////////////////////////
		
		
		
			
			
			// Means for avarage speed //
			column="Average Speed(um/s)";
			tmpArr=newArray();
			for (i=1; i<lines.length; i++) {
				tmpVar=getResult(column,i-1);
				if (isNaN(tmpVar)==0){tmpArr=Array.concat(tmpArr,tmpVar);}
			}
			Array.getStatistics(tmpArr, tmpArrMin,tmpArrMax,tmpArrMean,tmpArrSD);
			avgSpeed=tmpArrMean;
			////////////////////////////////
		
		
		
		    
		    
		    
		    
		    // Means for Anterograde percent //
			column="Forward%";
			tmpArr=newArray();
			for (i=1; i<lines.length; i++) {
				tmpVar=getResult(column,i-1);
				if (isNaN(tmpVar)==0){tmpArr=Array.concat(tmpArr,tmpVar);}
			}
			Array.getStatistics(tmpArr, tmpArrMin,tmpArrMax,tmpArrMean,tmpArrSD);
			AnteroPercent=tmpArrMean;
			////////////////////////////////
		
		
		
		    // Means for Retrograde percent //
			column="Backward%";
			tmpArr=newArray();
			for (i=1; i<lines.length; i++) {
				tmpVar=getResult(column,i-1);
				if (isNaN(tmpVar)==0){tmpArr=Array.concat(tmpArr,tmpVar);}
			}
			Array.getStatistics(tmpArr, tmpArrMin,tmpArrMax,tmpArrMean,tmpArrSD);
			RetroPercent=tmpArrMean;
			////////////////////////////////
		
			print(name+"	"+MovPercent+"	"+avgSpeed+"	"+AnteroPercent+"	"+RetroPercent+"	"+pixelSize+"	"+frameRate+"	"+lowerSpeedLimit+"	"+frameSkipGap+"	"+frameSkipGapInSeconds+"	"+firstLineOfHeaders);
		}
		moreFiles=getBoolean("more files to add?");
	}
}




savingDirectory=getDirectory("Choose a Directory to save in");
fileName=getString("Enter a file name:", "collatedMeans");
selectWindow("Log");  //select Log-window 
saveAs("text", savingDirectory+fileName+".xls");

