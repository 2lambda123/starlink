#! /bin/csh -f
#+
# deletecombinefiles.csh
#
# Script to remove the files generated by the recipe `Combining Target
# Images' in SC/5.
#
# Note that the final combined image, mosaic.sdf, is not deleted.
#
# Author:
#  ACD: A C Davenhall (Edinburgh)
#
# History:
#  15/4/99 (ACD): First stable version.
#-
#
# Targets.

rm targets/ngc2336_r_1_deb_flt.find
rm targets/ngc2336_r_2_deb_flt.find

rm targets/ngc2336_r_1_deb_flt.off
rm targets/ngc2336_r_2_deb_flt.off

rm targets/ngc2336_r_1_deb_flt.sdf
rm targets/ngc2336_r_2_deb_flt.sdf

rm targets/ngc2336_r_1_deb_flt_reg.sdf
rm targets/ngc2336_r_2_deb_flt_reg.sdf

#
# Print message.

echo "Intermediate data files deleted."
