#!python

#
# The idea with this script is to automate the process of updating the
# reference to the Tutorial version inside the scenario.
#
# Before running this script the version number should be updated to the
# version of the release to be made.
# 
# How it works:
# 1. Change version_upgrade.nut so that the Tutorial GameScript will accept loading savegames/scenarios with older versions of itself
# 2. Load the scenario in OpenTTD
# 3. Save scenario in OpenTTD 
# 4. Exit OpenTTD
# 5. Change version_upgrade.nut back so that the shipped Tutorial GS will not allow loading older versions.
#

import os

def WriteVersionUpgradeNut(allowUpgrade):
	f = open("version_upgrade.nut", "w")
	if allowUpgrade:
		value = "true"
	else:
		value = "false"
	f.write("ALLOW_UPGRADE <- " + value + ";\n")
	f.close

def OpenTTD(params):
	openttd_exec_dir = "C:\Users\Leif\Documents\OpenTTD\Installations\TutorialPrepare"
	old_working_dir = os.getcwd()
	os.chdir(openttd_exec_dir) # change working dir to where OpenTTD is
	os.system("openttd.exe " + params)
	os.chdir(old_working_dir) # restore working dir



# -- Main -------------------

WriteVersionUpgradeNut(True)
scn = os.getcwd() + "\\Beginner Tutorial.scn"
OpenTTD("-e -g \"" + scn + "\"")
WriteVersionUpgradeNut(False)

