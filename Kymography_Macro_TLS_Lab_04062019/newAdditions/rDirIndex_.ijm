// Recursively get all files //
dir = getDirectory("Choose a Directory ");
allFiles=rDirIndex(dir); 


// Keep unique files only //
print("\\Clear");
print("Remving Non-Unique Files"); // printing update	
allFilesUnique=newArray();
for (fileCount=0; fileCount<allFiles.length; fileCount++) {
	numberofPreviousOccurances= occurencesInArray (allFilesUnique, allFiles[fileCount]);
	if (numberofPreviousOccurances==0){
		allFilesUnique=Array.concat(allFilesUnique,allFiles[fileCount]);
	}
}
print("\\Update:"+"Done!"); // printing update	
allFiles=allFilesUnique;
Array.show(allFiles);



function rDirIndex(dir){
	subDirs=getSubDirectoryList(dir);
	files=getfileList_WO_Subdirectories(dir);
	print("\\Clear");
	while (lengthOf(subDirs)>0) {
		subDirsOld=subDirs;
		for (i=0; i<subDirs.length; i++) {
			print("ScanningFolder:"+subDirs[i]); // printing update		
			subDirsTmp=getSubDirectoryList(subDirs[i]);
			filesTmp=getfileList_WO_Subdirectories(subDirs[i]);
			subDirs=Array.concat(subDirs,subDirsTmp);
			files=Array.concat(files,filesTmp);
		}
		subDirs=Array.slice(subDirs, lengthOf(subDirsOld)); // Remove old subdirectories from array
	}
	return files;
}



function getSubDirectoryList(dir) {
	subDirs=newArray();
  	list = getFileList(dir);
  	for (i=0; i<list.length; i++) {
     	if (endsWith(list[i], "/"))
        	subDirs=Array.concat(subDirs,dir+list[i]);
     	}
   return subDirs;
}


function getfileList_WO_Subdirectories(dir) {
  	files=newArray();
    list = getFileList(dir);
    for (i=0; i<list.length; i++) {
       if (endsWith(list[i], "/"))
          subDirs=Array.concat(subDirs,dir+list[i]);
       else
          files=Array.concat(files,dir+list[i]);
     }
     return files;
}



//Returns the number of times the value occurs within the array
function occurencesInArray (array, value){
    count=0;
    for (a=0; a<lengthOf(array); a++) {
        if (array[a]==value) {
            count++;
        }
    }
    return count;
}