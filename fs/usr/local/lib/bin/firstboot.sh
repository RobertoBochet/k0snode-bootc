#!/usr/bin/env sh

echo "Starting firstboot scripts"

scripts_folder="/etc/firstboot.d"

scripts=$( find "$scripts_folder" -type f -executable | sort )

for script in $scripts; do
  echo "#Running $script"
  $script
done

echo "Finished firstboot scripts"
