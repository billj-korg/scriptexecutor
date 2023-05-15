# Script executor

Lightweight operating system image that downloads an arbritary shell script from a HTTP or NFS server, and executes it.

## Quick start (if using a binary build)

To tell the image to download the script from the HTTP server with IP-address 1.2.3.4 put in `cmdline.txt`:

`script=http://1.2.3.4/name-of-script.sh`

To tell the image to download the script from the NFS server with IP-addresses 1.2.3.4 use:

`script=1.2.3.4:/name-of-nfs-share/name-of-script.sh`

If using NFS the script has access to other files inside the same NFS share as well.
The current working directory is set to where the share is mounted before the script is executed.

## Documentation

[Building and customizing scriptexecutor](https://github.com/raspberrypi/scriptexecutor/wiki/Building-and-customizing)

########################
## Korg Notes ##########
########################

Within buildroot, run make busybox-menuconfig and enable gzip support for tar under the Archival
Utilities menu.

There are two types of images for the Korg SparkPi line of products, a normal update image and an
"update from USB Boot mode" image. 

In both updater modes, the update process occurs by rewriting the /boot/config.txt file to reference
an updater kernel and associated scriptexecute.img file, which contains the rootfs for the updater
kernel to use during the update. When the system reboots into the updater kerner, the first thing the
S99 updater will do is to rewrite the /boot/config.txt file so that the system reboots normally into
the regular kernel and rootfs of the target system. It will then proceed to run any pre/post tar scripts
and untar the update content to the target based on the location specified (which will vary depending
on whether it is a normal update or USB boot mode update).

IMPORTANT NOTES ABOUT THE NORMAL MODE VS. USB BOOT MODE
-------------------------------------------------------
Each mode for a release will be located within its own branch in the repo.

Take care to that when switching between building each of the two types of images that
the cached files under the output folder of the buildroot build are removed, if necessary.
It is important to check the contents of the generated rootfs to make sure that no cached
files from a previous type of build have been inadvertently leftover. In order to read
the contents of scriptexecute.img, you can do the following:

	1. Start in a folder containing a copy of scriptexecute.img file.
	2. rename scriptexecute.img to scriptexecute.img.gz
	3. gunzip scriptexecute.img.gz
	4. Create a folder to receive the contents of the rootfs image - e.g. mkdir ./rootfs
	5. Change to that folder (cd ./rootfs)
	6. execute the following command:
		cpio -idv < ../scriptexecute.img

Normal Mode Update Image
------------------------
In this case, the S99 script under scriptexecute/board/overlay/etc/init.d will point to an update
tarball that will have been downloaded to the target system under /Korg/Updater and the path to the
update will be contained in a file located at /Updater/CurrentInstallSourcePath on the target system.

USB Boot Mode Image
-------------------
In this special case, the same update content that would normally be in the location specified by
/Updater/CurrentInstallSourcePath on the target system is instead located in the scriptexecute.img 
rootfs itself under the /etc/updatecontent folder. The S99 /etc/init.d script for the updater kernel's
rootfs is modified to use this hardcoded location and the update proceeds as it would in the normal case.

An important note here is that the USB Boot Mode update's content MUST also contain the normal mode
update kernel and image that resides under /boot so that the updater kernel and scriptexecute.img that
was installed specifically for the USB Boot mode update will get replaced back to the normal ones so that
any subsequent normal mode update will continue to work.

