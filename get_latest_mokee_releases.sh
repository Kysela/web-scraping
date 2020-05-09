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
	echo -e "\nThis script can be used to get latest mokee ROM releases" 
	echo -e "\nand send them formatted to Telegram channels or groups" 
	echo -e "\nSource: (https://github.com/Kysela/web-scraping" 
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
	CONFIG="mokee.config";
fi

BUILDS_PROCESSED="false";

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
if curl --output /dev/null --silent --head --fail -H "Host: $host" -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website"; then
  return 0;
else
  return 1;
fi
}
 
if ! check_connectivity; then
echo "Device does not have internet connection, can not continue!";
exit 1;
fi

if ! website_exists https://download.mokeedev.com; then
echo "Unable to locate download server, may be it is down?";
exit 1;
fi

parse_html() {
sed -n 's/.*href="\([^"]*\).*/\1/p'
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
curl -s -L -H "Host: $host" -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
}

send_message_to_tg() {
local text=${1//&/%26amp;}
text=${text//&lt;/<}
text=${text//&gt;/>}
text=${text//&quot;/'"'}
local tg_command="https://api.telegram.org/bot${TOKEN}/sendmessage";
local tg_data="text=${text}&chat_id=${2}&parse_mode=HTML";
echo "sending message to Telegram..."
local telegram_result="`curl -k -L -s "$tg_command" --data "$tg_data"`";
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


get_new_build_post_message() {
if [ -z "$1" ] || [ -z "$2" ]; then 
return 1;
fi
local_MESSAGES=(
"Yay, new ${1} build is now available on ${2}"
"Hey yo, new ${1} build just arrived on ${2}"
"Ay, new ${1} build is now available on ${2}"
"Seems like that new ${1} build is now available on ${2}"
"What's up? New ${1} build is now available on ${2}"
"Weeew, new ${1} build is now up on ${2}"
"Btw. new ${1} build just arrived on ${2}"
"Ey, new ${1} build was just posted on ${2}"
"What's up everyone! How you doin? Btw. new ${1} build was just posted on ${2}."
"Damn, some ${1} build just arrived on ${2}."
"If i'm not wrong then new ${1} build just arrived on ${2}."
"Another ${1} build was just posted on ${2}."
)
local messages_size=${#local_MESSAGES[@]}
printf '%s\n' "${local_MESSAGES[RANDOM % messages_size]}"
return 0;
}

process_package() {
local file_path_basename=${package_array[0]};
[[ "$file_path_basename" == *"/" ]] && file_path_basename="${file_path%?}";
file_path_basename="${file_path_basename%/*}";
file_path_basename="${file_path_basename##*/}";
echo "Processing $file_path_basename";
[ "$GENERATE_CONFIG" = "true" ] && ./database -f "${CONFIG}.tmp" -s "$file_path_basename"
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "$file_path_basename"; then
package_array=();
return 0;
fi
fi
./database -f "$CONFIG" -s "$file_path_basename";
local file_path=${package_array[0]};
local md5sum=${package_array[1]};
local package_type=${package_array[2]};
local package_version=${package_array[3]};
local package_size=${package_array[4]};
local package_date=${package_array[5]};
local package_codename="`scissors $file_path / 3`"
local download_webpage="`process_webpage ${file_path}`";
local TG_LINKS="`echo "$download_webpage" | parse_html | grep t.me/`";
local package_device="`first_html_arg_for_value "$download_webpage" "li" "class" "breadcrumb-item active"`";
local telegram_id="";
if [ "$TG_LINKS" ]; then
for telegram in $TG_LINKS; do
[[ "$telegram" == *"t.me/mokeecommunity" ]] && continue;
telegram_id="${telegram##*/}";
break;
done
fi

WHOLE_MESSAGE="New MokeeOS build is out!";

if [ "$package_device" ]; then
WHOLE_MESSAGE+="
<b>Device</b>: ${package_device}";
fi

WHOLE_MESSAGE+="
<b>Codename</b>: #${package_codename}";

if [ "$telegram_id" ]; then
WHOLE_MESSAGE+="
<b>Maintainer</b>: @${telegram_id}";
fi

WHOLE_MESSAGE+="
<b>Type</b>: ${package_type}
<b>Android</b>: ${package_version}
<b>FileSize</b>: ${package_size}
<b>BuildDate</b>: ${package_date}
<b>MD5</b>: <code>${md5sum}</code>
<b>Filename</b>: <code>${file_path_basename}</code>
<b>Download</b>: <a href=\"${file_path}\">Click here</a>
";

if [ "$package_codename" = "mido" ]; then
if [ "${package_type}" != "Nightly" ]; then
local MESSAGE_COPY="${WHOLE_MESSAGE}
<b>Channel</b>:
Follow $CHAT_ID to get direct information about new updates
for all supported devices from one single channel.

#rom #customrom #official #mokee #mokeeos

@rn4downloads | @rn4official | @xiaomiot | @customization | @rn4photography";
send_message_to_tg "$MESSAGE_COPY" "@rn4downloads";
else
send_message_to_tg "`get_new_build_post_message "MokeeOS mido ${package_type}" "@MokeeDownloads"`" "@rn4official";
fi
elif [ "$package_codename" = "whyred" ]; then
local MESSAGE_COPY="${WHOLE_MESSAGE}
<b>Channel</b>:
Follow $CHAT_ID to get direct information about new updates
for all supported devices from one single channel.

#rom #customrom #official #mokee #mokeeos

@whyredofficial | @whyredphotos | @xiaomiot | @customization";
send_message_to_tg "$MESSAGE_COPY" "@whyreddownloads";
#send_message_to_tg "`get_new_build_post_message "MokeeOS ${package_type}" "@whyreddownloads"`" "@whyredofficial";
elif [ "$package_codename" = "laurel" ]; then
local MESSAGE_COPY="${WHOLE_MESSAGE}
<b>Channel</b>:
Follow $CHAT_ID to get direct information about new updates
for all supported devices from one single channel.

#rom #customrom #official #mokee #mokeeos

@laurelofficial"
send_message_to_tg "$MESSAGE_COPY" "@laurelofficial";
fi

WHOLE_MESSAGE="${WHOLE_MESSAGE}
${CHAT_ID}";

send_message_to_tg "$WHOLE_MESSAGE" "$CHAT_ID"
if [ "$BUILDS_PROCESSED" = "false" ]; then
BUILDS_PROCESSED="true"
fi
package_array=();
return 0;
}

CONFIG_SIZE="`file_size $CONFIG`";
if (( $? == 0 && CONFIG_SIZE > 130000 )); then
GENERATE_CONFIG="true";
else
GENERATE_CONFIG="false";
fi

found_md5=false;
package_array=();
while read -r line; do
$found_md5 && [ "$line" = "</td>" ] && continue;
$found_md5 && [[ "$line" == "<td>"* ]] && package_array+=("`echo "$line" | parse_simple_html_tag "td"`") && continue;
$found_md5 && [[ "$line" != "<td>"* ]] && found_md5=false && process_package;
[[ "$line" == "<a href=\""* ]] && [[ "$line" == *"/download"* ]] && package_array+=("`echo "$line" | parse_html`") && continue;
[[ "$line" == "<small>md5sum: "* ]] && package_array+=("`echo "$line" | parse_simple_html_tag "small" | awk '{print $2}'`") && found_md5=true && continue;
done <<< $(process_webpage https://download.mokeedev.com)

if [ "$BUILDS_PROCESSED" = "true" ]; then
send_message_to_tg "Builds for `date +%Y-%m-%d` are done!" "$CHAT_ID"
fi

if [ "$GENERATE_CONFIG" = "true" ] && [ -f "${CONFIG}.tmp" ]; then
rm -rf "$CONFIG"
mv "${CONFIG}.tmp" "$CONFIG";
fi

exit 0;
