#!/bin/bash
BUILD_TYPE=$1
rm -rf out/

# Clone latest topaz_manifest
echo "Cloning latest topaz_manifest"
rm -rf .repo/local_manifests/
git clone https://github.com/Rexons-AOSP-Projects/topaz_manifest -b main .repo/local_manifests

echo "Running repo sync"
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)

echo "Hardware Cleanup"
    if [ -d "hardware/qcom-caf" ]; then
        echo "Cleaning up hardware/qcom-caf..."
        cd hardware/qcom-caf
        rm -rf msm8953 msm8996 msm8998 sdm660 sdm845 sm8150 sm8250 sm8350 sm8450 sm8450-6.6 sm8550 sm8650 sm8750 sm8850
        cd - > /dev/null
        echo "Cleanup complete."
    else
        echo "hardware/qcom-caf directory not found, skipping cleanup."
    fi

    echo "Cleaning up XML snippets"
    SNIPPET_DIR=$(ls -d .repo/manifests/snippets 2>/dev/null || ls -d .repo/mani*/sni* 2>/dev/null)
    
    if [ -n "$SNIPPET_DIR" ] && [ -d "$SNIPPET_DIR" ]; then
        cd "$SNIPPET_DIR" || exit
        
        BOARDS="msm8953 msm8996 msm8998 sdm660 sdm845 sm8150 sm8250 sm8350 sm8450 sm8450-6.6 sm8550 sm8650 sm8750 sm8850"
        for BOARD in $BOARDS; do
            sed -i "/path=\"hardware\/qcom-caf\/$BOARD/d" *.xml 2>/dev/null || true
        done
        
        cd - > /dev/null
        echo "XML snippets updated."
    else
        echo "Snippet directory not found, skipping XML edits."
    fi
    if [ -d "hardware/dolby"]; then
        echo "Replacing LunarisDolby with KoharuDolby" 
        cd hardware/dolby
        rm -rf LunarisDolby
        git clone https://github.com/Sissiogamer1/android_packages_apps_Dolby -b main LunarisDolby
        cd - > /dev/null
        echo "KoharuDolby cloned" 
    else
        echo "hardware/dolby not found, skipping KoharuDolby cloning" 
    fi
    
echo "Starting build"
source build/env*
breakfast tapas $BUILD_TYPE
mka shinkai -j$(nproc --all)
