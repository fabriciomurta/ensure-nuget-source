#!/bin/bash

default_name="${INPUT_SOURCE_NAME}"
default_url="${INPUT_SOURCE_URL}"

if [ ${#default_name} -lt 1 ]; then
 default_name="nuget.org"
fi

if [ ${#default_url} -lt 1 ]; then
 default_url="https://api.nuget.org/v3/index.json"
fi

function fail() {
 local msg="${@}"
 >&2 echo "::error::${msg}"
 exit 1
}

function fail_cmd() {
 local msg="${1}" cmd="${2}" output="${3}"
 local multiline_msg

 multiline_msg="${msg}.
Failed command and output:

\$ ${cmd}

${output}
----

Aborting execution."
 fail "${multiline_msg}"
}

function regexp_clean() {
 local str="${@}"

 str="${str//\\/\\\\}"

 for char in \\. \\/ \\\[ \\\] \\\( \\\) \\\{ \\\} \\+ \\\*; do
  str="${str//${char}/${char}}"
 done

 echo "${str}"
}

re_default_name="$(regexp_clean "${default_name}")"

# https:\/\/api\.nuget\.org\/v3\/index\.json
re_default_url="$(regexp_clean "${default_url}")"

# absorb the welcome banner
cmd=(dotnet nuget list source)
result="$("${cmd[@]}" 2>&1)" || \
 fail_cmd "Unable to execute the 'dotnet' command" "${cmd[*]}" "${result}"

source_list="$("${cmd[@]}" 2>&1)" || \
 fail_cmd "Unable to get list of NuGet sources" "${cmd[*]}" "${source_list}"

echo -n "List of 'dotnet nuget' "
echo "${source_list}"
if ! echo "${source_list}" | egrep -q "^ +${re_default_url}.?\$"; then
 source_line="$(echo "${source_list}" | egrep "^ {0,2}[0-9]{1,3}\.  ${re_default_name} \[(En|Dis)abled\].?\$" | strings)"
 if [ ! -z "${source_line}" ]; then
  echo "- Updating ${default_name} source to ${default_url}..."
  cmd=(dotnet nuget update source "${default_name}" --source "${default_url}")
  result="$("${cmd[@]}" 2>&1)" || fail_cmd "Unable to update NuGet source '${default_name}' to point to '${default_url}'." "${cmd[*]}" "${result}"
  echo "- Updated NuGet source."
  if [ "${source_line:$(( 10#${#source_line} - 9 )):8}" == "Disabled" ]; then
   echo "- Enabling ${default_name} source..."
   cmd=(dotnet nuget enable source "${default_name}")
   result="$("${cmd[@]}" 2>&1)" || fail_cmd "Unable to enable NuGet source '${default_name}'." "${cmd[*]}" "${result}"
   echo "- Enabled NuGet source."
  elif [ "${source_line:$(( 10#${#source_line} - 8 )):7}" != "Enabled" ]; then
   fail "Unable to infer NuGet source enabled status."
  fi
 else
  echo "- Adding ${default_name} source for url ${default_url}..."
  cmd=(dotnet nuget add source "${default_url}" --name "${default_name}")
  result="$("${cmd[@]}" 2>&1)" || fail_cmd "Unable to add NuGet source '${default_name}=${default_url}'." "${cmd[*]}" "${result}"
  echo "- Added NuGet source."
 fi
 echo -n "Updated List of 'dotnet nuget' "
 dotnet nuget list source
else
 source_line="$(echo "${source_list}" | egrep -B1 "^ +${re_default_url}.?\$" | head -n1 | strings)"
 if [ ${#source_line} -gt 12 -a "${source_line:$(( 10#${#source_line} - 9 )):8}" == "Disabled" ]; then
  source_name="$(echo "${source_line}" | sed -E "s/^ *[0-9]+\. +(.*) \[Disabled\]\$/\1/")"
  echo "- Enabling '${source_name}' NuGet source..."
  if [ "${source_name}" == "${source_line}" ]; then
   fail "Unable to infer NuGet source name from NuGet sources list."
  else
   cmd=(dotnet nuget enable source "${source_name}")
   result="$("${cmd[@]}" 2>&1)" || fail_cmd "Unable to enable NuGet source '${source_name}'." "${cmd[*]}" "${result}"
   echo "- Enabled NuGet source."
  fi
 echo -n "Updated List of 'dotnet nuget' "
  dotnet nuget list source
 elif [ ${#source_line} -lt 11 -o "${source_line:$(( 10#${#source_line} - 8 )):7}" != "Enabled" ]; then
  fail "Unable to infer NuGet source enabled status."
 else
  echo "- NuGet source for '${default_url}' is correctly set."
 fi
fi