dir=getDirectory("Choose Data Folder");
list=recursiveSubFolderIndexing(dir);


function recursiveSubFolderIndexing(dir) {
	// Getting all folders //
	print("\\Clear");
	print("Getting all Folders"); // printing update	
	subDirectories=getSubDirectoryList(dir);
	for (loopNumber=0; loopNumber<9; loopNumber++) {
		// Getting all subfolders of folder list //
		print("Level: "+ loopNumber);
		subDirectoriesTmp=newArray();
		for (i=0; i<subDirectories.length; i++) {
			subDirectoriesCurrent=getSubDirectoryList(subDirectories[i]);
			subDirectoriesTmp=Array.concat(subDirectoriesTmp,subDirectoriesCurrent);
		}
		subDirectories=Array.concat(subDirectoriesTmp,subDirectories);
	
		// Keep unique Folders only (removes folders that have repeated above) //
		print("Remving Non-Unique Files"); // printing update	
		allFoldersUnique=newArray();
		for (folderCount=0; folderCount<subDirectories.length; folderCount++) {
			numberofPreviousOccurances= occurencesInArray(allFoldersUnique, subDirectories[folderCount]);
			if (numberofPreviousOccurances==0){
				allFoldersUnique=Array.concat(allFoldersUnique,subDirectories[folderCount]);
			}
		}
		print("\\Update:"+"Done!"); // printing update	
		subDirectories=allFoldersUnique;
	}
	return subDirectories;
}


// Returns only subdirectories //
function getSubDirectoryList(dir) {
	subDirs=newArray();
	list = getFileList(dir);
  	for (i=0; i<list.length; i++) {
     	if (endsWith(list[i], "/"))
        	subDirs=Array.concat(subDirs,dir+list[i]);
     	}
   return subDirs;
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
