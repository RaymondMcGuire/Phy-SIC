#!/bin/bash
urle () { [[ "${1}" ]] || return 1; local LANG=C i x; for (( i = 0; i < ${#1}; i++ )); do x="${1:i:1}"; [[ "${x}" == [a-zA-Z0-9.~-] ]] && echo -n "${x}" || printf '%%%02X' "'${x}"; done; echo; }

echo -e "Please register at https://smpl.is.tue.mpg.de"
read -p "Username (SMPL account): " username
read -p "Password (SMPL account): " password
username=$(urle "${username}")
password=$(urle "${password}")

# SMPL Body model
mkdir -p data/body_models/smpl
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smpl&sfile=SMPL_python_v.1.1.0.zip' -O './data/body_models/smpl/SMPL_python_v.1.1.0.zip' --no-check-certificate --continue
unzip -o ./data/body_models/smpl/SMPL_python_v.1.1.0.zip -d ./data/body_models/smpl/
mv ./data/body_models/smpl/SMPL_python_v.1.1.0/smpl/models/* ./data/body_models/smpl/
rm -r ./data/body_models/smpl/SMPL_python_v.1.1.0 ./data/body_models/smpl/SMPL_python_v.1.1.0.zip
ln -sf basicmodel_neutral_lbs_10_207_0_v1.1.0.pkl ./data/body_models/smpl/SMPL_NEUTRAL.pkl
mkdir -p data/models/SMPL
ln -sf ../../body_models/smpl/SMPL_NEUTRAL.pkl ./data/models/SMPL/SMPL_NEUTRAL.pkl

echo -e "Please register at https://smpl-x.is.tue.mpg.de"
read -p "Username (SMPL-X account): " username
read -p "Password (SMPL-X account): " password
username=$(urle "${username}")
password=$(urle "${password}")

# SMPL-X Body model, part segmentation
mkdir -p data/body_models/smplx
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=models_smplx_v1_1.zip' -O './data/body_models/smplx/models_smplx_v1_1.zip' --no-check-certificate --continue
unzip -o ./data/body_models/smplx/models_smplx_v1_1.zip -d ./data/body_models/smplx/
mv ./data/body_models/smplx/models/smplx/* ./data/body_models/smplx/
rm -r ./data/body_models/smplx/models ./data/body_models/smplx/models_smplx_v1_1.zip
mkdir -p data/models/SMPLX
ln -sf ../../body_models/smplx/SMPLX_NEUTRAL.npz ./data/models/SMPLX/SMPLX_NEUTRAL.npz

# SMPLFitter SMPL <-> SMPL-X transfer files
if [[ ! -f ./data/body_models/smpl2smplx_deftrafo_setup.pkl || ! -f ./data/body_models/smplx2smpl_deftrafo_setup.pkl ]]; then
    wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=smplx&sfile=model_transfer.zip' -O './data/body_models/model_transfer.zip' --no-check-certificate --continue
    rm -rf ./data/body_models/model_transfer_tmp
    mkdir -p ./data/body_models/model_transfer_tmp
    unzip -o ./data/body_models/model_transfer.zip -d ./data/body_models/model_transfer_tmp/
    find ./data/body_models/model_transfer_tmp -name '*deftrafo_setup.pkl' -exec cp {} ./data/body_models/ \;
    test -f ./data/body_models/smpl2smplx_deftrafo_setup.pkl
    test -f ./data/body_models/smplx2smpl_deftrafo_setup.pkl
    rm -r ./data/body_models/model_transfer_tmp ./data/body_models/model_transfer.zip
fi

echo -e "Please register at https://agora.is.tue.mpg.de"
read -p "Username (CameraHMR account): " username
read -p "Password (CameraHMR account): " password
username=$(urle "${username}")
password=$(urle "${password}")

# Kid templates, required by SMPLFitter
wget --post-data "username=$username&password=$password" "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smpl_kid_template.npy" -O "./data/body_models/smpl/kid_template.npy" --no-check-certificate --continue
wget --post-data "username=$username&password=$password" "https://download.is.tue.mpg.de/download.php?domain=agora&resume=1&sfile=smplx_kid_template.npy" -O "./data/body_models/smplx/kid_template.npy" --no-check-certificate --continue

echo -e "Please register at https://camerahmr.is.tue.mpg.de"
read -p "Username (CameraHMR account): " username
read -p "Password (CameraHMR account): " password
username=$(urle "${username}")
password=$(urle "${password}")

# CameraHMR checkpoints
mkdir -p data/pretrained-models
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=cam_model_cleaned.ckpt' -O './data/pretrained-models/cam_model_cleaned.ckpt' --no-check-certificate --continue
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=camerahmr_checkpoint_cleaned.ckpt' -O './data/pretrained-models/camerahmr_checkpoint_cleaned.ckpt' --no-check-certificate --continue
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=model_final_f05665.pkl' -O './data/pretrained-models/model_final_f05665.pkl' --no-check-certificate --continue
wget --post-data "username=$username&password=$password" 'https://download.is.tue.mpg.de/download.php?domain=camerahmr&sfile=smpl_mean_params.npz' -O './data/smpl_mean_params.npz' --no-check-certificate --continue

# MMPose RTMPose whole-body and Depth Pro
mkdir -p data/mmpose/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody
mkdir -p data/mmpose/configs/_base_
wget https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody/rtmpose-l_8xb64-270e_coco-wholebody-256x192.py -O data/mmpose/configs/wholebody_2d_keypoint/rtmpose/coco-wholebody/rtmpose-l_8xb64-270e_coco-wholebody-256x192.py
wget https://raw.githubusercontent.com/open-mmlab/mmpose/v1.3.2/configs/_base_/default_runtime.py -O data/mmpose/configs/_base_/default_runtime.py
wget https://download.openmmlab.com/mmpose/v1/projects/rtmposev1/rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth -O data/mmpose/rtmpose-l_simcc-coco-wholebody_pt-aic-coco_270e-256x192-6f206314_20230124.pth
wget https://ml-site.cdn-apple.com/models/depth-pro/depth_pro.pt -P data/

# Torch hub runtime checkpoints
mkdir -p data/torch/hub/checkpoints
wget https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_large.pt -O data/torch/hub/checkpoints/sam2.1_hiera_large.pt

# Deco checkpoints and data
mkdir -p data/deco
wget https://keeper.mpdl.mpg.de/f/6f2e2258558f46ceb269/?dl=1 --max-redirect=2 --trust-server-names -O data/deco/Release_Checkpoint.tar.gz && tar -xvf data/deco/Release_Checkpoint.tar.gz --directory data/deco && rm -r data/deco/Release_Checkpoint.tar.gz
mv data/deco/Release_Checkpoint/* data/deco/
rmdir data/deco/Release_Checkpoint
wget https://keeper.mpdl.mpg.de/f/50cf65320b824391854b/?dl=1 --max-redirect=2 --trust-server-names -O data/deco/data.tar.gz && tar -xvf data/deco/data.tar.gz --directory data/deco && rm -r data/deco/data.tar.gz
mv data/deco/data/conversions data/
mv data/deco/data/smplx_vert_segmentation.json data/body_models/smplx/
mv data/deco/data/weights/pose_hrnet_w32_256x192.pth data/deco/
mv data/deco/data/smplx/smplx_neutral_tpose.ply data/body_models/smplx/
mv data/deco/data/smpl/smpl_neutral_tpose.ply data/body_models/smpl/
rm -r data/deco/data

