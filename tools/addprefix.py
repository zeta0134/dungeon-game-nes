#!/usr/bin/env python3
import os, sys
import pathlib
from pathlib import Path

if len(sys.argv) != 2:
  print("Usage: addprefix.py folderpath")
  sys.exit(-1)
folderpath = sys.argv[1]

filenames = sorted(os.listdir(folderpath))
count = 0
for old_filename in filenames:
  countstring = f"{count:03}"
  count += 1
  new_filename = countstring + "_" + old_filename
  oldpath = (Path(folderpath) / old_filename).resolve() 
  newpath = (Path(folderpath) / new_filename).resolve() 
  os.rename(oldpath, newpath)

