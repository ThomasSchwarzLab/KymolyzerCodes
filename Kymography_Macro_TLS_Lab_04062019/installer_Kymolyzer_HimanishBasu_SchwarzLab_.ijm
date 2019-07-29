////////////////////////////////////////////////////////////////
//
//
// Getting macro directory //
sourceDirectory=getInfo("macro.filepath");
sourceDirectory=File.getParent(sourceDirectory) + File.separator + "Kymolyzer_HimanishBasu_SchwarzLab" + File.separator;
if (indexOf(sourceDirectory, "AutoRun")>1){
	sourceDirectory=File.openDialog("choose installer file");
	sourceDirectory=File.getParent(sourceDirectory) + File.separator + "Kymolyzer_HimanishBasu_SchwarzLab" + File.separator;
}
print(sourceDirectory);
/////////////////////////////////////////////////////////////////
//
//
//
///////////////////////////////////////////////
//
//
//
// creating installation directory and path //
installationDirectory=getDirectory("plugins")+ File.separator+ "Macros"+ File.separator+"Kymolyzer" + File.separator;
if (File.exists(installationDirectory)){
	// Delete Directory if it already exists //
  list = getFileList(installationDirectory);
  for (i=0; i<list.length; i++){
	ok = File.delete(installationDirectory+list[i]);  		
  }
  ok = File.delete(installationDirectory);    
  
  if (File.exists(installationDirectory))
      exit("Unable to delete previous installation directory");
  else
      print("Previous installation directory and files successfully deleted");
}
print(installationDirectory);
File.makeDirectory(installationDirectory);
// copying to installation directory and path //
list = getFileList(sourceDirectory);
for (FileNumber=0; FileNumber<list.length; FileNumber++) {
	if (endsWith(list[FileNumber], ".ijm")){ // only processing .ijm files
		sourcePath = sourceDirectory+list[FileNumber];
		installationPath= installationDirectory+list[FileNumber];
		File.copy(sourcePath, installationPath);
		//run("Install... ", "install=["+sourcePath+"] save=["+installationPath+"]");
	}
}
////////////////////////////////////////////////////////////////////
//
//
//run("Quit"); 
showMessage("Please Resart ImageJ and run Macro > Kymolyzer")