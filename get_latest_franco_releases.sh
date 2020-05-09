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
	echo -e "\nThis script can be used to get latest Franco kernel releases" 
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
	CONFIG="franco.config";
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

if ! website_exists https://franco-lnx.net; then
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
echo "$text"
local telegram_result="`curl -s "$tg_command" --data "$tg_data"`";
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
"Btw. new ${1} build was just posted on ${2}."
"Damn, some ${1} build just arrived on ${2}."
)
local messages_size=${#local_MESSAGES[@]}
printf '%s\n' "${local_MESSAGES[RANDOM % messages_size]}"
return 0;
}

process_webpage_headers() {
local website="$1";
local host="`scissors ${website} / 2`";
curl -s -I -L -H "Host: $host" -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.89 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://www.google.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed "$website";
}

get_download_link_size() {
local bytes_size="`process_webpage_headers "$1" | grep -i Content-Length | awk '{print $2}'`";
echo "`./human_size "$bytes_size"`";
}

parse_changelog() {
echo "$1" | while read -r line; do
echo "<code>$line</code>";
done
}

CONFIG_SIZE="`file_size $CONFIG`";
if (( $? == 0 && CONFIG_SIZE > 100000 )); then
GENERATE_CONFIG="true";
else
GENERATE_CONFIG="false";
fi

last_device="";
echo "Processing devices...";
VERSIONS_LIST="`process_webpage https://franco-lnx.net/versions | parse_html`";
for link in $VERSIONS_LIST; do
[[ "$link" != "/versions"* ]] && continue;
[[ "$link" == *"/" ]] && link="${link%?}";
link=${link##*/}
full_link="https://franco-lnx.net/versions/$link";
DOWNLOAD_LIST="`process_webpage $full_link | parse_html`";
full_download_link="";
full_md5_link="";
first_link=false;
for download_links in $DOWNLOAD_LIST; do
[[ "$download_links" != *".zip" ]] && [[ "$download_links" != *".md5" ]] && continue;
[ "$first_link" = "false" ] && full_download_link="$download_links" && first_link=true && continue;
[ "$download_links" = "${full_download_link}.md5" ] && full_md5_link="${full_download_link}.md5" && break;
done;

if [ -z "$full_download_link" ]; then
echo "Unable to find download link...";
continue;
fi

formatted_device_name="`scissors $full_download_link / 3`";

if [ "$last_device" != "$formatted_device_name" ]; then
echo "$formatted_device_name";
fi
last_device="$formatted_device_name";

[ "$GENERATE_CONFIG" = "true" ] && ./database -f "${CONFIG}.tmp" -s "$full_download_link"

if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "$full_download_link"; then
continue;
fi
fi

formatted_version_name="`scissors $full_download_link / 4`";


changelog="${full_download_link%/*}"
changelog="${changelog%/*}/appfiles/changelog"
changelog_file="`process_webpage $changelog | sed -e '/^$/,$d'`";
if [ ! "$changelog_file" ]; then
echo "Unable to get changelog, may be it is not published?";
else
echo "Found changelog!";
fi


download_link_basename="${full_download_link##*/}";
WHOLE_MESSAGE="New Franco Kernel release is out!";

if [ "$formatted_device_name" ]; then
WHOLE_MESSAGE+="
<b>Device</b>: ${formatted_device_name}";
fi

if [ "$formatted_version_name" ]; then
WHOLE_MESSAGE+="
<b>Version</b>: ${formatted_version_name}";
fi

if [ "$changelog_file" ]; then
first_changelog_line="`echo "$changelog_file" | sed -n '1p'`";
RELEASE_NUMBER="`echo "$first_changelog_line" | awk '{print $1}'`";
WHOLE_MESSAGE+="
<b>Release</b>: ${RELEASE_NUMBER}";
WHOLE_MESSAGE+="
<b>BuildDate</b>: `echo "$first_changelog_line" | sed -n -e 's/^.*- //p'`";
fi

WHOLE_MESSAGE+="
<b>FileSize</b>: `get_download_link_size "$full_download_link"`";

if [ "$full_md5_link" ]; then
WHOLE_MESSAGE+="
<b>MD5</b>: <code>`process_webpage ${full_md5_link} | awk '{print $1}'`</code>";
fi

WHOLE_MESSAGE+="
<b>Download</b>: <a href=\"${full_download_link}\">${download_link_basename}</a>"

if [ "$changelog_file" ]; then
changelog_file="`echo "$changelog_file" | tail -n +2`";
changelog_file="`parse_changelog "$changelog_file"`";
WHOLE_MESSAGE+="
<b>Changelog</b>:
${changelog_file}";
fi

if [ "$formatted_device_name" = "RedmiNote4" ]; then
MESSAGE_COPY="${WHOLE_MESSAGE}

<b>Franco Kernel Channel:</b> $CHAT_ID

#Kernel #FrancoKernel #Franco

@rn4downloads | @rn4official | @xiaomiot | @customization | @rn4photography";
send_message_to_tg "$MESSAGE_COPY" "@rn4downloads";
elif [ "$formatted_device_name" = "RedmiNote5" ]; then
local MESSAGE_COPY="${WHOLE_MESSAGE}
<b>Franco Kernel Channel:</b> $CHAT_ID

#Kernel #FrancoKernel #Franco

@whyredofficial | @whyredphotos | @xiaomiot | @customization";
send_message_to_tg "$MESSAGE_COPY" "@whyreddownloads";
send_message_to_tg "`get_new_build_post_message "Franco Kernel" "@whyreddownloads"`" "@whyredofficial";
elif [ "$formatted_device_name" = "MiA3" ]; then
local MESSAGE_COPY="${WHOLE_MESSAGE}
<b>Franco Kernel Channel:</b> $CHAT_ID

#Kernel #FrancoKernel #Franco

@laurelofficial";
send_message_to_tg "$MESSAGE_COPY" "@laurelofficial";
fi

send_message_to_tg "$WHOLE_MESSAGE" "$CHAT_ID"

./database -f "$CONFIG" -s "$full_download_link";
done;

if [ "$GENERATE_CONFIG" = "true" ] && [ -f "${CONFIG}.tmp" ]; then
rm -rf "$CONFIG"
mv "${CONFIG}.tmp" "$CONFIG";
fi

exit 0;