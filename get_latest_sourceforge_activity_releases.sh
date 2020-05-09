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
	echo -e "This script can be used to get latest updates" 
	echo -e "from a SourceForge server based on a defined string"
	echo -e "and send them formatted to a Telegram channels or groups"
	echo -e "Source: (https://github.com/Kysela/web-scraping)" 
	echo -e "by @ATGDroid" 
	echo -e "Usage:\n $0 [options..]"
	echo -e "Options:"
	echo -e "-a | --append <message> - message to append to a post"
	echo -e "-c | --config <config file> - Custom path for script configuration file"
	echo -e "-n | --name <formatted name> - Formatted name for telegram posts"
	echo -e "-s | --string <string value> - string match to search for"
	echo -e "-t | --token <api token> - Telegram bot api token"
	echo -e "-h | --help - Display usage instructions."
	exit 0;
}

print() {
echo -e "$@" >&2;
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
	    i | id)
		    parse_args_ensure_argument;
			CHAT_ID="$parse_args_value";
			;;
		t | token)
		    parse_args_ensure_argument;
			TOKEN="$parse_args_value";
			;;
		n | name)
		    parse_args_ensure_argument;
			NAME="$parse_args_value";
			;;
		s | string)
		    parse_args_ensure_argument;
			STRING="$parse_args_value";
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
	CONFIG="release_feed_${STRING}_${CHAT_ID}.config";
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

parse_simple_html_tag() {
sed -n "s:.*<.*>\(.*\)</.*>.*:\1:p"
}

parse_argument_html_tag() {
sed -n "s:.*<.* .*=\".*\" .*=\".*\">\(.*\)</.*>.*:\1:p"
}

first_html_arg_for_value() {
echo "$1" | parse_argument_html_tag "$2" "$3" "$4" | while read -r device_line; do
echo "$device_line"
break;
done
}

parse_double_argument_html_tag() {
sed -n "s:.*<.* .*=\".*\" .*=\".*\">\(.*\)</.*>.*:\1:p"
}

parse_triple_argument_html_tag() {
sed -n "s:.*<.* .*=\".*\" .*=\".*\"><.* .*=\(.*\)>.*</.*></.*>.*:\1:p"
}

download_link_basename() {
local ret="$1";
case $ret in
*"/download")
ret="${ret%/*}";
;;
esac;
case $ret in
*"/")
ret="${ret%?}";
;;
esac;
ret="${ret##*/}";
echo "$ret";
}

parse_json_pure_bash() {
[ -z "$1" ] && return 1;
local value_exists="false";
local ret_val="";
local ret_key="";
local ret="$1";
if [[ "$ret" == *"\": "* ]]; then
value_exists=true;
fi;
ret=${ret#*'"'};
if [[ "$ret" == *"," ]]; then
ret=${ret%?}
fi
ret_key=${ret%%:*}
if [[ "$ret_key" == *'"' ]]; then
ret_key=${ret_key%?}
fi
if [[ "$ret_key" == '"'* ]]; then
ret_key=${ret_key#?}
fi
JSON_KEY="$ret_key";
if $value_exists; then
ret_val=${ret#* }
if [[ "$ret_val" == *'"' ]]; then
ret_val=${ret_val%?}
fi
if [[ "$ret_val" == '"'* ]]; then
ret_val=${ret_val#?}
elif [[ "$ret_val" == "\"}"* ]]; then
ret_val=${ret_val#??}
return 0;
fi
JSON_VALUE="$ret_val";
else
JSON_VALUE="";
fi
return 0;
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
local telegram_result="`curl -s -k "$tg_command" --data "$tg_data"`";
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


process_website_file() {
local formatted_name download_link
if [ "$2" ]; then
download_link="$2";
formatted_name="$1";
else
formatted_name="";
download_link="$1";
fi

if [ "${GENERATE_CONFIG}" = "new" ]; then
./database -f "$CONFIG" -s "${download_link}";
return 0;
elif [ "${GENERATE_CONFIG}" = "true" ]; then
./database -f "${CONFIG}.tmp" -s "${download_link}";
fi
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "${download_link}"; then
return 0;
fi
./database -f "$CONFIG" -s "${download_link}";
fi

local message
if [ "${formatted_name}" ]; then
message="${formatted_name}

<code>`download_link_basename $download_link`</code>
<a href=\"${download_link}\">Download Now</a>"
else
message="<code>`download_link_basename $download_link`</code>
<a href=\"${download_link}\">Download Now</a>"
fi

if [ "$APPEND" ]; then
message+="

$APPEND";
fi

send_message_to_tg "$message" "$CHAT_ID";
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

WEBSITE="https://sourceforge.net/directory/release_feed";
if [ "$STRING" ]; then
process_webpage "$WEBSITE" | grep "<link>" | grep "$STRING" | parse_simple_html_tag | while read -r parsed_link; do
[ "${parsed_link}" = "${WEBSITE}" ] && continue;
device_verification_basename="`download_link_basename "$parsed_link"`";
[[ "$parsed_link" != *"/$STRING/"* ]] && [[ "$device_verification_basename" != "${STRING}_"* ]] && [[ "$device_verification_basename" != "${STRING}-"* ]] && [[ "$device_verification_basename" != *"_${STRING}_"* ]] && [[ "$device_verification_basename" != *"_${STRING}-"* ]] && [[ "$device_verification_basename" != *"-${STRING}_"* ]] && [[ "$device_verification_basename" != *"-${STRING}-"* ]] && [[ "$device_verification_basename" != *"-${STRING}."* ]] && [[ "$device_verification_basename" != *"_${STRING}."* ]] && continue;
if [ "$NAME" ]; then
process_website_file "$NAME" "$parsed_link"
else
process_website_file "$parsed_link"
fi
done
else
process_webpage "$WEBSITE" | grep "<link>" | parse_simple_html_tag | while read -r parsed_link; do
[ "${parsed_link}" = "${WEBSITE}" ] && continue;
if [ "$NAME" ]; then
process_website_file "$NAME" "$parsed_link"
else
process_website_file "$parsed_link"
fi
done
fi

if [ "$GENERATE_CONFIG" = "true" ]; then
rm -rf "${CONFIG}"
mv "${CONFIG}.tmp" "${CONFIG}"
fi

exit 0;
