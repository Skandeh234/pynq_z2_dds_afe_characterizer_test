#!/usr/bin/bash

#if [[ $# -ne 2 ]] || [[ ! -d $1 ]] || [[ ! -f $2 ]]; then
#  echo "invalid argument(s); please supply the path to the project directory and the name of the bd tcl file"
#  echo "scp_hardware.sh /path/to/project /path/to/bd_tcl"
if [[ $# -ne 1 ]] || [[ ! -d $1 ]]; then
  echo "invalid argument(s); please supply the path to the project directory"
  echo "scp_hardware.sh /path/to/project"
  exit
fi

if [[ ! -d scp_payload ]]; then
  mkdir scp_payload
fi

echo "looking for .hwh and .bit files in $1"
if [[ $(find $1 -name *.hwh | wc -l) -ne 1 ]] || [[ $(find $1 -name *.bit | wc -l) -ne 1 ]]; then
  echo "couldn't find a unique .bit and/or .hwh file"
  echo $(find $1 -name *.hwh)
  echo $(find $1 -name *.bit)
  exit
fi
echo "found necessary files for overlay creation"

if [[ ! -z $(ls -A scp_payload/) ]]; then
  echo "scp_payload/ contains files, OK to delete? (Y/N): "
  select yn in "Yes" "No"; do
    case $yn in
      Yes ) rm scp_payload/*; break;;
      No ) exit;;
    esac
  done
fi

cp $(find $1 -name *.hwh) scp_payload/top.hwh
#cp $2 scp_payload/top.tcl
cp $(find $1 -name *.bit) scp_payload/top.bit

echo "using scp to copy files to the pynq board"
scp -r scp_payload xilinx@192.168.2.99:jupyter_notebooks


