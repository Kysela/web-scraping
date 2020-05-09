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
	echo -e "\nThis script can be used to get latest TWRP releases" 
	echo -e "\nand send them formatted to Telegram channels or groups" 
	echo -e "\nSource: (https://github.com/Kysela/web-scraping)" 
	echo -e "\by @ATGDroid" 
	echo -e "\nUsage:\n $0 [options..]\n"
	echo -e "Options:\n"
	echo -e "-c | --config <config file> - Custom path for script configuration file"
	echo -e "-i | --id <chat id> - id of the chat to send message to"
	echo -e "-t | --token <api token> - Telegram bot api token\n"
	echo -e "-n | --notification - Disable notification\n"
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
		c | config)
		    parse_args_ensure_argument
			CONFIG="$parse_args_value";
			;;
	    i | id)
		    parse_args_ensure_argument;
			CHAT_ID="$parse_args_value";
			;;
		t | token)
		    parse_args_ensure_argument;
			TOKEN="$parse_args_value";
			;;
		n | notification)
			DISABLE_NOTIFICATION=true
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

if [ -z "$CONFIG" ]; then
	CONFIG="./twrp.config";
fi

print() {
echo -e "$@" >&2;
}

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
print "Processing website $1";
local website="$1";
local host="`scissors ${website} / 2`";
curl -m 15 -k -L -s -b cookiefile -c cookiefile -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H 'authority: $host' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
print "done"
}

process_webpage_headers() {
local website="$1";
local host="`scissors ${website} / 2`";
curl -m 15 -k -L -I -s -b cookiefile -c cookiefile -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H 'authority: $host' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
}

get_download_link_size() {
local bytes_size="`process_webpage_headers "$1" | grep -i Content-Length | awk '{print $2}'`";
echo "`./human_size "$bytes_size"`";
}

echo "Searching for website";
if ! website_exists https://twrp.me; then
echo "Unable to locate download server, may be it is down?";
exit 1;
fi

get_link_basename() {
local ret="${1##*/}";
local ret="${ret%.*}";
echo "$ret";
}
 
 
send_message_to_tg() {
local text=${1//&/%26amp;}
text=${text//&lt;/<}
text=${text//&gt;/>}
text=${text//&quot;/'"'}
local tg_command="https://api.telegram.org/bot${TOKEN}/sendmessage";
local tg_data="text=${text}&chat_id=${2}&parse_mode=HTML";
echo "sending message to Telegram..."
echo "$text"
local telegram_result="`curl -s -L "$tg_command" --data "$tg_data"`";
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


if [ -f "${CONFIG}" ]; then
GENERATE_CONFIG="false";
else
GENERATE_CONFIG="new";
fi
echo "Getting device list";
VERSIONS_LIST="`process_webpage https://twrp.me/Devices | parse_html`";
for link in $VERSIONS_LIST; do
([[ "$link" != "/Devices/"* ]] || [ "$link" = "/Devices/" ]) && continue;
[[ "$link" == *"/" ]] && link="${link%?}";
link=${link##*/}
formatted_device_brand="$link";
echo "Processing $formatted_device_brand";
process_webpage "https://twrp.me/Devices/${link}" | while read -r line; do
if [[ "$line" == *"<strong><a href=\""* ]]; then
device_links="`echo "$line" | parse_html`";
formatted_name="`echo "$line" | awk -F'\">|</a>' '{print $2}'`";
echo "- $formatted_name";
xda_thread_link="";
device_tree_link="";
classic_download_link="";
eu_download_link="";
device_code_name="";
DOWNLOAD_LIST="`process_webpage "https://twrp.me${device_links}" | parse_html`";
for download_links in $DOWNLOAD_LIST; do
case $download_links in
*"forum.xda-developers.com"*) xda_thread_link="$download_links";;
*"github.com/TeamWin/"*) device_tree_link="$download_links";;
*"eu.dl.twrp.me/"*) eu_download_link="${download_links}";;
*"dl.twrp.me/"*) classic_download_link="${download_links}";;
esac;
done;
if [ "$classic_download_link" ]; then
device_code_name="${classic_download_link##*/}"
elif [ "$eu_download_link" ]; then
device_code_name="${eu_download_link##*/}"
continue;
fi
classic_image_file_link="";
classic_zip_installer_file_link="";
eu_image_file_link="";
eu_zip_installer_file_link="";
if [ "$classic_download_link" ]; then
DOWNLOAD_LIST="`process_webpage "${classic_download_link}" | parse_html`"
for classic_download_list in $DOWNLOAD_LIST; do
[[ "$classic_download_list" != "/${device_code_name}/"* ]] && continue;
[ -z "$classic_zip_installer_file_link" ] && [[ "$classic_download_list" == *".zip.html" ]] && [[ "$classic_download_list" == *"twrp-installer"* ]] && classic_zip_installer_file_link="https://dl.twrp.me${classic_download_list}" && continue;
[ -z "$classic_image_file_link" ] && [[ "$classic_download_list" == *".img.html" ]] && [[ "$classic_download_list" == *"twrp-"* ]] && classic_image_file_link="https://dl.twrp.me${classic_download_list}" && continue;
done;
fi
if [ "$eu_download_link" ]; then
DOWNLOAD_LIST="`process_webpage "${eu_download_link}" | parse_html`"
for classic_download_list in $DOWNLOAD_LIST; do
[[ "$classic_download_list" != "/${device_code_name}/"* ]] && continue;
[ -z "$eu_zip_installer_file_link" ] && [[ "$classic_download_list" == *".zip.html" ]] && [[ "$classic_download_list" == *"installer"* ]] && eu_zip_installer_file_link="https://eu.dl.twrp.me${classic_download_list}" && continue;
[ -z "$eu_image_file_link" ] && [[ "$classic_download_list" == *".img.html" ]] && [[ "$classic_download_list" == *"twrp-"* ]] && eu_image_file_link="https://eu.dl.twrp.me${classic_download_list}" && break;
done;
fi

if [ "$classic_image_file_link" ]; then
download_serialized="`get_link_basename $classic_image_file_link`";
elif [ "$eu_image_file_link" ]; then
download_serialized="`get_link_basename $eu_image_file_link`";
else
continue;
fi

#./database -f "${CONFIG}.devices.config" -s "$formatted_name";
#./database -f "${CONFIG}.codenames.config" -s "$device_code_name";

echo "- $download_serialized";

if [ "$GENERATE_CONFIG" = "new" ]; then
./database -f "$CONFIG" -s "$download_serialized";
continue;
fi
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "$download_serialized"; then
continue;
fi
fi
./database -f "$CONFIG" -s "$download_serialized";

WHOLE_MESSAGE="<b>New TWRP build is out for $formatted_name</b>
";

if [ "$xda_thread_link" ] || [ "$device_tree_link" ]; then
WHOLE_MESSAGE+="
<b>Device links</b>:";

if [ "$device_tree_link" ]; then
WHOLE_MESSAGE+="
  - <a href=\"${device_tree_link}\">Device tree</a>";
fi

if [ "$xda_thread_link" ]; then
WHOLE_MESSAGE+="
  - <a href=\"${xda_thread_link}\">XDA Thread</a>";
fi

WHOLE_MESSAGE+="
";
fi

WHOLE_MESSAGE+="
<b>Recovery image</b>:";

if [ "$classic_image_file_link" ]; then
WHOLE_MESSAGE+="
  - <a href=\"${classic_image_file_link}\">US Server</a>";
fi

if [ "$eu_image_file_link" ]; then
echo "EU LINK: ${eu_image_file_link}";
WHOLE_MESSAGE+="
  - <a href=\"${eu_image_file_link}\">EU Server</a>";
fi

if [ "${classic_zip_installer_file_link}" ] || [ "${eu_zip_installer_file_link}" ]; then
WHOLE_MESSAGE+="

<b>ZIP installer</b>:";

if [ "$classic_zip_installer_file_link" ]; then
WHOLE_MESSAGE+="
  - <a href=\"${classic_zip_installer_file_link}\">US Server</a>";
fi

if [ "$eu_zip_installer_file_link" ]; then
WHOLE_MESSAGE="$WHOLE_MESSAGE
  - <a href=\"${eu_zip_installer_file_link}\">EU Server</a>";
fi
fi

if [ "$device_code_name" = "mido" ] && [ "$formatted_device_brand" = "Xiaomi" ]; then
MESSAGE_COPY="${WHOLE_MESSAGE}

<b>Channel</b>:
TWRP channel: $CHAT_ID

#twrp #recovery #customrecovery

@rn4downloads | @rn4official | @xiaomiot | @customization | @rn4photography";
send_message_to_tg "$MESSAGE_COPY" "@rn4downloads";
elif [ "$device_code_name" = "whyred" ] && [ "$formatted_device_brand" = "Xiaomi" ]; then
MESSAGE_COPY="${WHOLE_MESSAGE}

<b>Channel</b>:
TWRP channel: $CHAT_ID

#twrp #recovery #customrecovery

@whyredofficial | @whyredphotos | @xiaomiot | @customization";
send_message_to_tg "$MESSAGE_COPY" "@whyreddownloads";
send_message_to_tg "What's up? New TWRP build for whyred is now available on @whyreddownloads" "@whyredofficial";
elif [ "$device_code_name" = "laurel" ] && [ "$formatted_device_brand" = "Xiaomi" ]; then
MESSAGE_COPY="${WHOLE_MESSAGE}

<b>Channel</b>:
TWRP channel: $CHAT_ID

#twrp #recovery #customrecovery

@laurelofficial";
send_message_to_tg "$MESSAGE_COPY" "@laurelofficial";
fi

WHOLE_MESSAGE="${WHOLE_MESSAGE}

$CHAT_ID";

send_message_to_tg "$WHOLE_MESSAGE" "$CHAT_ID"

fi
done
done;

exit 0;