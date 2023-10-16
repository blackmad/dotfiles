#!/bin/bash

git lfs install

# Makes Git use LFS for potentially huge python-related stuff
git lfs track \
  '*.pkl' \
  '*.npz'

# Same for binary image types
git lfs track \
  '*.png' \
  '*.jpeg' \
  '*.jpg' \
  '*.bmp' \
  '*.svg' \
  '*.sketch'

# And again for office-related binaries
git lfs track \
  '*.ppt' \
  '*.pptx' \
  '*.doc' \
  '*.docx' \
  '*.xls' \
  '*.xlsx' \
  '*.odt' \
  '*.odf' \
  '*.odp' \
  '*.docx' \
  '*.xls' \
  '*.xlsx'
