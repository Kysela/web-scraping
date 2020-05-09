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
	echo -e "\nThis script can be used to get latest github" 
	echo -e "\releases and send them formatted to Telegram channels or groups" 
	echo -e "\nSource: (https://github.com/Kysela/web-scraping)" 
	echo -e "\by @ATGDroid" 
	echo -e "\nUsage:\n $0 [options..]\n"
	echo -e "Options:\n"
	echo -e "-a | --append <message> - message to append to a post"
	echo -e "-c | --config <config file> - Custom path for script configuration file"
	echo -e "-i | --id <chat id> - id of the chat to send message to"
	echo -e "-r | --repo <repository name> - Github repository name"
	echo -e "-u | --user <user name> - Name of the github user"
	echo -e "-t | --token <api token> - Telegram bot api token\n"
	echo -e "--title <release title> - Default title for tg post\n"
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
	    i | id)
		    parse_args_ensure_argument;
			CHAT_ID="$parse_args_value";
			;;
		t | token)
		    parse_args_ensure_argument;
			TOKEN="$parse_args_value";
			;;
		r | repo)
		    parse_args_ensure_argument;
			REPOSITORY="$parse_args_value";
			;;
		 title)
		    parse_args_ensure_argument;
			TITLE="$parse_args_value";
			;;
		u | user)
		    parse_args_ensure_argument;
			USER="$parse_args_value";
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

if [ -z "$REPOSITORY" ]; then
	echo "Please set Github repository name to search for!"
	exit 1
fi

if [ -z "$USER" ]; then
	echo "Please set github user name to search for"
	exit 1
fi

if [ -z "$CONFIG" ]; then
	CONFIG="${USER}_${REPOSITORY}_${CHAT_ID}.config";
fi

send_message_to_tg() {
local text=${1//&/%26amp;}
text=${text//&lt;/%26lt;}
text=${text//&gt;/%26gt;}
text=${text//&quot;/'"'}
local tg_command="https://api.telegram.org/bot${TOKEN}/sendMessage";
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

process_latest_github_release() {
API_RESULT=$(curl -s -L -k -H "Authorization: Token fe07f5ba97ebf2f52c7df9fdc8faa367a1c83078" "https://api.github.com/repos/${1}/${2}/releases/latest")
get_api_var() { 
local api_line;
local api_iter
echo "${API_RESULT}" | while read -r api_line; do
parse_json_pure_bash "$api_line";
for api_iter in $@; do
[ "${JSON_KEY}" = "$api_iter" ] && echo "${JSON_VALUE}" && return 0;
done
done
}
get_api_var_all() { 
local api_line;
local api_iter
echo "${API_RESULT}" | while read -r api_line; do
parse_json_pure_bash "$api_line";
for api_iter in $@; do
[ "${JSON_KEY}" = "$api_iter" ] && echo "${JSON_VALUE}"
done
done
}
get_api_changelog() {
local api_line;
local api_iter
local found_body=false
echo "${API_RESULT}" | while read -r api_line; do
parse_json_pure_bash "$api_line";
if [ "${found_body}" = "false" ] && [ "${JSON_KEY}" = "body" ]; then
found_body=true
echo -e "${JSON_VALUE}"
elif [ "${api_line}" != '"' ] && [ "${api_line}" != '}' ] && $found_body; then
[[ "${api_line}" == *'"' ]] && api_line=${api_line%?}
echo -e "${api_line}"
fi
done
}
local id="`get_api_var id`";
[ -z "$id" ] && exit 1;
if [ "${GENERATE_CONFIG}" = "new" ]; then
./database -f "$CONFIG" -s "github_${id}";
return 0;
elif [ "${GENERATE_CONFIG}" = "true" ]; then
./database -f "${CONFIG}.tmp" -s "github_${id}";
fi
if [ -f "$CONFIG" ]; then
if ./database -f "$CONFIG" -c "github_${id}"; then
return 0;
fi
./database -f "$CONFIG" -s "github_${id}";
fi
local name="`get_api_var name`";
local login="`get_api_var login`";
local body="`get_api_var body`";
local created_at="`get_api_var created_at`";
local html_url="`get_api_var html_url`";
local target_commitish="`get_api_var target_commitish`";
[ -z "$name" ] && name="${html_url##*/}";
created_at=${created_at//T/ }
created_at=${created_at//Z/ }
local message
if [ "$3" ]; then
message="<b>New $3 by $login is out!</b>";
else
message="<b>New $name by $login is out!</b>";
fi


message+="

Author: <a href=\"https://github.com/$1\">${1}</a>"
if [ "$3" ]; then
message+="
Title: <code>${name}</code>"
fi
message+="
Repository: <a href=\"https://github.com/$1/$2\">${2}</a>
Release tag: <a href=\"${html_url}\">${html_url##*/}</a>
Branch: <a href=\"https://github.com/$1/$2/tree/${target_commitish}\">${target_commitish}</a>
";

message+="<b>Release date</b>: $created_at";

if [ "$body" ]; then
message+="

`get_api_changelog`";
fi


if [ "`get_api_var browser_download_url`" ]; then
message+="

<b>Assets Included:</b>";

local counter=1;
local key="";
local value="";
local position=false;
for releases in `echo "${API_RESULT}" | get_api_var_all size browser_download_url`; do
  if ! $position; then
  key=$releases;
  position=true;
  continue;
  else
  value=$releases
  position=false;
  fi
message+="
<b>${counter})</b>
<i>Size: `./human_size $key`</i>
<a href=\"${value}\">${value##*/}</a>"
(( counter++ ))
done
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

if [ "$TITLE" ]; then
process_latest_github_release "$USER" "$REPOSITORY" "$TITLE";
else
process_latest_github_release "$USER" "$REPOSITORY";
fi

if [ "$GENERATE_CONFIG" = "true" ]; then
rm -rf "${CONFIG}"
mv "${CONFIG}.tmp" "${CONFIG}"
fi

exit 0;
