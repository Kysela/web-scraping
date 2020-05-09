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
	echo -e "from a AndroidFileHost server based on a defined string"
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
	CONFIG="afh_${STRING}_${CHAT_ID}.config";
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

parse_var_simple_html_tag() {
sed -n "s:.*<.* .*=\"\(.*\)\">.*</.*>.*:\1:p"
}

parse_double_var_simple_html_tag() {
sed -n "s:.*<.* .*=\"\(.*\)\" .*=\".*\">.*</.*>.*:\1:p"
}

parse_argument_html_tag() {
sed -n "s:.*<.* .*=\".*\">\(.*\)</.*>.*:\1:p"
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
case $ret in
*"/"*)
ret="${ret##*/}";
;;
esac;
echo "$ret";
}

check_device_link() {
local device_link_basename="`download_link_basename "$1"`";
if [[ "$1" != *"/$2/"* ]] && [[ "$device_link_basename" != "${2}_"* ]] && [[ "$device_link_basename" != "${2}-"* ]] && [[ "$device_link_basename" != *"_${2}_"* ]] && [[ "$device_link_basename" != *"_${2}-"* ]] && [[ "$device_link_basename" != *"-${2}_"* ]] && [[ "$device_link_basename" != *"-${2}-"* ]] && [[ "$device_link_basename" != *"-${2}."* ]] && [[ "$device_link_basename" != *"_${2}."* ]]; then
return 1;
else
return 0;
fi
}

get_result_value() {
while read result dummy; do
echo "$result" | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed -e 's/"ok":true//g' -e 's/"result":"message_id"/"message_id"/g' -e 's/"from":"id"/"id"/g' -e 's/":/": /g' | while read -r line; do
local value_exists="false";
local ret_val="";
local ret_key="";
local ret="";
if [[ "$line" == *"\": "* ]]; then
value_exists=true;
fi;
ret=${line#*'"'};
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
fi
JSON_VALUE="$ret_val";
[ "$JSON_KEY" = "$1" ] && echo "$JSON_VALUE" && return 0;
fi
done
done
return 1;
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
curl -L -s -b "afh.cookiefile.config" -c "afh.cookiefile.config" -e "https://androidfilehost.com/" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "authority: $host" -H 'Connection: keep-alive' -H 'TE: Trailers' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://androidfilehost.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed --url "$website";
}

process_headers() {
local website="$1";
local host="`scissors ${website} / 2`";
curl -I -L -s -b "afh.cookiefile.config" -c "afh.cookiefile.config" -e "https://androidfilehost.com/" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "authority: $host" -H 'Connection: keep-alive' -H 'TE: Trailers' -H 'upgrade-insecure-requests: 1' -H "Host: $host" -H 'sec-fetch-mode: navigate' -H 'sec-fetch-site: same-origin' -H 'sec-fetch-user: ?1' -H "Cache-Control: max-age=0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36" -H "HTTPS: 1" -H "DNT: 1" -H "Referer: https://androidfilehost.com/" -H "Accept-Language: en-US,en;q=0.8,en-GB;q=0.6,es;q=0.4" -H "If-Modified-Since: Thu, 23 Jul 2015 20:31:28 GMT" --compressed --url "$website";
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


forward_tg_message() {
local tg_command="https://api.telegram.org/bot${TOKEN}/forwardMessage";
echo "forwarding message to Telegram..."
local telegram_result="`curl -s -L "$tg_command" --data "from_chat_id=${1}&message_id=${2}&chat_id=${3}"`";
local status=$?;
if [ $status -ne 0 ]; then
		echo "curl reported an error. Exit code was: $status."
		echo "Response was: $telegram_result"
		echo "Quitting."
		return $status
	fi
		if [[ "$telegram_result" != '{"ok":true'* ]]; then
			echo "Telegram reported an error:"
			echo "$telegram_result"
			echo "Quitting."
			return 1;
		fi
		echo "$telegram_result";
		return 0;
}

pin_tg_message() {
local tg_command="https://api.telegram.org/bot${TOKEN}/pinChatMessage";
local telegram_result="`curl -s -L "$tg_command" --data "chat_id=${1}&message_id=${2}&disable_notification=${3}"`";
local status=$?;
if [ $status -ne 0 ]; then
		echo "curl reported an error. Exit code was: $status."
		echo "Response was: $telegram_result"
		echo "Quitting."
		return $status
	fi
		if [[ "$telegram_result" != '{"ok":true'* ]]; then
			echo "Telegram reported an error:"
			echo "$telegram_result"
			echo "Quitting."
			return 1;
		fi
		echo "$telegram_result";
		return 0;
}

send_message_to_tg() {
local text=${1//&/%26amp;}
text=${text//&lt;/%26lt;}
text=${text//&gt;/%26gt;}
text=${text//&quot;/'"'}
local tg_command="https://api.telegram.org/bot${TOKEN}/sendmessage";
local tg_data="text=${text}&chat_id=${2}&parse_mode=Markdown&disable_web_page_preview=true";
echo "sending message to Telegram..."
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


WEBSITE="https://androidfilehost.com"
API="INSERT_YOUR_API_KEY"

generate_post_data()
{
  cat <<EOF
{
                "url": "https://androidfilehost.com",
			    "renderType": "html",
			    "overseerScript":'page.waitForSelector("input#s");',
			    "emulateDevice": "iPhone X",
				"ignoreImages": false,
				"disableJavascript": false,
				"userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36",
				"xssAuditingEnabled": false,
				"webSecurityEnabled": false,
				"resourceWait": 15000,
				"resourceTimeout": 35000,
				"maxWait": 35000,
				"waitInterval": 10000,
				"stopOnError": false,
				"customHeaders": {"authority":"androidfilehost.com", "Host":"androidfilehost.com"}

}
EOF
}

curl -v -k -i \
-H "Content-Type:application/json" -H "Expect:" \
-X POST --data "$(generate_post_data)" "https://PhantomJScloud.com/api/browser/v2/${API}/" > "androidfilehost.html.config"

# Yeah, it's fucked up xD
html_pos=2
while ((html_pos > 0)); do
if ! grep -R "#newestfiles" androidfilehost.html.config; then
sleep 2
curl -v -k -i \
-H "Content-Type:application/json" -H "Expect:" \
-X POST --data "$(generate_post_data)" "https://PhantomJScloud.com/api/browser/v2/${API}/" > "androidfilehost.html.config"
else
break;
fi
(( html_pos-- ))
done


found_files=false
cat "androidfilehost.html.config" | while read -r line; do
if ! ${found_files}; then
case $line in
*"id=\"newestfiles\""*) 
found_files=true ;;
esac
else
case $line in
*"id=\"newestdevs\""*)
break; ;;
esac
case $line in
*"<a href=\"/?fid="*) 
filename="`echo "$line" | parse_simple_html_tag`";
download="`echo "$line" | parse_var_simple_html_tag`";
;;
*"<a href=\"/?w=profile"*)
profile="`echo "$line" | parse_double_var_simple_html_tag`";
profile=${profile//&amp;/&}
developer="`echo "$line" | parse_simple_html_tag`";
message='`';
message+="${filename}";
message+='`';
message+="
[Download Now](https://androidfilehost.com${download}) - [$developer](https://androidfilehost.com${profile})";
echo -e "$message";
if [ "${GENERATE_CONFIG}" = "new" ]; then
./database -f "$CONFIG" -s "${download}";
continue;
elif [ "${GENERATE_CONFIG}" = "true" ]; then
./database -f "${CONFIG}.tmp" -s "${download}";
fi
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "${download}"; then
continue;
fi
./database -f "$CONFIG" -s "${download}";
fi
local message_id="";
if check_device_link "$filename" "mido"; then
message_id="`send_message_to_tg "$message" "$CHAT_ID" | get_result_value message_id`";
group_message_id="`forward_tg_message "$CHAT_ID" "$message_id" "@rn4official" | get_result_value message_id`";
pin_tg_message "@rn4official" "$group_message_id" "true"
elif check_device_link "$filename" "whyred"; then
message_id="`send_message_to_tg "$message" "$CHAT_ID" | get_result_value message_id`";
forward_tg_message "$CHAT_ID" "$message_id" "@whyredofficial";
else
send_message_to_tg "$message" "$CHAT_ID";
fi
;;
esac
fi
done


if [ "$GENERATE_CONFIG" = "true" ]; then
rm -rf "${CONFIG}"
mv "${CONFIG}.tmp" "${CONFIG}"
fi

exit 0;
