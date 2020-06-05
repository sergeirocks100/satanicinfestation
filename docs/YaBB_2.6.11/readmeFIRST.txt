Setup.pl requires more than 60Mb of memory to function correctly. If your hosting service is offering less than 128Mb of memory, YaBB may not function well.

If you're testing or upgrading by overwriting the files in Admin, Sources, Languages, etc. be sure to also replace YaBB.pl and AdminIndex.pl. And, most importantly, rename your Settings.pl to Settings.pm and Paths.pl to Paths.pm. 
We are now at the point where ONLY executable files have the .pl extension.

Messages/movedthreads.cgi has been renamed and moved to Variables/Movedthreads.pm (Note the capitalization and different folder.)

*NEW instructions for upgrading.* We are now using the Convert folders for *all* upgrades - even from 2.5.2. Copy your old Variables, Members, Messages and Boards folder contents into their appropriate Convert folders in 2.6.0. Convert.pl (for 1x versions of YaBB) or Convert2x.pl (for 2x versions of YaBB) will double check the folder permissions and copy the files over for you - this removes some confusion as to exactly which old files need to be copied into Variables and also allows for the old settings in Settings.pl to be imported into the new Settings.pm. This is *also* in preparation for future changes in data formatting *and* as a check on YaBB's read/write permissions on the server.

NOTE: Old templates will not have all the necessary function calls and variables needed for the new functions - use the new templates and modify them.
NOTE: The graphics have been redone and many renamed. Among those graphics that have been renamed are the Group Membership stars. The new default Group Membership stars are .png files. If you are importing settings from an earlier version of YaBB you will need to either import your old stars OR assign the new Group Membership stars to your Member Groups in the Group Membership section of the Admin Center.