#!/bin/bash
#
# Shortcut script to update the archivebox with a new URL
#
# Create issues with what you want to save or PR into data/links-to-preserve.txt
#
# Image: docker pull nikisweeting/archivebox
#

cat data/links-to-preserve.txt | docker run -i -v -v $(pwd)/archivebox:/data nikisweeting/archivebox
