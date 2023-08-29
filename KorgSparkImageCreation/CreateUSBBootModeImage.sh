#!/bin/bash

# -------------------------------------------------------------------------
#
#	CreateUSBBootModeImage.sh
#
#	This script assumes that the developer has downloaded the resource 
#	from Google Drive onto their local ~/Development folder. Some dialogs
#	wil start the script to make sure.
#
#	The UpdatersFolder will be assigned the path to where the rootfs files
#	for the selected product's updaters live.
# -------------------------------------------------------------------------
DialogTitleText="SparkPi USB Boot Mode Image Creator"
ImageType=1
S99UpdateScriptFile=""
S99FactoryScriptFile=""
UpdatersFolder=""
SelectedProductName=""
RootfsFilePath=""
ReleaseString=""
NewTarballMD5Sum=""
RestoreZipFile=""
ButtonsToHold=""
InstructionsImageFile=""
IncompatibleProducts=""

# default the architecture to whatever is most common.
Architecture="cm4"

UpdateRestoreFileName=""
TargetUpdaterKernelFileName="updater-kernel.img"
TargetUpdaterInitRamFSFileName="updater-scriptexecute.img"
FactoryUpdateBootFilesZipFile=""

EtcSourcePath="../scriptexecute/board/overlay/etc"
UpdateContentSourcePath="${EtcSourcePath}/updatecontent"
CurrentBuildRootPath="../buildroot-2019.11.1"
LogFile="/tmp/SparkPiBootModeImageLog"
ResourcesDir="${HOME}/Development/USBBootModeImageResources"
ImageTypeSelectionFile="/tmp/SparkPiUSBBootModeImageTypeSelection"
ProductSelectionFile="/tmp/SparkPiUSBBootModeProductSelection"
RlsDirsFile="/tmp/TempRlsDirs"
SelectedRlsFile="/tmp/SparkPiUSBBootModeSelectedRls"
TempCreationFolder="/tmp/SparkPiTempUSBBootModeRls"
TempUpdateRootfsFolder="/tmp/SparkPiTempUSBBootModeRootfs"
ReadMeFile="${ResourcesDir}/readme.txt"

# dialog exit status codes
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

# ---------------------------------------------------
# PostCleanUpTempFiles()
# ---------------------------------------------------
PostCleanUpTempFiles()
{
	rm -f $ImageTypeSelectionFile
	rm -f $ProductSelectionFile
	rm -f $SelectedRlsFile
	rm -fr $RlsDirsFile
	rm -fr $TempCreationFolder
	rm -fr $TempUpdateRootfsFolder
}

# ---------------------------------------------------
# CleanUpTempFiles()
# ---------------------------------------------------
CleanUpTempFiles()
{
	rm -f $LogFile
	rm -f $ImageTypeSelectionFile
	rm -f $ProductSelectionFile
	rm -f $SelectedRlsFile
	rm -fr $RlsDirsFile
	rm -fr $TempCreationFolder
	rm -fr $TempUpdateRootfsFolder
}

# ---------------------------------------------------
# ExitWithErrorDialog()
#
#	This takes a string argument ($1) to display in
#	a dialog and then exits.
# ---------------------------------------------------
ExitWithErrorDialog()
{
	dialog --title "$DialogTitleText" \
		--msgbox "$1" 0 0
	clear
	exit -1
}

# ---------------------------------------------------
# CheckResources()
# ---------------------------------------------------
CheckResources()
{
	if [ ! -d "$ResourcesDir" ]; then
		ExitWithErrorDialog "Missing Resources in $ResourcesDir.\n Consult the README.txt file for details on resolving this."
	fi

	ResourceCheckText="Please be sure that the resources under\n $ResourcesDir are up-to-date.\n\nAre you sure you want to continue?"

	dialog --clear --title "$DialogTitleText" \
		--yesno "$ResourceCheckText" 10 60

	response=$?
	case $response in
		$DIALOG_ESC) exit -1;;
		$DIALOG_CANCEL) exit -2;;
	esac
}

# ---------------------------------------------------
# SelectImageType()
# ---------------------------------------------------
SelectImageType()
{
	rm -f $ImageTypeSelectionFile

	dialog	--clear --backtitle "$DialogTitleText" --title "Select Image Type:" \
		--menu "" \
		20 60 5 \
		"1" "Restore Plus Update" \
		"2" "Factory Updater Kernel/Initramfs" \
		2> $ImageTypeSelectionFile

	response=$?
	case $response in
		$DIALOG_ESC) exit -1;;
		$DIALOG_CANCEL) exit -2;;
	esac

	ImageType=`cat $ImageTypeSelectionFile`
}

# ---------------------------------------------------
# SelectProduct()
# ---------------------------------------------------
SelectProduct()
{
	rm -f $ProductSelectionFile

	dialog	--clear --backtitle "$DialogTitleText" --title "Select Product:" \
		--menu "" \
		20 40 5 \
		"1" "wavestate CM3" \
		"2" "wavestate mkII" \
		"3" "wavestate SE" \
		"4" "wavestate module" \
		"5" "modwave CM3" \
		"6" "modwave CM4" \
		"7" "multipoly" \
		"8" "opsix CM3" \
		"9" "opsix mkII" \
		2> $ProductSelectionFile

	response=$?
	case $response in
		$DIALOG_ESC) exit -1;;
		$DIALOG_CANCEL) exit -2;;
	esac

	productSelectionMenuChoice=`cat $ProductSelectionFile`

	case $productSelectionMenuChoice in
		1)
			UpdatersFolder="$HOME/Development/Spark/Products/Wavest8/Util/Updaters/wavestate_cm3"
			SelectedProductName="Korg wavestate (CM3)"
			XMLProductName="wavestate (original)"
			UpdateRestoreFileName="wavestate_usb_boot_"
			Architecture="cm3"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdater_wavestateCM3"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExec_wavestateCM3"
			RestoreZipFile="$ResourcesDir/wavestateCM3/bootRestorewavestateCM3.zip"
			TargetUpdaterKernelFileName="kernel.img"
			TargetUpdaterInitRamFSFileName="scriptexecute.img"
			FactoryUpdateBootFilesZipFile="wavestateCM3FactoryUpdateBootFiles.zip"
			ButtonsToHold="PERFORMANCE MOD KNOBS, MASTER, NOTE ADVANCE"
			InstructionsImageFile="$ResourcesDir/images/wavestateUSBBootButtons.png"
			IncompatibleProducts="wavestate SE, wavestate mkII"
			;;
		2)
			UpdatersFolder="$HOME/Development/Spark/Products/Wavest8/Util/Updaters/wavestate_cm4"
			SelectedProductName="wavestate mkII"
			XMLProductName="wavestate mkII"
			UpdateRestoreFileName="wavestate_mkII_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/wavestateMkII/bootRestoreWavestateMkII.zip"
			FactoryUpdateBootFilesZipFile="wavestateCM4FactoryUpdateBootFiles.zip"
			ButtonsToHold="PERFORMANCE MOD KNOBS, MASTER, NOTE ADVANCE"
			InstructionsImageFile="$ResourcesDir/images/wavestateUSBBootButtons.png"
			IncompatibleProducts="wavestate (original), wavestate SE"
			;;
		3)
			UpdatersFolder="$HOME/Development/Spark/Products/Wavest8/Util/Updaters/wavestate_cm4"
			SelectedProductName="wavestateSE_M"
			XMLProductName="wavestate SE"
			UpdateRestoreFileName="wavestate_SE_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/commonCM4/bootRestoreCM4.zip"
			FactoryUpdateBootFilesZipFile="wavestateCM4FactoryUpdateBootFiles.zip"
			ButtonsToHold="PERFORMANCE MOD KNOBS, MASTER, NOTE ADVANCE"
			InstructionsImageFile="$ResourcesDir/images/wavestateUSBBootButtons.png"
			IncompatibleProducts="wavestate (original), wavestate mkII"
			;;
		4)
			UpdatersFolder="$HOME/Development/Spark/Products/Wavest8/Util/Updaters/wavestate_cm4"
			SelectedProductName="wavestateSE_M"
			XMLProductName="wavestate module"
			UpdateRestoreFileName="wavestate_module_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/commonCM4/bootRestoreCM4.zip"
			FactoryUpdateBootFilesZipFile="wavestateCM4FactoryUpdateBootFiles.zip"
			ButtonsToHold="PERFORMANCE MOD KNOBS, MASTER, NOTE ADVANCE"
			InstructionsImageFile="$ResourcesDir/images/wavestateUSBBootButtons.png"
			IncompatibleProducts="wavestate (original), wavestate mkII"
			;;
		5)
			UpdatersFolder="$HOME/Development/Spark/Products/Dwx/Util/Updaters/modwave_cm3"
			SelectedProductName="modwaveCM3"
			XMLProductName="modwave"
			UpdateRestoreFileName="modwave_usb_boot_"
			Architecture="cm3"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/modwaveCM3/bootRestoremodwaveCM3.zip"
			FactoryUpdateBootFilesZipFile="modwaveFactoryUpdateBootFiles.zip"
			ButtonsToHold="HOLD, FILTER (ENVELOPE), FILTER TYPE"
			InstructionsImageFile="$ResourcesDir/images/modwaveUSBBootButtons.png"
			IncompatibleProducts=""
			;;
		6)
			UpdatersFolder="$HOME/Development/Spark/Products/Dwx/Util/Updaters/modwave_cm4"
			SelectedProductName="modwaveCM4"
			XMLProductName="modwave mkII"
			UpdateRestoreFileName="modwave_mkII_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/modwaveCM4/bootRestoremodwaveCM4.zip"
			FactoryUpdateBootFilesZipFile="modwaveFactoryUpdateBootFiles.zip"
			ButtonsToHold="HOLD, FILTER (ENVELOPE), FILTER TYPE"
			InstructionsImageFile="$ResourcesDir/images/modwaveUSBBootButtons.png"
			IncompatibleProducts="modwave"
			;;
		7)
			UpdatersFolder="$HOME/Development/Spark/Products/Mpx/Util/Updaters"
			SelectedProductName="multipoly"
			XMLProductName="multipoly"
			UpdateRestoreFileName="multipoly_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/multipolyCM4/bootRestoremultipolyCM4.zip"
			FactoryUpdateBootFilesZipFile="multipolyFactoryUpdateBootFiles.zip"
			ButtonsToHold="UTIL"
			InstructionsImageFile="$ResourcesDir/images/multipolyUSBBootButtons.png"
			;;
		8)
			UpdatersFolder="$HOME/Development/Spark/Products/Operator6/Util/Updaters"
			SelectedProductName="opsix CM3"
			XMLProductName="Korg opsix"
			UpdateRestoreFileName="opsix_usb_boot_"
			Architecture="cm3"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/opsixCM3/bootRestoreopsixCM3.zip"
			FactoryUpdateBootFilesZipFile="opsixCM3FactoryUpdateBootFiles.zip"
			InstructionsImageFile="$ResourcesDir/images/opsixUSBBootButtons.png"
			;;
		9)
			UpdatersFolder="$HOME/Development/Spark/Products/Operator6/Util/Updaters"
			SelectedProductName="opsixMkII"
			XMLProductName="opsix mkII"
			UpdateRestoreFileName="opsix_mkII_usb_boot_"
			S99UpdateScriptFile="$ResourcesDir/scripts/S99scriptexecUpdaterV1"
			S99FactoryScriptFile="$ResourcesDir/scripts/S99FactoryScriptExecV1"
			RestoreZipFile="$ResourcesDir/opsixCM4/bootRestoreopsixCM4.zip"
			FactoryUpdateBootFilesZipFile="opsixCM4FactoryUpdateBootFiles.zip"
			InstructionsImageFile="$ResourcesDir/images/opsixUSBBootButtons.png"
			;;
	esac
}

# ---------------------------------------------------
# ScanProductUpdatersDirectories()
# ---------------------------------------------------
ScanProductUpdatersDirectories()
{
	# $1 is the path to the directory. Assemble all available release directories
	AllDirsString=$(find "$1" -maxdepth 1 -mindepth 1 -type d  | xargs -L1 -I{} basename "{}")

	AllReleaseDirs=()
	IFS=$'\n' read -d '' -r -a AllReleaseDirs <<< "$AllDirsString"

	# Create a temporary file for presenting the dialog
	rm -f $RlsDirsFile
	directoryIndex=0
	for rlsEntry in "${AllReleaseDirs[@]}"; do
		let directoryIndex++
		echo "	\"$directoryIndex\" \""${rlsEntry}"\" \\" >> $RlsDirsFile
	done

	dialog	--clear --backtitle "SparkPi Programmer App/Firmware tarball Creator" --title "Select ${SelectedProductName} Release:" \
		--cancel-label "Cancel" \
		--menu "" \
		20 40 5 \
		--file $RlsDirsFile \
		2> $SelectedRlsFile

	response=$?
	case $response in
		$DIALOG_ESC) exit -1;;
		$DIALOG_CANCEL) exit -2;;
	esac

	# take the selected version number and update the strings we will use to access the rootfs
	#	file and make the target tarball
	selectedIndex=`cat $SelectedRlsFile`
	# adjust for zero based index
	let selectedIndex--
	ReleaseString="${AllReleaseDirs[selectedIndex]}"
	RootfsFilePath="$UpdatersFolder/$ReleaseString/rootfs.tgz"
}

# ---------------------------------------------------
# VerifySelectedFileExists()
#	$1 is the filepath to check
#	$2 is the error message if the file is not found.
# ---------------------------------------------------
VerifySelectedFileExists()
{
	# verify that the passed in file exists. If not, just bail with an informational message as to why.
	if [ ! -f "${1}" ]; then
		ExitWithErrorDialog "$2"
	fi
}

# ---------------------------------------------------
# SelectPrePostTarScripts()
# ---------------------------------------------------
SelectPrePostTarScripts()
{
	# first ask whether there will be a pretar.sh file. It is expected to be in the specific folder
	#	at $ResourcesDir/scripts/pretar. These can have descriptive names. The selected file will be
	#	added in to the update content and renamed to simply pretar.sh.
	dialog --clear --title "$DialogTitleText" \
		--yesno "Will there be a pretar.sh file?" 10 60

	response=$?
	case $response in
		$DIALOG_OK) 
			PretarFiles=()
			while IFS= read -r -d $'\0' file; do
			    PretarFiles+=("$file" "")
			done < <(find $ResourcesDir/scripts/pretar -type f -name "*.sh" -print0)

			if [ ${#PretarFiles[@]} -eq 0 ]; then
				ExitWithErrorDialog "No .sh pretar files found in $ResourcesDir/scripts/pretar."
			else
			    file=$(dialog --stdout --title "Select a file to be pretar.sh" --menu "Choose a file:" 0 0 0 "${PretarFiles[@]}")
				VerifySelectedFileExists "$file" "Expected a valid pretar file selection."
				# if we are here, then a pretar file has been selected, move it into place
				cp $file $UpdateContentSourcePath/pretar.sh
			fi    
		;;
	esac

	# now ask whether there will be a posttar.sh file. It is expected to be in the specific folder
	#	at $ResourcesDir/scripts/posttar. 
	dialog --clear --title "$DialogTitleText" \
		--yesno "Will there be a posttar.sh file?" 10 60

	response=$?
	case $response in
		$DIALOG_OK) 
			PostarFiles=()
			while IFS= read -r -d $'\0' file; do
			    PostarFiles+=("$file" "")
			done < <(find $ResourcesDir/scripts/posttar -type f -name "*.sh" -print0)

			if [ ${#PostarFiles[@]} -eq 0 ]; then
				ExitWithErrorDialog "No .sh posttar files found in $ResourcesDir/scripts/posttar."
			else
			    file=$(dialog --stdout --title "Select a file to be posttar.sh" --menu "Choose a file:" 0 0 0 "${PostarFiles[@]}")
				VerifySelectedFileExists "$file" "Expected a valid posttar file selection."
				# if we are here, then a posttar file has been selected, move it into place
				echo "cp $file $UpdateContentSourcePath/posttar.sh"
				cp $file $UpdateContentSourcePath/posttar.sh
			fi    
		;;
	esac
}

# ---------------------------------------------------
# DeletePreviousUpdateContent()
# ---------------------------------------------------
DeletePreviousUpdateContent()
{
	BuildRootOutputEtcPath="${CurrentBuildRootPath}/output/target/etc"
	rm -fr $UpdateContentSourcePath
	rm -fr $BuildRootUpdateContentPath/updatecontent"
	rm -f $BuildRootUpdateContentPath/init.d/S99*"
}

# ---------------------------------------------------
# CreateInstallInfoForUpdateContent()
# ---------------------------------------------------
CreateInstallInfoForUpdateContent()
{
	pushd $UpdateContentSourcePath

	# start by creating the install.info file with the version number.
	echo "VERSION $ReleaseString" > install.info

	# calculate md5 sums of the files in the updatecontent folder and place them at the end of the created install.info file.
	md5sum * | awk '{print $2 " " $1}' >> install.info

	# remove the self-referential install.info md5sum line from the newly created install.info file.
	sed -i "/install.info/d" install.info

	popd
}

# ---------------------------------------------------
# CreateRestorePlusUpdateImage()
# ---------------------------------------------------
CreateRestorePlusUpdateImage()
{
	ScanProductUpdatersDirectories $UpdatersFolder
	VerifySelectedFileExists "$RootfsFilePath" "Requires $RootfsFilePath"

	ReleaseStringWithUnderscores=`echo $ReleaseString | tr . _`
	TargetZipFileFolderName="${UpdateRestoreFileName}${ReleaseStringWithUnderscores}"

	# start by deleting any previous updater content that might be cached
	#	in the build root system and its source, and then remaking a blank
	#	folder to receive the new update contents.
	DeletePreviousUpdateContent
	mkdir -p $UpdateContentSourcePath

	# set up temp creation folders and put the boot restore content in place.
	#	This will be used to add the factory update kernel and initramfs to the update content.
	rm -fr $TempCreationFolder
	mkdir -p $TempCreationFolder/$TargetZipFileFolderName
	rm -fr $TempUpdateRootfsFolder
	mkdir -p $TempUpdateRootfsFolder/boot

	# give the option for pre/post tar scripts to be included in the update
	SelectPrePostTarScripts

	cp $RestoreZipFile $TempCreationFolder/$TargetZipFileFolderName
	pushd $TempCreationFolder/$TargetZipFileFolderName
	unzip $RestoreZipFile &>> $LogFile
		# get rid of the extraneous zip file now that we've put its contents in place
	ZipFileToRemove=`basename $RestoreZipFile`
	rm -f $ZipFileToRemove &>> $LogFile
	popd

	# move the selected update version's rootfs into a temporary location and add the 
	#	factory scriptexecute and kernel files into the boot location.
	tar xzvf $RootfsFilePath -C $TempUpdateRootfsFolder &>> $LogFile
	cp $TempCreationFolder/$TargetZipFileFolderName/$TargetUpdaterKernelFileName $TempUpdateRootfsFolder/boot
	cp $TempCreationFolder/$TargetZipFileFolderName/$TargetUpdaterInitRamFSFileName $TempUpdateRootfsFolder/boot

	# retar the rootfs.tgz with the requisite /boot contents
	pushd $TempUpdateRootfsFolder
	rm -f rootfs.tgz &> /dev/null
	tar czvf rootfs.tgz . &>> $LogFile

	# the rootfs is ready - now copy it into the updatecontent location
	popd
	cp $TempUpdateRootfsFolder/rootfs.tgz $UpdateContentSourcePath

	# now create the install.info file for the updatecontent folder contents.
	CreateInstallInfoForUpdateContent

	# copy the correct script file into the source location and then run build root to
	#	build the updater kernel and its initramfs
	cp $S99UpdateScriptFile $EtcSourcePath/init.d/S99scriptexecute

	pushd ..
	sh build.sh

	# copy the generated kernel and its initramfs to the restore contents folder
	cp output/kernel.img $TempCreationFolder/$TargetZipFileFolderName/$TargetUpdaterKernelFileName
	cp output/scriptexecute.img $TempCreationFolder/$TargetZipFileFolderName/$TargetUpdaterInitRamFSFileName
	popd

	# generate the update/restore payload
	pushd $TempCreationFolder/$TargetZipFileFolderName
	zip -r bootRestore.zip .
	# clear out the rest of the contents for creating the final zip file.
	mv bootRestore.zip ..
	rm -fr *
	mv ../bootRestore.zip .

	# next to the bootRestore.zip file is also an image and the readme.txt file.
	cp $InstructionsImageFile ./InstructionsImage.png 
	cp $ReadMeFile ./readme.txt

	# now wrap the bootRestore.zip in a zip with an xml info file. An example of the xml contents is:
	#	<?xml version="1.0" encoding="UTF-8"?>
	#	
	#	<UsbBootVersionInfo
	#		product="wavestate (original)"
	#		incompatibleProducts="wavestate mkII, wavestate SE"
	#		version="2.1.3"
	#		architecture="cm3"
	#		checksum="6456b894bccc957081d5ee00a4419f58"
	#		buttonsToHoldAtStartup="PERFORMANCE MOD KNOBS, MASTER, NOTE ADVANCE"
	#	/>

	bootRestoreMD5=`md5sum bootRestore.zip | awk '{print $1}'`
	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > .versioninfo.xml
	echo -e "<UsbBootVersionInfo\n\tproduct=\"${XMLProductName}\"\n\tincompatibleProducts=\"${IncompatibleProducts}\"\n\tversion=\"${ReleaseString}\"\n\tarchitecture=\"${Architecture}\"\n\tchecksum=\"${bootRestoreMD5}\"\n\tbuttonsToHoldAtStartup=\"${ButtonsToHold}\"\n/>" >> .versioninfo.xml

	cd ..
	zip -r ${TargetZipFileFolderName}.zip $TargetZipFileFolderName
	popd

	# move the result into its final resting place
	mv $TempCreationFolder/${TargetZipFileFolderName}.zip output/
}

# ---------------------------------------------------
# CreateFactoryUpdaterKernelAndInitramfs()
# ---------------------------------------------------
CreateFactoryUpdaterKernelAndInitramfs()
{
	# start by deleting any previous updater content that might be cached
	#	in the build root system and its source:
	DeletePreviousUpdateContent

	# copy the correct script file into the source location and then run build root to
	#	build the factory update kernel and its initramfs
	cp $S99FactoryScriptFile $EtcSourcePath/init.d/S99scriptexecute

	TargetZip=$PWD/output/$FactoryUpdateBootFilesZipFile
	pushd ..
	sh build.sh
	mkdir -p $TempCreationFolder
	cp output/kernel.img $TempCreationFolder/$TargetUpdaterKernelFileName
	cp output/scriptexecute.img $TempCreationFolder/$TargetUpdaterInitRamFSFileName
	pushd $TempCreationFolder
	zip -r $TargetZip .
	popd
}

# ---------------------------------------------------
# CreateImage()
# ---------------------------------------------------
CreateImage()
{
	mkdir $PWD/output &> /dev/null

	imageType=`cat $ImageTypeSelectionFile`
	case $imageType in
		1)
			CreateRestorePlusUpdateImage
			;;
		2)
			CreateFactoryUpdaterKernelAndInitramfs
			;;
		*)
			exit -2
			;;
	esac
}

# ---------------------------------------------------
# Main script control
# ---------------------------------------------------
CleanUpTempFiles
CheckResources
SelectImageType
SelectProduct
CreateImage

PostCleanUpTempFiles

