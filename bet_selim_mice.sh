#!/bin/bash
start=`date +%s`
#cpu_s= `echo (grep -c processor /proc/cpuinfo)`

for img in *.nii*; do
img_no_ext=`remove_ext $img`
#name=${img_no_ext:end:11}
fslroi $img $img_no_ext'_b0' 0 1
ResampleImage 3 $img_no_ext'_b0.nii.gz' $img_no_ext'_b0.nii.gz' 108x90x64 1 1 6
done
mkdir Template 
immv *b0* ./Template 
cd ./Template 
buildtemplateparallel.sh -d 3 -m 30x50x20 -t GR -s CC -c 2 -n 1 -i 4 -j $(getconf _NPROCESSORS_ONLN) -o My_ *b0.nii.gz
wait
bet My_template.nii.gz 'My_template_bet' -m -R -r 40 -c 55 42 7 -f 0.44 -g -0.027
wait
fsleyes My_template.nii.gz My_template_bet_mask.nii.gz
#fslmaths My_template_bet_mask.nii.gz -ero My_template_bet_mask.nii.gz

for img in My*b0.nii.gz;do
img_no_ext=`remove_ext $img`
name_=`echo ${img_no_ext:end-2}`
antsApplyTransforms -d 3 -i My_template_bet_mask.nii.gz -r $img -o $img_no_ext'_mask.nii.gz' -t [$img_no_ext"Affine.txt" , 1] -t $img_no_ext'InverseWarp.nii.gz' 
fslmaths $img_no_ext'_mask.nii.gz' -thr 0.85 -bin $img_no_ext'_mask.nii.gz'
ResampleImage 3 $img_no_ext'_mask.nii.gz' $img_no_ext'_mask.nii.gz' 108x90x16 1 1 6

done
mkdir ../masks
immv *b0_mask* ../masks

end=`date +%s`
runtime=$((end-start))
echo 'Check your Masks! Selim :)'
echo "total excution time in seconds:"$runtime