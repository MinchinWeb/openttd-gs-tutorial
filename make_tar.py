#!python

import os
import re

version = -1
for line in open("info.nut"):

	r = re.search('SELF_VERSION\s+<-\s+([0-9]+)', line)
	if(r != None):
		version = r.group(1)

if(version == -1):
	print("Couldn't find Tutorial version in info.nut!")
	exit(-1)

dir_name = "Tutorial-v" + version
tar_name = dir_name + ".tar"
os.system("mkdir " + dir_name);
os.system("cp -Ra *.nut lang " + dir_name);
os.system("tar -cf " + tar_name + " " + dir_name);
os.system("rm -r " + dir_name);
