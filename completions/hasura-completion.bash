# bash completion for hasura                               -*- shell-script -*-

__hasura_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__hasura_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__hasura_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__hasura_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__hasura_handle_go_custom_completion()
{
    __hasura_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly hasura allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __hasura_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __hasura_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __hasura_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __hasura_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __hasura_debug "${FUNCNAME[0]}: the completions are: ${out[*]}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __hasura_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __hasura_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __hasura_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __hasura_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subDir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out[0]}")
        if [ -n "$subdir" ]; then
            __hasura_debug "Listing directories in $subdir"
            __hasura_handle_subdirs_in_dir_flag "$subdir"
        else
            __hasura_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out[*]}" -- "$cur")
    fi
}

__hasura_handle_reply()
{
    __hasura_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __hasura_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __hasura_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __hasura_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __hasura_custom_func >/dev/null; then
			# try command name qualified custom func
			__hasura_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__hasura_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__hasura_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__hasura_handle_flag()
{
    __hasura_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __hasura_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __hasura_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __hasura_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __hasura_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __hasura_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__hasura_handle_noun()
{
    __hasura_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __hasura_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __hasura_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__hasura_handle_command()
{
    __hasura_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_hasura_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __hasura_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__hasura_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __hasura_handle_reply
        return
    fi
    __hasura_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __hasura_handle_flag
    elif __hasura_contains_word "${words[c]}" "${commands[@]}"; then
        __hasura_handle_command
    elif [[ $c -eq 0 ]]; then
        __hasura_handle_command
    elif __hasura_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __hasura_handle_command
        else
            __hasura_handle_noun
        fi
    else
        __hasura_handle_noun
    fi
    __hasura_handle_word
}

_hasura_actions_codegen()
{
    last_command="hasura_actions_codegen"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--derive-from=")
    two_word_flags+=("--derive-from")
    local_nonpersistent_flags+=("--derive-from")
    local_nonpersistent_flags+=("--derive-from=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_actions_create()
{
    last_command="hasura_actions_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--derive-from=")
    two_word_flags+=("--derive-from")
    local_nonpersistent_flags+=("--derive-from")
    local_nonpersistent_flags+=("--derive-from=")
    flags+=("--kind=")
    two_word_flags+=("--kind")
    local_nonpersistent_flags+=("--kind")
    local_nonpersistent_flags+=("--kind=")
    flags+=("--webhook=")
    two_word_flags+=("--webhook")
    local_nonpersistent_flags+=("--webhook")
    local_nonpersistent_flags+=("--webhook=")
    flags+=("--with-codegen")
    local_nonpersistent_flags+=("--with-codegen")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_actions_use-codegen()
{
    last_command="hasura_actions_use-codegen"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--framework=")
    two_word_flags+=("--framework")
    local_nonpersistent_flags+=("--framework")
    local_nonpersistent_flags+=("--framework=")
    flags+=("--output-dir=")
    two_word_flags+=("--output-dir")
    local_nonpersistent_flags+=("--output-dir")
    local_nonpersistent_flags+=("--output-dir=")
    flags+=("--with-starter-kit")
    local_nonpersistent_flags+=("--with-starter-kit")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_actions()
{
    last_command="hasura_actions"

    command_aliases=()

    commands=()
    commands+=("codegen")
    commands+=("create")
    commands+=("use-codegen")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_completion()
{
    last_command="hasura_completion"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    flags_with_completion+=("--file")
    flags_completion+=("_filedir")
    local_nonpersistent_flags+=("--file")
    local_nonpersistent_flags+=("--file=")
    flags+=("--help")
    flags+=("-h")
    local_nonpersistent_flags+=("--help")
    local_nonpersistent_flags+=("-h")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_console()
{
    last_command="hasura_console"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    local_nonpersistent_flags+=("--address")
    local_nonpersistent_flags+=("--address=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret=")
    flags+=("--api-port=")
    two_word_flags+=("--api-port")
    local_nonpersistent_flags+=("--api-port")
    local_nonpersistent_flags+=("--api-port=")
    flags+=("--browser=")
    two_word_flags+=("--browser")
    local_nonpersistent_flags+=("--browser")
    local_nonpersistent_flags+=("--browser=")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority=")
    flags+=("--console-port=")
    two_word_flags+=("--console-port")
    local_nonpersistent_flags+=("--console-port")
    local_nonpersistent_flags+=("--console-port=")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--no-browser")
    local_nonpersistent_flags+=("--no-browser")
    flags+=("--static-dir=")
    two_word_flags+=("--static-dir")
    local_nonpersistent_flags+=("--static-dir")
    local_nonpersistent_flags+=("--static-dir=")
    flags+=("--use-server-assets")
    local_nonpersistent_flags+=("--use-server-assets")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_help()
{
    last_command="hasura_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_init()
{
    last_command="hasura_init"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret=")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--install-manifest=")
    two_word_flags+=("--install-manifest")
    local_nonpersistent_flags+=("--install-manifest")
    local_nonpersistent_flags+=("--install-manifest=")
    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_apply()
{
    last_command="hasura_metadata_apply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_clear()
{
    last_command="hasura_metadata_clear"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_diff()
{
    last_command="hasura_metadata_diff"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--type=")
    two_word_flags+=("--type")
    local_nonpersistent_flags+=("--type")
    local_nonpersistent_flags+=("--type=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_export()
{
    last_command="hasura_metadata_export"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_inconsistency_drop()
{
    last_command="hasura_metadata_inconsistency_drop"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_inconsistency_list()
{
    last_command="hasura_metadata_inconsistency_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_inconsistency_status()
{
    last_command="hasura_metadata_inconsistency_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_inconsistency()
{
    last_command="hasura_metadata_inconsistency"

    command_aliases=()

    commands=()
    commands+=("drop")
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("status")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata_reload()
{
    last_command="hasura_metadata_reload"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_metadata()
{
    last_command="hasura_metadata"

    command_aliases=()

    commands=()
    commands+=("apply")
    commands+=("clear")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("reset")
        aliashash["reset"]="clear"
    fi
    commands+=("diff")
    commands+=("export")
    commands+=("inconsistency")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ic")
        aliashash["ic"]="inconsistency"
        command_aliases+=("inconsistencies")
        aliashash["inconsistencies"]="inconsistency"
    fi
    commands+=("reload")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate_apply()
{
    last_command="hasura_migrate_apply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--up=")
    two_word_flags+=("--up")
    local_nonpersistent_flags+=("--up")
    local_nonpersistent_flags+=("--up=")
    flags+=("--down=")
    two_word_flags+=("--down")
    local_nonpersistent_flags+=("--down")
    local_nonpersistent_flags+=("--down=")
    flags+=("--goto=")
    two_word_flags+=("--goto")
    local_nonpersistent_flags+=("--goto")
    local_nonpersistent_flags+=("--goto=")
    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--skip-execution")
    local_nonpersistent_flags+=("--skip-execution")
    flags+=("--type=")
    two_word_flags+=("--type")
    local_nonpersistent_flags+=("--type")
    local_nonpersistent_flags+=("--type=")
    flags+=("--dry-run")
    local_nonpersistent_flags+=("--dry-run")
    flags+=("--all-databases")
    local_nonpersistent_flags+=("--all-databases")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate_create()
{
    last_command="hasura_migrate_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--down-sql=")
    two_word_flags+=("--down-sql")
    local_nonpersistent_flags+=("--down-sql")
    local_nonpersistent_flags+=("--down-sql=")
    flags+=("--from-server")
    local_nonpersistent_flags+=("--from-server")
    flags+=("--metadata-from-file=")
    two_word_flags+=("--metadata-from-file")
    flags_with_completion+=("--metadata-from-file")
    flags_completion+=("_filedir")
    local_nonpersistent_flags+=("--metadata-from-file")
    local_nonpersistent_flags+=("--metadata-from-file=")
    flags+=("--metadata-from-server")
    local_nonpersistent_flags+=("--metadata-from-server")
    flags+=("--schema=")
    two_word_flags+=("--schema")
    local_nonpersistent_flags+=("--schema")
    local_nonpersistent_flags+=("--schema=")
    flags+=("--sql-from-file=")
    two_word_flags+=("--sql-from-file")
    flags_with_completion+=("--sql-from-file")
    flags_completion+=("_filedir")
    local_nonpersistent_flags+=("--sql-from-file")
    local_nonpersistent_flags+=("--sql-from-file=")
    flags+=("--sql-from-server")
    local_nonpersistent_flags+=("--sql-from-server")
    flags+=("--up-sql=")
    two_word_flags+=("--up-sql")
    local_nonpersistent_flags+=("--up-sql")
    local_nonpersistent_flags+=("--up-sql=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate_delete()
{
    last_command="hasura_migrate_delete"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all")
    local_nonpersistent_flags+=("--all")
    flags+=("--force")
    local_nonpersistent_flags+=("--force")
    flags+=("--server")
    local_nonpersistent_flags+=("--server")
    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate_squash()
{
    last_command="hasura_migrate_squash"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--delete-source")
    local_nonpersistent_flags+=("--delete-source")
    flags+=("--from=")
    two_word_flags+=("--from")
    local_nonpersistent_flags+=("--from")
    local_nonpersistent_flags+=("--from=")
    flags+=("--name=")
    two_word_flags+=("--name")
    local_nonpersistent_flags+=("--name")
    local_nonpersistent_flags+=("--name=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_flag+=("--from=")
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate_status()
{
    last_command="hasura_migrate_status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_migrate()
{
    last_command="hasura_migrate"

    command_aliases=()

    commands=()
    commands+=("apply")
    commands+=("create")
    commands+=("delete")
    commands+=("squash")
    commands+=("status")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_plugins_install()
{
    last_command="hasura_plugins_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_plugins_list()
{
    last_command="hasura_plugins_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dont-update-index")
    local_nonpersistent_flags+=("--dont-update-index")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_plugins_uninstall()
{
    last_command="hasura_plugins_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_plugins_upgrade()
{
    last_command="hasura_plugins_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_plugins()
{
    last_command="hasura_plugins"

    command_aliases=()

    commands=()
    commands+=("install")
    commands+=("list")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ls")
        aliashash["ls"]="list"
    fi
    commands+=("uninstall")
    commands+=("upgrade")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_scripts_update-project-v2()
{
    last_command="hasura_scripts_update-project-v2"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret=")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority=")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--metadata-dir=")
    two_word_flags+=("--metadata-dir")
    local_nonpersistent_flags+=("--metadata-dir")
    local_nonpersistent_flags+=("--metadata-dir=")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_scripts_update-project-v3()
{
    last_command="hasura_scripts_update-project-v3"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret")
    local_nonpersistent_flags+=("--admin-secret=")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority")
    local_nonpersistent_flags+=("--certificate-authority=")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    local_nonpersistent_flags+=("--database-name")
    local_nonpersistent_flags+=("--database-name=")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint")
    local_nonpersistent_flags+=("--endpoint=")
    flags+=("--force")
    local_nonpersistent_flags+=("--force")
    flags+=("--insecure-skip-tls-verify")
    local_nonpersistent_flags+=("--insecure-skip-tls-verify")
    flags+=("--move-state-only")
    local_nonpersistent_flags+=("--move-state-only")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_scripts()
{
    last_command="hasura_scripts"

    command_aliases=()

    commands=()
    commands+=("update-project-v2")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("update-config-v2")
        aliashash["update-config-v2"]="update-project-v2"
    fi
    commands+=("update-project-v3")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_seed_apply()
{
    last_command="hasura_seed_apply"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    local_nonpersistent_flags+=("--file")
    local_nonpersistent_flags+=("--file=")
    local_nonpersistent_flags+=("-f")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_seed_create()
{
    last_command="hasura_seed_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--from-table=")
    two_word_flags+=("--from-table")
    local_nonpersistent_flags+=("--from-table")
    local_nonpersistent_flags+=("--from-table=")
    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_seed()
{
    last_command="hasura_seed"

    command_aliases=()

    commands=()
    commands+=("apply")
    commands+=("create")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--admin-secret=")
    two_word_flags+=("--admin-secret")
    flags+=("--certificate-authority=")
    two_word_flags+=("--certificate-authority")
    flags+=("--database-name=")
    two_word_flags+=("--database-name")
    flags+=("--disable-interactive")
    flags+=("--endpoint=")
    two_word_flags+=("--endpoint")
    flags+=("--insecure-skip-tls-verify")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_update-cli()
{
    last_command="hasura_update-cli"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--version=")
    two_word_flags+=("--version")
    local_nonpersistent_flags+=("--version")
    local_nonpersistent_flags+=("--version=")
    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_version()
{
    last_command="hasura_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_hasura_root_command()
{
    last_command="hasura"

    command_aliases=()

    commands=()
    commands+=("actions")
    commands+=("completion")
    commands+=("console")
    commands+=("help")
    commands+=("init")
    commands+=("metadata")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("md")
        aliashash["md"]="metadata"
    fi
    commands+=("migrate")
    commands+=("plugins")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("plugin")
        aliashash["plugin"]="plugins"
    fi
    commands+=("scripts")
    commands+=("seed")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("sd")
        aliashash["sd"]="seed"
        command_aliases+=("seeds")
        aliashash["seeds"]="seed"
    fi
    commands+=("update-cli")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--envfile=")
    two_word_flags+=("--envfile")
    flags+=("--log-level=")
    two_word_flags+=("--log-level")
    flags+=("--no-color")
    flags+=("--project=")
    two_word_flags+=("--project")
    flags+=("--skip-update-check")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_hasura()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __hasura_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("hasura")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function
    local last_command
    local nouns=()

    __hasura_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_hasura hasura
else
    complete -o default -o nospace -F __start_hasura hasura
fi

# ex: ts=4 sw=4 et filetype=sh
