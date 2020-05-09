#!/bin/bash
# Copyright (C) 2019 František Kysela <bythedroid@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

check_connectivity() {
    local test_ip
    local test_count

    test_ip="8.8.8.8"
    test_count=1

    if ping -c ${test_count} ${test_ip} > /dev/null; then
       return 0;
    else
       return 1;
    fi
 }
 
if ! check_connectivity; then
exit 1;
fi

GITHUB_TABLE=(
"penglezos" "android_kernel_xiaomi_msm8953" "@rn4downloads" "#kernel #Englezos #Kernels"
"topjohnwu" "MagiskManager" "@MagiskReleases" "@MagiskReleases"
"topjohnwu" "Magisk" "@MagiskReleases" "@MagiskReleases"
"topjohnwu" "MagiskManager" "@rn4downloads" "#magiskmanager #root #app"
"topjohnwu" "MagiskManager" "@whyreddownloads" "#magiskmanager #root #app"
"topjohnwu" "MagiskManager" "@laurelofficial" "#magiskmanager #root #app"
"topjohnwu" "Magisk" "@laurelofficial" "#magisk #root"
"topjohnwu" "Magisk" "@rn4downloads" "#magisk #root"
"topjohnwu" "Magisk" "@whyreddownloads" "#magisk #root"
"dracarys18" "NotKernel" "@rn4downloads" "#notkernel #kernel #kernels"
"davidtrpcevski" "Advanced-LineageOS-Releases" "@rn4downloads" "#LineageOS #AdvancedLOS #rom #customrom"
"akhilnarang" "whyred" "@whyreddownloads" "#derpkernel #kernel #kernels"
"msfjarvis" "whyred" "@whyreddownloads" "#caesium #kernel #kernels"
"Pzqqt" "android_kernel_xiaomi_whyred" "@whyreddownloads" "#panda #kernel #kernels"
)

SOURCEFORGE_TABLE=(
"candyroms" "Candy ROM" "Candy" "@candyrom"
"illusionproject" "AOSIP" "AOSIP" "@aosiprom"
"xiaomi-eu-multilang-miui-roms" "MIUI EU ROM" "miui.eu" "@MIUI_EU"
"superioros" "SuperiorOS" "SuperiorOS" "@SuperiorDL"
"nitrogen-project" "NitrogenOS" "Nitrogen-OS" "@NitrogenDL"
"aospextended-rom" "AospExtended ROM" "AospExtended" "@aexrom"
"posp" "POSP" "potato" "@posprom"
"havoc-os" "HavocOS" "Havoc-OS" "@havocrom"
"stag-os" "StagOS ROM" "StagOS" "@StagOS"
"arrow-os" "ArrowOS ROM" "Arrow" "@ArrowOS_DL"
"evolution-x" "EvolutionX" "EvolutionX" "@evolutionx_dl"
"viper-project" "ViperOS ROM" "Viper" "@ViperOS_dl"
"bootleggersrom" "Bootleggers ROM" "BootleggersROM" "@bootleggers_dl"
"miroom" "Mi ROOM" "MiRoom" "@miroom_dl"
"revolutionos-miui" "Revolution OS" "ROS-MIUI" "@Revolution_dl"
"miui-ita" "MIUI Italia ROM" "miui.it" "@MIUIItalia"
"syberiaos" "SyberiaOS" "syberia" "@SyberiaOS"
"aosmp" "AOSMP ROM" "AOSmP" "@AOSMP_dl"
"xtended" "MSM Xtended ROM" "Xtended" "@MSMXtended"
"coltos" "ColtOS ROM" "ColtOS" "@ColtOS"
)

SOURCEFORGE_DEVICE_TABLE=(
"dirtyunicorns" "DU by @dracarys_18" "mido" "@rn4downloads" "#DU #rom #customrom"
"candyroms" "Candy for mido" "mido" "@rn4downloads" "#candy #rom #customrom"
"candyroms" "Candy for whyred" "whyred" "@whyreddownloads" "#candy #rom #customrom"
"havoc-os" "HavocOS for whyred" "whyred" "@whyreddownloads" "#havoc #rom #customrom"
"havoc-os" "HavocOS for mido" "mido" "@rn4downloads" "#havoc #rom #customrom"
"superioros" "SuperiorOS for whyred" "whyred" "@whyreddownloads" "#superioros #rom #customrom"
"superioros" "SuperiorOS for mido" "mido" "@rn4downloads" "#superioros #rom #customrom"
"illusionproject" "AOSIP for whyred" "whyred" "@whyreddownloads" "#aosip #rom #customrom"
"illusionproject" "AOSIP for mido" "mido" "@rn4downloads" "#aosip #rom #customrom"
"rfdforce" "@rev31one for mido" "mido" "$MY_ID" "#rev31one"
"syberiaos" "SyberiaOS for mido" "mido" "@rn4downloads" "#syberiaos #rom #customrom"
"syberiaos" "SyberiaOS for whyred" "whyred" "@whyreddownloads" "#syberiaos #rom #customrom"
"nitrogen-project" "NitrogenOS for mido" "mido" "@rn4downloads" "#nitrogenos #rom #customrom"
"nitrogen-project" "NitrogenOS for whyred" "whyred" "@whyreddownloads" "#nitrogenos #rom #customrom"
"posp" "POSP (Potato Open Sauce Project) for mido" "mido" "@rn4downloads" "#posp #rom #customrom"
"posp" "POSP (Potato Open Sauce Project) for whyred" "whyred" "@whyreddownloads" "#posp #rom #customrom"
"viper-project" "ViperOS for mido" "mido" "@rn4downloads" "#viperos #rom #customrom"
"viper-project" "ViperOS for whyred" "whyred" "@whyreddownloads" "#viperos #rom #customrom"
"bootleggersrom" "Bootleggers for mido" "mido" "@rn4downloads" "#bootleggers #rom #customrom"
"bootleggersrom" "Bootleggers for whyred" "whyred" "@whyreddownloads" "#bootleggers #rom #customrom"
"arrow-os" "ArrowOS for mido" "mido" "@rn4downloads" "#arrowos #rom #customrom"
"arrow-os" "ArrowOS for whyred" "whyred" "@whyreddownloads" "#arrowos #rom #customrom"
"pixys-os" "PixysOS for mido" "mido" "@rn4downloads" "#pixysos #rom #customrom"
"pixys-os" "PixysOS for whyred" "whyred" "@whyreddownloads" "#pixysos #rom #customrom"
"evolution-x" "EvolutionX for mido" "mido" "@rn4downloads" "#evolutionx #rom #customrom"
"evolution-x" "EvolutionX for whyred" "whyred" "@whyreddownloads" "#evolutionx #rom #customrom"
"rebellionos" "RebellionOS for mido" "mido" "@rn4downloads" "#rebellionos #rom #customrom"
"rebellionos" "RebellionOS for whyred" "whyred" "@whyreddownloads" "#rebellionos #rom #customrom"
"lotus-os" "LotusOS for mido" "mido" "@rn4downloads" "#lotusos #rom #customrom"
"lotus-os" "LotusOS for whyred" "whyred" "@whyreddownloads" "#lotusos #rom #customrom"
"dotos-downloads" "DotOS for mido" "mido" "@rn4downloads" "#dotos #rom #customrom"
"dotos-downloads" "DotOS for whyred" "whyred" "@whyreddownloads" "#dotos #rom #customrom"
"crdroid" "crDroid for mido" "mido" "@rn4downloads" "#crdroid #rom #customrom"
"crdroid" "crDroid for whyred" "whyred" "@whyreddownloads" "#crdroid #rom #customrom"
"krakenproject" "Kraken (Kraken Open Tentacles Project) for whyred" "whyred" "@whyreddownloads" "#krakenrom #rom #customrom"
"ancientrom" "ANCIENT ROM for whyred" "whyred" "@whyreddownloads" "#ancientrom #rom #customrom"
"crdroidpie" "crDroid for whyred" "whyred" "@whyreddownloads" "#crdroid #rom #customrom"
"zirconiumaosp" "Zirconium AOSP for whyred" "whyred" "@whyreddownloads" "#zirconiumaosp #rom #customrom"
"xiaomi-eu-multilang-miui-roms" "MIUI EU for whyred" "HMNote5Pro" "@whyreddownloads" "#miui #miuieu #rom #customrom"
"aosipderp-fest4whyred" "AOSIP Derpfest for whyred" "whyred" "@whyreddownloads" "#aosipderpfest #aosip #rom #customrom"
"coltmod4whyred" "ColtOS MOD for whyred" "whyred" "@whyreddownloads" "#coltosmod #rom #customrom"
"xtended" "MSM-Xtended for mido" "mido" "@rn4downloads" "#msmextended #rom #customrom"
"xtended" "MSM-Xtended for whyred" "whyred" "@whyreddownloads" "#msmextended #rom #customrom"
"aospextended-rom" "AospExtended ROM for mido" "mido" "@rn4downloads" "#aospextended #rom #customrom"
"aospextended-rom" "AospExtended ROM for whyred" "whyred" "@whyreddownloads" "#aospextended #rom #customrom"
"coltos" "ColtOS ROM for mido" "mido" "@rn4downloads" "#coltos #official #rom #customrom"
"coltos" "ColtOS ROM for whyred" "whyred" "@whyreddownloads" "#coltos #official #rom #customrom"
"stag-os" "StagOS ROM for whyred" "whyred" "@whyreddownloads" "#stagos #official #rom #customrom"
"stag-os" "StagOS ROM for mido" "mido" "@rn4downloads" "#stagos #official #rom #customrom"
"du-whyred" "DU ROM (UNOFFICIAL) for whyred" "whyred" "@whyreddownloads" "#du #unofficial #rom #customrom"
"aosmp" "AOSMP ROM for whyred" "whyred" "@whyreddownloads" "#aosmp #rom #customrom"
"aosmp" "AOSMP ROM for mido" "mido" "@rn4downloads" "#aosmp #rom #customrom"
"cerberusos" "CerberusOS for whyred" "whyred" "@whyreddownloads" "#cerberusos #official #rom #customrom"
"cerberusos" "CerberusOS for mido" "mido" "@rn4downloads" "#cerberusos #official #rom #customrom"
"revos-aosp" "RevOS for whyred" "whyred" "@whyreddownloads" "#revos #official #rom #customrom"
"aosip-fanedition" "AOSIP DerpFest (Fan edition) by @NBD_ERICK for mido" "mido" "@rn4downloads" "#aosipderpfest #aosip #rom #customrom"
"escobar1945" "Xiaomi EU Port by @Escobar1945 for mido" "mido" "@rn4downloads" "#miuieu #miui #rom #customrom"
"cosmic-os" "CosmicOS ROM for mido" "mido" "@rn4downloads" "#cosmicos #rom #customrom"
"cosmic-os" "CosmicOS ROM for whyred" "whyred" "@whyreddownloads" "#cosmicos #rom #customrom"
"aicp-mido" "AICP ROM by @NBD_ERICK for mido" "mido" "@rn4downloads" "#aicp #rom #customrom"
"miui-ports.whats-new.p" "MIUI port by @officialwhatsnew for mido" "mido" "@rn4downloads" "#miui #miuiport #portrom #rom #customrom"
"devilsfork" "@aryankedare for mido" "mido" "@rn4downloads" "#aryankadere"
"havoc-autumn" "HavocOS by hungphan2001 for mido" "mido" "@rn4downloads" "#havoc #rom #customrom"
"havoc-autumn" "HavocOS by hungphan2001 for whyred" "whyred" "@whyreddownloads" "#havoc #rom #customrom"
"thht-misc" "build of @sayan7848 for mido" "mido" "@rn4downloads" "#sayan7848"
"havoc-mido" "HavocOS by @NBD_ERICK for mido" "mido" "@rn4downloads" "#havoc #rom #customrom"
)

CHANNEL_TABLE=(
"@laurelofficial" "@laurelofficial"
"@rn4downloads" "@rn4downloads | @rn4official | @xiaomiot | @customization | @rn4photography"
"@whyreddownloads" "@whyredofficial | @whyredphotos | @xiaomiot | @customization"
)

get_channel_tags() {
local key="";
local value="";
local position=false;
for i in "${CHANNEL_TABLE[@]}" ; do
  if ! $position; then
  key=$i;
  position=true;
  continue;
  else
  value=$i
  position=false;
  fi
  if [ "$key" = "$1" ]; then 
  echo $value;
  return 0;
  fi
done
return 1;
}

MY_ID="TELEGRAM_USER_ID";
TOKEN="TELEGRAM_API_TOKEN";

chmod +x ./database
chmod +x ./human_size
chmod +x ./get_latest_github_releases.sh
chmod +x ./get_latest_sourceforge_releases.sh

current_array=()
position=0;
for i in "${GITHUB_TABLE[@]}"; do
if (( position == 3 )); then
current_array+=("$i")
position=0;
append="${current_array[3]}

`get_channel_tags ${current_array[2]}`";
./get_latest_github_releases.sh -i "${current_array[2]}" -t "${TOKEN}" -r "${current_array[1]}" -u "${current_array[0]}" -a "$append";
current_array=()
else
(( position++ ))
current_array+=("$i")
fi
done

current_array=()
position=0;
for i in "${SOURCEFORGE_TABLE[@]}"; do
if (( position == 3 )); then
current_array+=("$i")
position=0;
./get_latest_sourceforge_releases.sh -i "${current_array[3]}" -t "${TOKEN}" -d "${current_array[2]}" -n "${current_array[1]}" -a "${current_array[3]}" -p "${current_array[0]}";
current_array=()
else
(( position++ ))
current_array+=("$i")
fi
done

current_array=()
position=0;
for i in "${SOURCEFORGE_DEVICE_TABLE[@]}"; do
if (( position == 4 )); then
current_array+=("$i")
position=0;
append="${current_array[4]}

`get_channel_tags ${current_array[3]}`";
./get_latest_sourceforge_releases.sh -i "${current_array[3]}" -t "${TOKEN}" -p "${current_array[0]}" -d "${current_array[2]}" -n "${current_array[1]}" -a "$append";
current_array=()
else
(( position++ ))
current_array+=("$i")
fi
done

echo "Done.";
exit 0;

