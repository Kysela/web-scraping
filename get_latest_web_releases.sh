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

usage() {
	echo -e "\nThis script can be used to get latest releases" 
	echo -e "\from specified website and send them formatted" 
	echo -e "\to Telegram channels or groups" 
	echo -e "\nSource: (https://github.com/Kysela/web-scraping)" 
	echo -e "\by @ATGDroid" 
	echo -e "\nUsage:\n $0 [options..]\n"
	echo -e "Options:\n"
	echo -e "-a | --append <message> - message to append to a post"
	echo -e "-c | --config <config file> - Custom path for script configuration file"
	echo -e "-d | --device <device codename> - device codename to search for"
	echo -e "-i | --id <chat id> - id of the chat to send message to"
	echo -e "-n | --name <formatted name> - Formatted name for telegram posts"
	echo -e "-w | --website <website link> - link to website with download links"
	echo -e "-t | --token <api token> - Telegram bot api token\n"
	echo -e "-h | --help - Display usage instructions.\n" 
	exit 0;
}

parse_args() {
parse_args_get_complete_counter() {
if [ "$parse_args_long_arguments" ] && [ "$parse_args_argument_position" ]; then
return $((parse_args_argument_position - parse_args_long_arguments))
elif [ "$parse_args_argument_position" ]; then
return $parse_args_argument_position;
else
return 0;
fi
}
if [ -z "$1" ]; then
parse_args_argument_position=0;
parse_args_long_arguments=0;
return 1;
fi;
if [ -z "$parse_args_long_arguments" ]; then
for argument in "$@"; do
(( parse_args_long_arguments++ ))
done
parse_args_long_arguments=$(( $parse_args_long_arguments - $# ));
fi
local tmp_arg_pos;
local require_arg_value=false;
parse_args_value="";
parse_args_key="";
if [ "$parse_args_argument_position" ]; then
tmp_arg_pos=$parse_args_argument_position;
else
tmp_arg_pos=0;
fi;
for argument in "$@"; do
if ((tmp_arg_pos > 0)); then
(( tmp_arg_pos-- ))
continue;
fi;
(( parse_args_argument_position++ ))
local arg_size=${#argument}
if (( arg_size == 2 )); then
if [[ "$argument" == "-"* ]]; then
if $require_arg_value; then
(( parse_args_argument_position-- ))
return 0;
fi
parse_args_key="${argument#?}";
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
parse_args_value="";
return 0;
fi
require_arg_value=true;
continue;
fi
elif (( arg_size >= 3 )) && [[ "$argument" == "--"* ]]; then
if $require_arg_value; then
(( parse_args_argument_position-- ))
return 0;
fi
parse_args_key="${argument#??}";
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
parse_args_value="";
return 0;
fi
require_arg_value=true;
continue;
fi
if $require_arg_value; then
if [ "$parse_args_value" ]; then
parse_args_value="$parse_args_value $argument";
else
parse_args_value="$argument";
fi
parse_args_get_complete_counter;
if [ "$#" -eq $? ]; then
return 0;
fi
continue;
fi
done;
parse_args_argument_position=0;
parse_args_long_arguments=0;
return 1;
}

parse_args_get_full_key() {
local parse_args_key_size=${#parse_args_key}
local full_argument;
if (( parse_args_key_size == 1 )); then
full_argument="-${parse_args_key}";
elif (( parse_args_key_size > 1 )); then
full_argument="--${parse_args_key}";
fi
if (( parse_args_key_size >= 1 )); then
   echo "\"$full_argument\"";
else
   echo "$parse_args_key";
fi
}

parse_args_ensure_argument() {
if [ -z "$parse_args_value" ]; then
   echo "Please specify value for `parse_args_get_full_key`\nUse --help if needed.";
   exit 1;
 fi
}


while parse_args "$@"; do
case $parse_args_key in
        a | append)
		    parse_args_ensure_argument;
			APPEND="$parse_args_value";
			;;
		c | config)
		    parse_args_ensure_argument
			CONFIG="$parse_args_value";
			;;
		d | device)
		    parse_args_ensure_argument
			DEVICE="$parse_args_value";
			;;
	    i | id)
		    parse_args_ensure_argument;
			CHAT_ID="$parse_args_value";
			;;
		n | name)
		    parse_args_ensure_argument;
			NAME="$parse_args_value";
			;;
		t | token)
		    parse_args_ensure_argument;
			TOKEN="$parse_args_value";
			;;
		w | website)
		    parse_args_ensure_argument;
			WEBSITE="$parse_args_value";
			;;
		h | help)
			usage
			;;
		 *)
			echo -e "Unsupported argument: `parse_args_get_full_key`\nUse --help if needed.";
			exit 1;
			;;
	esac
done

if [ -z "$TOKEN" ]; then
	echo "Please specify telegram bot api token!"
	exit 1
fi

if [ -z "$CHAT_ID" ]; then
	echo "Please set telegram chat id to send the message to!"
	exit 1
fi

if [ -z "$NAME" ]; then
	echo "Please set formatted project name for TG posts!"
	exit 1
fi

if [ -z "$WEBSITE" ]; then
	echo "Please set website link to search for!"
	exit 1
fi

get_str_by_pos() {
local_arr=($1)
echo ${local_arr[$2-1]}
}

scissors() {
if [ "$2" = "/" ]; then
echo "`get_str_by_pos "${1//\// }" $3`";
else
echo "`get_str_by_pos "${1//2/ }" $3`";
fi
}

if [ -z "$CONFIG" ]; then
CONFIG_WEBSITE="`scissors ${WEBSITE} / 2`";
if [ -z "$DEVICE" ]; then
	CONFIG="${CONFIG_WEBSITE}_${CHAT_ID}.config";
else
    CONFIG="${CONFIG_WEBSITE}.${DEVICE}_${CHAT_ID}.config";
fi
fi


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
 
website_exists() {
local website="$1";
local host="`scissors ${website} / 2`";
if curl -k -L --output /dev/null --silent --head --fail -b cookiefile -c cookiefile -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H 'authority: $host' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website"; then
  return 0;
else
  return 1;
fi
}

if ! website_exists "$WEBSITE"; then
echo "Unable to locate specified website, are you sure that $WEBSITE exists?";
exit 1;
fi

codenames=(
"Yaris_M_GSM" "Alcatel Pop C2"
"dl750" "Alcatel Pop D3"
"ttab" "Telekom Puls"
"x2xtreme" "Allview X2 Soul Xtreme"
"otter" "Amazon Kindle Fire (1st Gen)"
"soho" "Amazon Kindle Fire HD (3rd Generation)"
"ac55diselfie" "Archos 55 Diamond Selfie"
"ac50da" "Archos 50 Diamond"
"ac80cxe" "Archos 80c Xenon"
"tf300t" "Asus Transformer TF300T"
"tilapia" "Asus Nexus 7 2012 3G"
"grouper" "Asus Nexus 7 2012 Wi-Fi"
"deb" "Asus Nexus 7 2013 LTE"
"flo" "Asus Nexus 7 2013 Wi-Fi"
"fugu" "Asus Nexus Player"
"A66" "Asus PadFone 1"
"A68" "Asus PadFone 2"
"tf101" "Asus Transformer TF101"
"tf700t" "Asus Transformer Infinity TF700T"
"tf201" "Asus Transformer Prime TF201"
"Z00A" "Asus ZenFone 2 1080p"
"Z008" "Asus ZenFone 2 720p"
"Z00T" "Asus ZenFone 2 Laser 1080p"
"Z00L" "Asus ZenFone 2 Laser 720p"
"Z01K" "ASUS ZenFone 4 (2017)"
"X00I" "Asus ZenFone 4 Max"
"X00T" "Asus ZenFone Max Pro M1"
"Z01G" "ASUS ZenFone 4 Pro"
"Z01M" "ASUS ZenFone 4 Selfie Pro"
"X01AD" "ASUS ZenFone Max M2"
"X01BD" "ASUS ZenFone Max Pro M2"
"dendeone" "BQ Aquaris A4.5"
"kaito_wifi" "BQ Aquaris E10"
"puar" "BQ Aquaris E4"
"krillin" "BQ Aquaris E4.5"
"vegetalte" "BQ Aquaris E5 4G"
"vegetafhd" "BQ Aquaris E5FHD"
"vegetahd" "BQ Aquaris E5HD"
"bulma" "BQ Aquaris E6"
"freezerhd" "BQ Aquaris M10"
"freezerfhd" "BQ Aquaris M10 FHD"
"freezerlte" "BQ Aquaris M10 4G"
"dende" "BQ Aquaris M4.5"
"piccolo" "BQ Aquaris M5"
"namek" "BQ Aquaris M5.5"
"Aquaris_M8" "BQ Aquaris M8"
"chaozu" "BQ Aquaris U (chaozu)"
"yamcha" "BQ Aquaris U2 (yamcha)"
"yamchalite" "BQ Aquaris U2 Lite (yamchalite)"
"chaozulite" "BQ Aquaris U Lite (chaozulite)"
"tenshi" "BQ Aquaris U Plus (tenshi)"
"nappa" "BQ Aquaris V (nappa)"
"raditz" "BQ Aquaris V Plus (raditz)"
"bardock" "BQ Aquaris X (bardock)"
"piccolometal" "BQ Aquaris X5 (piccolometal/paella)"
"gohan" "BQ Aquaris X5 Plus (gohan)"
"bardock" "BQ Aquaris X Pro (bardock)"
"curie2qc" "BQ Curie 2 QC"
"edison2qc" "BQ Edison 2 QC"
"edison3mini" "BQ Edison 3 Mini"
"maxwell2" "BQ Maxwell 2"
"maxwell2lite" "BQ Maxwell 2 Lite"
"maxwell2plus" "BQ Maxwell 2 Plus"
"maxwell2qc" "BQ Maxwell 2 QC"
"b15q" "Cat B15q"
"streak7" "Dell Streak 7"
"p9000" "Elephone P9000"
"mata" "Essential PH-1"
"FP2" "Fairphone 2"
"molly" "ADT-1 Android TV"
"sprout" "Android One"
"gm9pro_sprout" "Android One Fifth Generation"
"GM6_s_sprout" "Android One Fourth Generation"
"seed" "Android One Second Generation Qualcomm"
"seedmtk" "Android One Second Generation MTK"
"shamrock" "Android One Third Generation"
"sailfish" "Google Pixel"
"walleye" "Google Pixel 2"
"taimen" "Google Pixel 2 XL"
"blueline" "Google Pixel 3"
"sargo" "Google Pixel 3a"
"bonito" "Google Pixel 3a XL"
"crosshatch" "Google Pixel 3 XL"
"dragon" "Google Pixel C"
"marlin" "Google Pixel XL"
"tenderloin" "HP TouchPad"
"pme" "HTC 10"
"a11ul" "HTC Desire 510 EU"
"a31ul" "HTC Desire 620"
"a55ml_dtul" "HTC E9+"
"ruby" "HTC Amaze 4G"
"aca" "HTC Bolt/10 Evo"
"b2ul" "HTC Butterfly 2"
"dlxu" "HTC Butterfly X920d"
"dlxub1" "HTC Butterfly X9202"
"a56dj" "HTC Desire 10 lifestyle"
"brepdugl" "HTC Desire 12+"
"a11" "HTC Desire 510 USA 32bit"
"zaracl" "HTC Desire 601 CDMA"
"zara" "HTC Desire 601 GSM"
"a3ul" "HTC Desire 610"
"a32e" "HTC Desire 626s"
"a5" "HTC Desire 816"
"a51cml_tuhl" "HTC Desire 830"
"golfu" "HTC Desire C"
"ace" "HTC Desire HD"
"saga" "HTC Desire S"
"protou" "HTC Desire X"
"dlx" "HTC Droid DNA"
"inc" "HTC Droid Incredible"
"vivow" "HTC Droid Incredible 2"
"fireball" "HTC Droid Incredible 4G"
"shooter" "HTC EVO 3D CDMA 4G WiMAX"
"shooteru" "HTC EVO 3D GSM"
"supersonic" "HTC EVO 4G"
"jewel" "HTC EVO 4G LTE"
"speedy" "HTC EVO Shift 4G"
"pico" "HTC Explorer"
"mystul" "HTC First"
"leo" "HTC HD2"
"heroc" "HTC Hero CDMA"
"vivo" "HTC Incredible S"
"lexicon" "HTC Merge"
"flounder" "HTC Nexus 9"
"passion" "HTC Nexus One"
"hiae" "HTC One A9"
"e8" "HTC One E8"
"m7cd" "HTC One m7 Dual SIM"
"m7" "HTC One m7 GSM"
"m7wls" "HTC One m7 Sprint"
"m7wlv" "HTC One m7 Verizon"
"m8" "HTC One M8 All Variants"
"hima" "HTC One M9"
"t6univ" "HTC One Max Universal"
"m4ul" "HTC One Mini"
"memwl" "HTC One Remix"
"villec" "HTC One S (S3 processor)"
"ville" "HTC One S (S4 processor)"
"ville_u" "HTC One S (S4 processor) Special Edition 64GB"
"k2_cl" "HTC One SV Boost USA"
"k2_plc_cl" "HTC One SV Cricket USA"
"k2_u" "HTC One SV GSM"
"k2_ul" "HTC One SV LTE"
"primou" "HTC One V GSM"
"primoc" "HTC One V Virgin Mobile"
"totemc2" "HTC One VX"
"e66_dugl" "HTC One X10 Dual Sim"
"evita" "HTC One X AT&T"
"endeavoru" "HTC One X International Tegra"
"evitareul" "HTC One X+ AT&T"
"enrc2b" "HTC One X+ International"
"pyramid" "HTC Sensation"
"runnymede" "HTC Sensation XL"
"mecha" "HTC Thunderbolt"
"ocn" "HTC U11"
"hay" "HTC U11 EYEs"
"ime" "HTC U12+"
"oce" "HTC U Ultra"
"holiday" "HTC Vivid"
"marvel" "HTC Wildfire S GSM"
"huanghe" "Amazfit Pace"
"mt2l03" "Huawei Ascend Mate 2"
"y550" "Huawei Ascend Y550"
"u8951" "Huawei G510"
"rio" "Huawei G8"
"cherry" "Huawei Honor 4X"
"nemo" "Huawei Honor 5C"
"kiwi" "Huawei Honor 5X"
"mogolia" "Huawei Honor 6"
"pine" "Huawei Honor 6 Plus"
"berlin" "Huawei Honor 6X"
"plank" "Huawei Honor 7"
"frd" "Huawei Honor 8"
"berkeley" "Huawei Honor View 10"
"blanc" "Huawei Mate 10 Pro"
"next" "Huawei Mate 8"
"carrera" "Huawei Mate S"
"mozart" "Huawei Mediapad M2 8.0"
"angler" "Huawei Nexus 6P"
"charlotte" "Huawei P20 Pro"
"grace" "Huawei P8"
"eva" "Huawei P9"
"vienna" "Huawei P9 Plus"
"u8815" "Huawei U8815"
"u8833" "Huawei Y300"
"CRO_U00" "Huawei Y3 2017"
"titanlte" "Hyundai Titan LTE"
"d5110" "Infinix Hot 2"
"u3" "IUNI U3"
"thunder_q45" "Kazam Thunder Q4.5"
"tornado_348" "Kazam Tornado 348"
"s2" "LeEco Le 2"
"x2" "LeEco Le Max 2"
"max_plus" "LeEco Le Max Pro"
"zl1" "LeEco Le Pro3"
"zl0" "LeEco Le Pro3 Elite"
"A6020" "Lenovo Vibe K5/K5 Plus"
"X704F" "Lenovo Tab4 10 Plus"
"aio_row" "Lenovo A7000-a"
"wt86518" "Lenovo K30-T"
"karate" "Lenovo K33"
"karatep" "Lenovo K53"
"k5fpr" "Lenovo K4 Note"
"manning" "Lenovo K8 Note"
"kuntao" "Lenovo P2a42"
"b8080f" "Lenovo Yoga HD 10+ Wi-Fi"
"yt_x703f" "Lenovo Yoga Tab 3 Plus Wifi"
"yt_x703l" "Lenovo Yoga Tab 3 Plus LTE"
"x1" "Letv Le 1 Pro"
"x3" "Letv/LeEco Le 1S"
"G2" "LG G2"
"d850" "LG G3 AT&T"
"d852" "LG G3 Canada Bell Rogers"
"d852g" "LG G3 Canada Wind, Videotron, Sasktel"
"d855" "LG G3 Europe"
"f400" "LG G3 Korea"
"ls990" "LG G3 Sprint"
"d851" "LG G3 T-Mobile"
"us990" "LG G3 US Cellular"
"vs985" "LG G3 Verizon"
"G4, F500, LS991, H810, H811, H812, H815, H819, US991, VS986" "LG G4"
"c90" "LG G4c"
"f500" "LG G4"
"h810" "LG G4"
"h811" "LG G4"
"h812" "LG G4"
"h815" "LG G4"
"h819" "LG G4"
"ls991" "LG G4"
"us991" "LG G4"
"vs986" "LG G4"
"h830" "LG G5 T-Mobile"
"h840" "LG G5 SE International"
"h850" "LG G5 International"
"rs988" "LG G5 US Carrier-Unlocked"
"f340k" "LG G Flex Korean"
"h870" "LG G6 International"
"e9wifi" "LG G Pad 10.1"
"v500" "LG G Pad 8.3 (v500, v510, awifi, palman)"
"dory" "LG G Watch"
"lenok" "LG G Watch"
"m216" "LG K10"
"m1" "LG K7"
"w7,w7ds,w7n" "LG L90"
"c50" "LG Leon LTE"
"mako" "LG Nexus 4"
"hammerhead" "LG Nexus 5"
"bullhead" "LG Nexus 5X"
"p930" "LG Nitro HD"
"p990" "LG Optimus 2x"
"p880" "LG Optimus 4x HD"
"p970" "LG Optimus Black"
"l34c" "LG Optimus Fuel"
"geeb" "LG Optimus G AT&T"
"e980" "LG Optimus G Pro GSM"
"geehrc4g" "LG Optimus G Sprint"
"su640" "LG Optimus LTE"
"p500" "LG Optimus One"
"gelato" "LG Optimus Slider"
"c70n" "LG Spirit LTE (H440N)"
"ph2n" "LG Stylo 2 Plus"
"sf340n" "LG Stylo 3 Plus"
"p999" "LG T-Mobile G2x"
"bass" "LG Watch Urbane"
"mobee01a" "LYF Water 8"
"KB-1501" "Marshall London"
"NabiSE" "Nabi SE"
"m1721" "Meizu M6 Note"
"a117" "Micromax Canvas Magnus"
"pace" "Micromax Canvas Pace 4G"
"p200_2G" "Minix NEO U1"
"byt_t_crv2" "Minix Z64 Android"
"skipjack" "Mobvoi TicWatch C2"
"catfish" "Mobvoi TicWatch Pro"
"catshark" "Mobvoi TicWatch Pro 4G/LTE"
"olympus" "Motorola Atrix 4G"
"jordan" "Motorola Defy"
"minnow" "Motorola Moto 360"
"condor" "Motorola Moto E"
"taido" "Motorola Moto E 2016"
"woods" "Motorola Moto E4"
"nicklaus" "Motorola Moto E4 Plus"
"nora" "Motorola Moto E5"
"james" "Motorola Moto E5 Play"
"hannah" "Motorola Moto E5 Plus"
"surnia" "Motorola Moto E LTE"
"falcon" "Motorola Moto G 2013"
"peregrine" "Motorola Moto G 2013 LTE"
"titan" "Motorola Moto G 2014"
"thea" "Motorola Moto G 2014 LTE"
"osprey" "Motorola Moto G 2015"
"harpia" "Motorola Moto G4 Play"
"cedric" "Motorola Moto G5"
"potter" "Motorola Moto G5 Plus"
"montana" "Motorola Moto G5S"
"ali" "Motorola Moto G6"
"evert" "Motorola Moto G6 Plus"
"river" "Motorola Moto G7"
"lake" "Motorola Moto G7 Plus"
"athene" "Motorola Moto G4/G4 Plus"
"quark" "Motorola Moto MAXX"
"chef" "Motorola Moto One Power"
"ghost" "Motorola Moto X 2013"
"victara" "Motorola Moto X 2014"
"clark" "Motorola Moto X 2015 Pure"
"payton" "Motorola Moto X4"
"kinzie" "Motorola Moto X Force"
"griffin" "Motorola Moto Z 2016"
"nash" "Motorola Moto Z2 Force"
"messi" "Motorola Moto Z3"
"beckham" "Motorola Moto Z3 Play"
"addison" "Motorola Moto Z Play 2016"
"shamu" "Motorola Nexus 6"
"sunfire" "Motorola Photon 4G"
"asanti_c" "Motorola Photon Q"
"wingray" "Motorola Xoom"
"ether" "Nextbit Robin"
"PLE" "Nokia 6 (2017)"
"DRG" "Nokia 6.1 Plus"
"PL2" "Nokia 6.1"
"NB1" "Nokia 8"
"nx511j" "Nubia ZTE Z9 mini"
"nx512j" "Nubia ZTE Z9Max"
"NX551J" "Nubia M2"
"nx563j" "Nubia ZTE Z17"
"nx589j" "Nubia Z17 Mini S"
"nx609" "Nubia ZTE 红魔电竞游戏手机"
"foster" "NVidia Shield Android TV"
"roth" "NVidia Shield Portable"
"shieldtablet" "NVidia Shield Tablet"
"x201" "Omate TrueSmart"
"cheeseburger" "OnePlus 5"
"dumpling" "OnePlus 5T"
"enchilada" "OnePlus 6 (enchilada)"
"fajita" "OnePlus 6T (fajita)"
"guacamoleb" "OnePlus 7 (guacamoleb)"
"guacamole" "OnePlus 7 Pro (guacamole)"
"bacon" "OnePlus One"
"oneplus3" "OnePlus 3/3T"
"oneplus2" "OnePlus Two"
"onyx" "OnePlus X"
"f1f" "Oppo F1"
"find5" "Oppo Find 5"
"find7" "Oppo Find 7"
"N1" "Oppo N1"
"n3" "Oppo N3"
"r5" "Oppo R5"
"r7f" "Oppo R7f"
"r7plusf" "Oppo R7 Plus f"
"r7sf" "Oppo R7sf"
"R819" "Oppo R819"
"RMX1801" "Realme 2 Pro"
"RMX1851" "Realme 3 Pro"
"k10" "OUKITEL K10"
"mix2" "OUKITEL MIX 2"
"wp1" "OUKITEL WP1"
"ef63" "Pantech VEGA Iron 2"
"ef56" "Pantech VEGA LTE-A"
"ef59" "Pantech VEGA Screct Note"
"ef60" "Pantech VEGA Screct UP"
"geminipda" "Planet Gemini PDA"
"dorado" "Verizon Wear24"
"pearlyn" "Razer Forge TV (pearlyn)"
"cheryl" "Razer Phone (cheryl)"
"spartan" "Realme 3"
"a33g" "Samsung A300H"
"c9lte" "Samsung Galaxy C9 Pro (C900F/Y)"
"c9ltechn" "Samsung Galaxy C9 Pro (China)"
"gprimelte" "Samsung Galaxy Grand Prime (SM-G530T/T1/W)"
"gprimeltespr" "Samsung Galaxy Grand Prime (SM-G530P)"
"gprimeltetfnvzw" "Samsung Galaxy Grand Prime (SM-S920L)"
"gprimeltexx" "Samsung Galaxy Grand Prime (SM-G530FZ)"
"gprimeltezt" "Samsung Galaxy Grand Prime (SM-G530MU)"
"grandprimeve3g" "Samsung Galaxy Grand Prime VE 3G"
"gtelwifiue" "Samsung Galaxy Tab E (SM-T560NU)"
"gtesqltespr" "Samsung Galaxy Tab E (SM-T377P)"
"j53gxx" "Samsung Galaxy J5 3G (SM-J500H)"
"j5lte" "Samsung Galaxy J5 LTE (SM-J500F/G/M/NO/Y)"
"j5ltechn" "Samsung Galaxy J5 LTE (SM-J5008)"
"j5nlte" "Samsung Galaxy J5N LTE (SM-J500FN)"
"o7prolte" "Samsung Galaxy On7 Pro (SM-G600FY)"
"fascinatemtd" "Samsung Galaxy S Fascinate"
"epicmtd" "Samsung Epic 4g"
"a3xelte" "Samsung Galaxy A3 2016 (Exynos)"
"a3y17lte" "Samsung Galaxy A3 2017"
"a5xelte" "Samsung Galaxy A5 2016 (Exynos)"
"a5y17lte" "Samsung Galaxy A5 2017"
"a7xelte" "Samsung Galaxy A7 2016 (Exynos)"
"a7y17lte" "Samsung Galaxy A7 2017"
"jackpotlte" "Samsung Galaxy A8 2018"
"jackpot2lte" "Samsung Galaxy A8+ 2018"
"loganreltexx" "Samsung Galaxy Ace 3"
"vivalto5mve3g" "Samsung Galaxy Ace 4 (SM-G316HU)"
"slte" "Samsung Galaxy Alpha"
"kanas3gnfc" "Samsung Galaxy Core 2 SM-G355HN"
"cs02" "Samsung Galaxy Core Plus"
"core33g" "Samsung Galaxy Core Prime 3G SM-G360H"
"coreprimelte" "Samsung Galaxy Core Prime Qualcomm"
"cprimeltemtr" "Samsung Galaxy Core Prime Qualcomm CDMA"
"expressltexx" "Samsung Galaxy Express"
"wilcoxltexx" "Samsung Galaxy Express 2"
"i9082" "Samsung Galaxy Grand Duos"
"fortuna3g" "Samsung Galaxy Grand Prime"
"grandprimevelte" "Samsung Galaxy Grand Prime VE"
"j1acelte" "Samsung Galaxy J1 Ace (SM-J110)"
"j2lte" "Samsung Galaxy J2 (SM-J200)"
"j2y18lte" "Samsung Galaxy J2 2018 SM-J250G"
"j3lte" "Samsung Galaxy J3 2016 Qualcomm (SM-J320YZ)"
"on5xelte" "Samsung Galaxy J5 Prime"
"j7ltespr" "Samsung Galaxy J7 (2015 Qualcomm Sprint)"
"j7xelte" "Samsung Galaxy J7 (2016 Exynos)"
"j7popltespr" "Samsung Galaxy J7 (2017 Qualcomm Sprint)"
"j7elte" "Samsung Galaxy J7 Exynos SM-J700"
"crater" "Samsung Galaxy Mega 5.8"
"melius" "Samsung Galaxy Mega 6.3"
"maguro" "Samsung Galaxy Nexus (GSM)"
"toroplus" "Samsung Galaxy Nexus (Sprint)"
"toro" "Samsung Galaxy Nexus (Verizon)"
"p4noterf" "Samsung Galaxy Note 10.1"
"lt03wifiue" "Samsung Galaxy Note 10.1 (2014) Exynos Wi-Fi"
"lt03ltexx" "Samsung Galaxy Note 10.1 (2014) Qualcomm LTE"
"quincyatt" "Samsung Galaxy Note 1 AT&T"
"quincytmo" "Samsung Galaxy Note 1 T-Mobile"
"t0lteatt" "Samsung Galaxy Note 2 AT&T"
"t0ltecan" "Samsung Galaxy Note 2 Canada"
"t03g" "Samsung Galaxy Note 2 N7100"
"t0lte" "Samsung Galaxy Note 2 N7105"
"l900" "Samsung Galaxy Note 2 Sprint"
"t0ltektt" "Samsung Galaxy Note 2 LTE Korea"
"t0lteskt" "Samsung Galaxy Note 2 LTE SK Telecom"
"t0ltetmo" "Samsung Galaxy Note 2 T-Mobile"
"t0ltevzw" "Samsung Galaxy Note 2 Verizon"
"ha3g" "Samsung Galaxy Note 3 International Exynos"
"hlltexx" "Samsung Galaxy Note 3 Neo"
"hl3g" "Samsung Galaxy Note 3 Neo N750"
"hlte" "Samsung Galaxy Note 3 (Americas, China, Europe & Korea)"
"tbltecan" "Samsung Galaxy Note 4 Edge (Canada)"
"tblte" "Samsung Galaxy Note 4 Edge (International)"
"tbltedt" "Samsung Galaxy Note 4 Edge (Korea)"
"tbltespr" "Samsung Galaxy Note 4 Edge (Sprint)"
"tbltetmo" "Samsung Galaxy Note 4 Edge (T-Mobile)"
"tblteusc" "Samsung Galaxy Note 4 Edge (US Celluar)"
"tbltevzw" "Samsung Galaxy Note 4 Edge (Verizon)"
"tre3gxx" "Samsung Galaxy Note 4 Exynos 3g"
"treltexx" "Samsung Galaxy Note 4 Exynos LTE (treltexx)"
"trlte" "Samsung Galaxy Note 4 (Qualcomm)"
"noblelte" "Samsung Galaxy Note 5"
"graceqltechn" "Samsung Galaxy Note 7 (China Qualcomm)"
"gracelte" "Samsung Galaxy Note 7 (Exynos)"
"greatlte" "Samsung Galaxy Note 8 (Exynos)"
"n5100" "Samsung Galaxy Note 8.0"
"n7000" "Samsung Galaxy Note 1 N7000"
"v1a3gxx" "Samsung Galaxy Note Pro 12.2 Exynos 3G"
"v1awifi" "Samsung Galaxy Note Pro 12.2 Wi-Fi"
"viennaltexx" "Samsung Galaxy Note Pro 12.2 Qualcomm LTE SM-P905"
"on5ltetmo" "Samsung Galaxy On5 (T-Mobile/MetroPCS)"
"prevail2spr" "Samsung Galaxy Prevail"
"iconvmu" "Samsung Galaxy Reverb"
"comanche" "Samsung Galaxy Rugby Pro SGH-i547"
"beyond1lte" "Samsung Galaxy S10 (Exynos)"
"beyond0lte" "Samsung Galaxy S10e (Exynos)"
"beyond2lte" "Samsung Galaxy S10+ (Exynos)"
"exhilarate" "Samsung Galaxy S2 Exhilarate SGH-i577"
"hercules" "Samsung Galaxy S2 Hercules T-Mobile SGH-t989"
"i9100" "Samsung Galaxy S II (International)"
"s2ve" "Samsung Galaxy S2 Plus"
"skyrocket" "Samsung Galaxy S2 AT&T Skyrocket SGH-i727"
"d2att" "Samsung Galaxy S3 AT&T"
"d2can" "Samsung Galaxy S3 Canada"
"d2cri" "Samsung Galaxy S3 Cricket"
"i9300" "Samsung Galaxy S3 International Exynos"
"i9305" "Samsung Galaxy S III (International LTE)"
"d2mtr" "Samsung Galaxy S3 Metro PCS"
"golden" "Samsung Galaxy S3 Mini"
"s3ve3g" "Samsung Galaxy S3 Neo i9301i"
"d2spr" "Samsung Galaxy S3 Sprint"
"d2tmo" "Samsung Galaxy S3 T-Mobile"
"d2usc" "Samsung Galaxy S3 US Cellular"
"d2vzw" "Samsung Galaxy S3 Verizon"
"jactivelte" "Samsung Galaxy S4 Active"
"jfltespi" "Samsung Galaxy S4 C-Spire"
"jgedlte" "Samsung Galaxy S4 Google Edition"
"i9500" "Samsung Galaxy S4 Exynos (ja3g)"
"jflte" "Samsung Galaxy S4 (Qualcomm)"
"ks01lte" "Samsung Galaxy S4 LTE Advanced i9506"
"serrano3gxx" "Samsung Galaxy S4 Mini (International 3G)"
"serranoveltexx" "Samsung Galaxy S4 Mini 64 bit ONLY"
"serranodsdd" "Samsung Galaxy S4 Mini (International Dual SIM)"
"serranoltexx" "Samsung Galaxy S4 Mini (International LTE)"
"serranolteusc" "Samsung Galaxy S4 Mini US Cellular"
"jfvelte" "Samsung Galaxy S4 (Value Edition)"
"k3gxx" "Samsung Galaxy S5 Exynos"
"lentislte" "Samsung Galaxy S5 LTE-A"
"kminilte" "Samsung Galaxy S5 Mini Exynos"
"s5neolte" "Samsung Galaxy S5 Neo Exynos"
"kccat6" "Samsung Galaxy S5 Plus"
"klte" "Samsung Galaxy S5 Qualcomm"
"zeroflte" "Samsung Galaxy S6"
"zerolte" "Samsung Galaxy S6 edge"
"zenlte" "Samsung Galaxy S6 edge+"
"herolte" "Samsung Galaxy S7 (Exynos)"
"heroqltechn" "Samsung Galaxy S7 (China Qualcomm)"
"hero2lte" "Samsung Galaxy S7 edge (Exynos)"
"hero2qltechn" "Samsung Galaxy S7 edge (China Qualcomm)"
"dreamlte" "Samsung Galaxy S8 (Exynos)"
"dream2lte" "Samsung Galaxy S8+ (Exynos)"
"dream2qlte" "Samsung Galaxy S8+ (Snapdragon)"
"dreamqlte" "Samsung Galaxy S8 (Snapdragon)"
"starlte" "Samsung Galaxy S9 (Exynos)"
"star2lte" "Samsung Galaxy S9+ (Exynos)"
"star2qltechn" "Samsung Galaxy S9+ (Snapdragon)"
"starqltechn" "Samsung Galaxy S9 (Snapdragon)"
"SGH-T769" "Samsung Galaxy S Blaze 4G"
"logan2g" "Samsung Galaxy Star Pro"
"jaspervzw" "Samsung Galaxy Stellar 4G (SCH-i200 Verizon)"
"p5100" "Samsung Galaxy Tab 2 10.1 (GSM)"
"p5110" "Samsung Galaxy Tab 2 10.1 (Wi-Fi)"
"p3100" "Samsung Galaxy Tab 2 7.0 (GSM)"
"p3110" "Samsung Galaxy Tab 2 7.0 (Wi-Fi)"
"espresso3g" "Samsung Galaxy Tab 2 (GSM - unified)"
"espressowifi" "Samsung Galaxy Tab 2 (Wi-Fi - unified)"
"lt02ltetmo" "Samsung Galaxy Tab 3 7.0 LTE"
"goyave" "Samsung Galaxy Tab 3 Lite 7.0 3G"
"matisse" "Samsung Galaxy Tab 4 10.1 (all variants)"
"degas" "Samsung Galaxy Tab 4 7.0"
"p6810" "Samsung Galaxy Tab 7.7"
"gtanotexllte" "Samsung Galaxy Tab A 10.1 LTE (2016) with S-Pen"
"gtaxlwifi" "Samsung Galaxy Tab A 10.1 WiFi (2016)"
"gtanotexlwifi" "Samsung Galaxy Tab A 10.1 WiFi (2016) with S-Pen"
"a8hplte" "Samsung Galaxy Tab A 8.0 LTE SM-A800i"
"gt510wifi" "Samsung Galaxy Tab A 9.7 WiFi"
"gteslte" "Samsung Galaxy Tab E 8.0 Exynos"
"picassowifi" "Samsung Galaxy Tab Pro 10.1 Wi-Fi"
"picassoltexx" "Samsung Galaxy Tab Pro 10.1 LTE"
"v2awifi" "Samsung Galaxy Tab Pro 12.2 Wi-Fi"
"mondrianlte" "Samsung Galaxy Tab Pro 8.4 LTE"
"mondrianwifi" "Samsung Galaxy Tab Pro 8.4 Wi-Fi"
"chagallwifi" "Samsung Galaxy Tab S 10.5 WiFi"
"chagalllte" "Samsung Galaxy Tab S 10.5 LTE"
"gts28velte" "Samsung Galaxy Tab S2 8.0 LTE (2016)"
"gts28ltexx" "Samsung Galaxy Tab S2 8.0 2015 (LTE)"
"gts28wifi" "Samsung Galaxy Tab S2 8.0 2015 (Wi-Fi)"
"gts28vewifi" "Samsung Galaxy Tab S2 8.0 WiFi (2016)"
"gts210velte" "Samsung Galaxy Tab S2 9.7 LTE (2016)"
"gts210ltexx" "Samsung Galaxy Tab S2 9.7 2015 (LTE)"
"gts210wifi" "Samsung Galaxy Tab S2 9.7 2015 (Wi-Fi)"
"gts210vewifi" "Samsung Galaxy Tab S2 9.7 WiFi (2016)"
"gts4lwifi" "Samsung Galaxy Tab S4"
"gts4lvwifi" "Samsung Galaxy Tab S5e WiFi"
"klimtwifi" "Samsung Galaxy Tab S 8.4 WiFi"
"klimtlte" "Samsung Galaxy Tab S 8.4 LTE"
"kyleve" "Samsung Galaxy Trend"
"kylevess" "Samsung Galaxy Trend Lite"
"kylepro" "Samsung Galaxy Trend Plus GT-S7580"
"vivalto3gvn" "Samsung Galaxy V SM-G313HZ"
"goghspr" "Samsung Galaxy Victory 4G LTE"
"xcover3ltexx" "Samsung Galaxy Xcover 3"
"xcover3velte" "Samsung Galaxy Xcover 3 VE (SM-G389F)"
"sprat" "Samsung Gear Live"
"manta" "Samsung Nexus 10"
"crespo" "Samsung Nexus S"
"crespo4g" "Samsung Nexus S 4G"
"bp2" "Silent Circle Blackphone 2"
"taoshan" "Sony Xperia L"
"nicki" "Sony Xperia M"
"nozomi" "Sony Xperia S"
"huashan" "Sony Xperia SP"
"mint" "Sony Xperia T"
"pollux" "Sony Xperia Tablet Z LTE"
"pollux_windy" "Sony Xperia Tablet Z Wi-Fi"
"hayabusa" "Sony Xperia TX"
"tsubasa" "Sony Xperia V"
"suzu" "Sony Xperia X"
"pioneer" "Sony Xperia XA2"
"voyager" "Sony Xperia XA2 Plus"
"discovery" "Sony Xperia XA2 Ultra"
"kugo" "Sony Xperia X Compact"
"dora" "Sony Xperia X Performance"
"kagura" "Sony Xperia XZ"
"maple" "Sony Xperia XZ Premium"
"yuga" "Sony Xperia Z"
"honami" "Sony Xperia Z1"
"sirius" "Sony Xperia Z2"
"z3c" "Sony Xperia Z3 Compact"
"scorpion_windy" "Sony Xperia Z3 Tablet Compact Wi-Fi"
"odin" "Sony Xperia ZL"
"dogo" "Sony Xperia ZR"
"togari" "Sony Xperia Z Ultra"
"twrp" "Android Emulator"
"Armor_6" "Ulefone Armor 6"
"f1_play" "UMIDIGI F1 Play"
"One_Max" "UMIDIGI One Max"
"aubrey" "UMIDIGI S3 Pro"
"jellypro" "Unihertz Jelly Pro (MT6737T)"
"a315" "Vanzo A315"
"orka" "Vestel Venus V4"
"porridge" "Wileyfox Spark and Spark+"
"porridgek3" "Wileyfox Spark X"
"crackling" "Wileyfox Swift"
"marmite" "Wileyfox Swift 2, 2 Plus, and 2 X"
"wt88047" "Wingtech Redmi 2"
"helium" "Xiaomi Mi Max Pro"
"aries" "Xiaomi Mi 2/2S"
"cancro" "Xiaomi Mi 3"
"libra" "Xiaomi Mi 4c"
"ferrari" "Xiaomi Mi 4i"
"gemini" "Xiaomi Mi 5"
"capricorn" "Xiaomi Mi 5s"
"natrium" "Xiaomi Mi 5s Plus"
"sagit" "Xiaomi Mi 6"
"wayne" "Xiaomi MI 6X"
"dipper" "Xiaomi Mi 8"
"tissot" "Xiaomi Mi A1"
"jasmine_sprout" "Xiaomi Mi A2"
"daisy" "Xiaomi Mi A2 Lite"
"hydrogen/helium" "Xiaomi Mi Max"
"oxygen" "Xiaomi Mi Max 2"
"nitrogen" "Xiaomi Mi Max 3"
"lithium" "Xiaomi Mi MIX"
"chiron" "Xiaomi Mi Mix 2"
"polaris" "Xiaomi Mi Mix 2S"
"scorpio" "Xiaomi Mi Note 2"
"jason" "Xiaomi Mi Note 3"
"mocha" "Xiaomi Mi Pad"
"perseus" "Xiaomi Mi MIX 3"
"beryllium" "Xiaomi Pocophone F1"
"armani" "Xiaomi Redmi 1S"
"ido" "Xiaomi Redmi 3"
"land" "Xiaomi Redmi 3S/Prime/3X"
"rolex" "Xiaomi Redmi 4A"
"santoni" "Xiaomi Redmi 4X"
"rosy" "Xiaomi Redmi 5"
"riva" "Xiaomi Redmi 5A"
"vince" "Xiaomi Redmi 5 Plus"
"cereus" "Xiaomi Redmi 6"
"cactus" "Xiaomi Redmi 6a"
"sakura" "Xiaomi Redmi 6 Pro"
"hermes" "Xiaomi Redmi Note 2"
"kenzo" "Xiaomi Redmi Note 3"
"kate" "Xiaomi Redmi Note 3 Special Edition"
"hennessy" "Xiaomi Redmi Note 3 MTK"
"mido" "Xiaomi Redmi Note 4(x)"
"dior" "Xiaomi Redmi Note 4G (Single SIM)"
"ugglite" "Xiaomi Redmi Note 5A or Xiaomi Redmi Y1 Lite"
"ugg" "Xiaomi Redmi Note 5A or Xiaomi Redmi Y1"
"whyred" "Xiaomi Redmi Note 5 Pro"
"tulip" "Xiaomi Redmi Note 6"
"violet" "Xiaomi Redmi Note 7 Pro"
"raphael" "Redmi K20 Pro"
"davinci" "Redmi K20"
"jalebi" "Yu Yunique"
"tomato" "Yu Yureka"
"garlic" "Yu Yureka Black"
"sambar" "Yu Yutopia"
"platy" "ZTE Quartz"
"ailsa_ii" "ZTE Axon 7"
"P892E10" "ZTE Blade Apex 2"
"ham" "Zuk Z1"
"z2_plus" "ZUK Z2 / Lenovo Z2 Plus"
"z2_row" "ZUK Z2 Pro"
"z2x" "ZUK Edge"
);

get_codename() {
local key="";
local value="";
local position=false;
for i in "${codenames[@]}" ; do
  if ! $position; then
  key=$i;
  position=true;
  continue;
  else
  value=$i
  position=false;
  fi
  if [ "${value}" = "${1}" ]; then 
  echo $key;
  return 0;
  fi
done
return 1;
}

get_full_name() {
local key="";
local value="";
local position=false;
local verification_basename="${1##*/}";
for i in "${codenames[@]}" ; do
  if ! $position; then
  key=$i;
  position=true;
  continue;
  else
  value=$i
  position=false;
  fi
  [[ "${1}" != *"/${key}/"* ]] && [[ "$verification_basename" != *"_${key}_"* ]] && [[ "$verification_basename" != *"_${key}-"* ]] && [[ "$verification_basename" != *"-${key}_"* ]] && [[ "$verification_basename" != *"-${key}-"* ]] && [[ "$verification_basename" != *"-${key}."* ]] && [[ "$verification_basename" != *"_${key}."* ]] && continue;
  echo $value;
  return 0;
done
return 0;
}

parse_html() {
grep -o '<a href=['"'"'"][^"'"'"']*['"'"'"]' | \
sed -e 's/^<a href=["'"'"']//' -e 's/["'"'"']$//'
}

parse_simple_html_tag() {
sed -n "s:.*<$1>\(.*\)</$1>.*:\1:p"
}

parse_argument_html_tag() {
sed -n "s:.*<$1 $2=\"$3\">\(.*\)</$1>.*:\1:p"
}

first_html_arg_for_value() {
echo "$1" | parse_argument_html_tag "$2" "$3" "$4" | while read -r device_line; do
echo "$device_line"
break;
done
}

process_webpage() {
local website="$1";
local host="`scissors ${website} / 2`";
curl -k -L -s -b cookiefile -c cookiefile -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H 'authority: $host' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
}

process_webpage_headers() {
local website="$1";
local host="`scissors ${website} / 2`";
curl -k -L -I -s -b cookiefile -c cookiefile -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H 'authority: $host' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
}

get_download_link_size() {
local bytes_size="`process_webpage_headers "$1" | grep -i Content-Length | awk '{print $2}'`";
echo "`./human_size "$bytes_size"`";
}

get_website_host() {
local website="$1";
local host="`scissors ${website} / 2`";
local host_ret="";
case $website in
"https:"*)
host_ret="https://";
;;
"http:"*)
host_ret="http://";
;;
esac;
host_ret+="$host";
echo "$host_ret";
}


send_message_to_tg() {
local text=${1//&/%26amp;}
text=${text//&lt;/%26lt;}
text=${text//&gt;/%26gt;}
text=${text//&quot;/'"'}
local tg_command="https://api.telegram.org/bot${TOKEN}/sendmessage";
local tg_data="text=${text}&chat_id=${2}&parse_mode=HTML&disable_web_page_preview=true";
echo "sending message to Telegram..."
local telegram_result="`curl -k -s "$tg_command" --data "$tg_data"`";
local status=$?;
if [ $status -ne 0 ]; then
		echo "curl reported an error. Exit code was: $status."
		echo "Response was: $telegram_result"
		echo "Quitting."
		exit $status
	fi
	echo "$telegram_result";
		if [[ "$telegram_result" != '{"ok":true'* ]]; then
			echo "Telegram reported an error:"
			echo $telegram_result
			echo "Quitting."
			exit 1
		fi
}

get_executable_path() {
local executable;
executable="`which $1`";
if [ -f "$executable" ]; then
echo "$executable";
return 0;
fi;
if [ "$PATH" ]; then
for i in ${PATH//:/ }; do
if [ -f "$i/$1" ]; then
echo "$i/$1";
return 0;
fi;
done
fi;
if [ "$LD_LIBRARY_PATH" ]; then
for i in ${LD_LIBRARY_PATH//:/ }; do
if [ -f "$i/$1" ]; then
echo "$i/$1";
return 0;
fi;
done
fi;
local exec_lib_paths="
/system/bin
/vendor/bin
/system/xbin
/sbin
/bin
";
for i in $exec_lib_paths; do
if [ -f "$i/$1" ]; then
echo "$i/$1";
return 0;
fi;
done;
return 1;
}

file_size() {
if [ "$1" ] && [ -f "$1" ]; then
local FILESIZE;
local exec="`get_executable_path stat`";
if [ "$exec" ]; then
FILESIZE="`eval $exec -c%s "$1"`";
if [ "$FILESIZE" ]; then
echo "$FILESIZE";
return 0;
else
return 1;
fi
fi
exec="`get_executable_path wc`";
if [ "$exec" ]; then
FILESIZE="`eval $exec -c "$1"`"
FILESIZE=${FILESIZE% *};
if [ "$FILESIZE" ]; then
echo "$FILESIZE";
return 0;
else
return 1;
fi
fi
exec="`get_executable_path ls`";
if [ "$exec" ]; then
FILESIZE="`eval $exec -l "$1"`"
FILESIZE=$(get_str_by_pos "$FILESIZE" 5);
if [ "$FILESIZE" ]; then
echo "$FILESIZE";
return 0;
else
return 1;
fi
fi
fi;
return 1;
}

download_link_basename() {
local ret="${1##*/}";
case $ret in
*"/")
ret="${ret%?}";
;;
esac;
case $ret in
*".zip" | *".md5sum" | *".sha2" | *".sha" | *".sha256") ;;
*) 
ret="${ret##*/}";
;;
esac;
echo "$ret";
}

process_website_file() {
if [ "${GENERATE_CONFIG}" = "new" ]; then
./database -f "$CONFIG" -s "${2}";
return 0;
elif [ "${GENERATE_CONFIG}" = "true" ]; then
./database -f "${CONFIG}.tmp" -s "${2}";
fi
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "${2}"; then
return 0;
fi
./database -f "$CONFIG" -s "${2}";
fi

local message
message="New build of ${1} is out!

<b>Download</b>: <a href=\"${2}\">`download_link_basename $2`</a>"

if [ "$3" ]; then
echo "Arg: $3"
device_verification_basename="`download_link_basename "$3"`";
if [[ "$device_verification_basename" == *".sha" ]] ||
    [[ "$device_verification_basename" == *".sha2" ]] || 
    [[ "$device_verification_basename" == *".sha256" ]] ||
    [[ "$device_verification_basename" == *".md5sum" ]] ||
    [[ "$device_verification_basename" == *".md5" ]]; then
local is_md5
case $device_verification_basename in
*".sha" | ".sha2" | ".sha256") is_md5=false; ;;
*".md5sum" | *".md5") is_md5=true; ;;
esac;

if $is_md5; then
message+="

<b>MD5</b>: <a href=\"${3}\">Click here</a>";
else
message+="

<b>SHA</b>: <a href=\"${3}\">Click here</a>";
fi
elif [[ "$3" == *".txt" ]] ||
       [[ "$3" == *".TXT" ]]; then
message+="

<b>Changelog</b>: <a href=\"${3}\">Click here</a>";
fi
fi

if [ "$4" ]; then
message+="

<b>Changelog</b>: <a href=\"${4}\">Click here</a>";
fi



local name=$(get_full_name "${2}")
if [ "$name" ]; then
local codename=$(get_codename "$name");
message+="
<b>Device</b>: $name
<b>Codename</b>: #${codename}";
fi

message+="
<b>BuildDate</b>: `date +%Y-%m-%d`";

local filesize="`get_download_link_size "$2"`";

if [ "$filesize" ] && [ "$filesize" != "0B" ]; then
message+="
FileSize: $filesize";
fi

if [ "$APPEND" ]; then
message+="

$APPEND";
fi

$INIT_WEBSITE || send_message_to_tg "$message" "$CHAT_ID";
}


CONFIG_DATE="${CONFIG}.date.config";
CURRENT_DATE="`date +%Y-%m-%d`";
if [ -f "${CONFIG_DATE}" ]; then
if [ "`cat ${CONFIG_DATE}`" != "${CURRENT_DATE}" ]; then
GENERATE_CONFIG="true";
echo "${CURRENT_DATE}" > "${CONFIG_DATE}";
else
GENERATE_CONFIG="false";
fi
else
GENERATE_CONFIG="new";
echo "${CURRENT_DATE}" > "${CONFIG_DATE}";
fi

echo "Processing $WEBSITE";


LINKS="`process_webpage "$WEBSITE" | parse_html`";
zip_array=()
md5_array=()
sha_array=()
changelog_array=()
for parsed_link in $LINKS; do
if [[ "$parsed_link" != "https:/"* ]] && [[ "$parsed_link" != "http:/"* ]]; then
case $parsed_link in
*"/"*)
if [[ "$parsed_link" != "$WEBSITE"* ]]; then
parsed_link="`get_website_host "${WEBSITE}"`/${parsed_link}";
fi
;;
*) 
parsed_link="${WEBSITE}/${parsed_link}";
;;
esac;
case $parsed_link in
*"/")
parsed_link="${parsed_link%?}";
;;
esac;

case $parsed_link in
*"//"*)
parsed_link=$(echo "$parsed_link" | tr -s /)
parsed_link=${parsed_link/https:\//https:\/\/};
parsed_link=${parsed_link/http:\//http:\/\/};
;;
esac;
fi
while true; do
if [ "$parsed_link" ] && [ "$parsed_link" != "/" ] && [[ "$parsed_link" == *"/"* ]]; then
if [[ "$parsed_link" != *".zip" ]] && [[ "$parsed_link" != *".md5sum" ]] && [[ "$parsed_link" != *".sha2" ]] && [[ "$parsed_link" != *".sha" ]] && [[ "$parsed_link" != *".sha256" ]] && [[ "$parsed_link" != *".txt" ]] && [[ "$parsed_link" != *".TXT" ]]; then
parsed_link=${parsed_link%/*};
else
break;
fi
else
break;
fi
done


if [ "$DEVICE" ]; then
device_verification_basename="`download_link_basename "$parsed_link"`";
[[ "$parsed_link" != *"/$DEVICE/"* ]] && [[ "$device_verification_basename" != *"_${DEVICE}_"* ]] && [[ "$device_verification_basename" != *"_${DEVICE}-"* ]] && [[ "$device_verification_basename" != *"-${DEVICE}_"* ]] && [[ "$device_verification_basename" != *"-${DEVICE}-"* ]] && [[ "$device_verification_basename" != *"-${DEVICE}."* ]] && [[ "$device_verification_basename" != *"_${DEVICE}."* ]] && continue;
fi
case $parsed_link in
*".zip") zip_array+=("$parsed_link"); ;;
*".txt" | *".TXT") changelog_array+=("$parsed_link"); ;;
*".sha" | *".sha2" | *".sha256") sha_array+=("$parsed_link"); ;;
*".md5sum" | *".md5") md5_array+=("$parsed_link"); ;;
esac;
done;

is_done=false;
for zip_files in "${zip_array[@]}"; do
$is_done && is_done=false;
for md5_files in "${md5_array[@]}"; do
if [[ "`download_link_basename $md5_files`" == *"`download_link_basename $zip_files`"* ]]; then
for changelogs in "${changelog_array[@]}"; do
case $changelogs in
*"-changelog.txt" | *"-Changelog.txt" | *"-CHANGELOG.txt" | *"CHANGELOG.TXT")
changelog_copy="$changelogs";
keyword_len="-changelog.txt";
keyword_len=${#keyword_len}
changelog_copy=${changelog_copy::${#changelog_copy}-keyword_len}
changelog_copy+=".zip";
if [ "$changelog_copy" = "$zip_files" ]; then
process_website_file "$NAME" "$zip_files" "$md5_files" "$changelogs";
is_done=true
break;
fi
;;
esac;
if [ "${changelogs##*/}" = "Changelog.txt" ] || [ "${changelogs##*/}" = "changelog.txt" ] || [ "${changelogs##*/}" = "CHANGELOG.TXT" ]; then
process_website_file "$NAME" "$zip_files" "$md5_files" "$changelogs";
is_done=true
break;
fi
done;
$is_done && continue;
process_website_file "$NAME" "$zip_files" "$md5_files";
is_done=true
break;
fi
done
$is_done && continue;
for sha_files in "${sha_array[@]}"; do
if [[ "`download_link_basename $sha_files`" == *"`download_link_basename $sha_files`"* ]]; then
for changelogs in "${changelog_array[@]}"; do
case $changelogs in
*"-changelog.txt" | *"-Changelog.txt" | *"-CHANGELOG.txt" | *"CHANGELOG.TXT")
changelog_copy="$changelogs";
keyword_len="-changelog.txt";
keyword_len=${#keyword_len}
changelog_copy=${changelog_copy::${#changelog_copy}-keyword_len}
changelog_copy+=".zip";
if [ "$changelog_copy" = "$zip_files" ]; then
process_website_file "$NAME" "$zip_files" "$sha_files" "$changelogs";
is_done=true
break;
fi
;;
esac;
if [ "${changelogs##*/}" = "Changelog.txt" ] || [ "${changelogs##*/}" = "changelog.txt" ] || [ "${changelogs##*/}" = "CHANGELOG.TXT" ]; then
process_website_file "$NAME" "$zip_files" "$sha_files" "$changelogs";
is_done=true
break;
fi
done;
process_website_file "$NAME" "$zip_files" "$sha_files";
is_done=true
break;
fi
done
$is_done && continue;

for changelogs in "${changelog_array[@]}"; do
case $changelogs in
*"-changelog.txt" | *"-Changelog.txt" | *"-CHANGELOG.txt" | *"CHANGELOG.TXT")
changelog_copy="$changelogs";
keyword_len="-changelog.txt";
keyword_len=${#keyword_len}
changelog_copy=${changelog_copy::${#changelog_copy}-keyword_len}
changelog_copy+=".zip";
if [ "$changelog_copy" = "$zip_files" ]; then
process_website_file "$NAME" "$zip_files" "$changelogs";
is_done=true
break;
fi
;;
esac;
if [ "${changelogs##*/}" = "Changelog.txt" ] || [ "${changelogs##*/}" = "changelog.txt" ] || [ "${changelogs##*/}" = "CHANGELOG.TXT" ]; then
process_website_file "$NAME" "$zip_files" "$changelogs";
is_done=true
break;
fi
done;
$is_done && continue;
process_website_file "$NAME" "$zip_files"
done

if [ "$GENERATE_CONFIG" = "true" ]; then
rm -rf "$CONFIG"
rm -rf "${CONFIG}.projects.config"
fi

exit 0;
