
declare-option -docstring 'command to copy to clipboard' \
    str kakboard_copy_cmd "xsel --input --clipboard"

declare-option -docstring 'command to paste from clipboard' \
    str kakboard_paste_cmd "xsel --output --clipboard"

declare-option -docstring 'keys to pull clipboard for' \
    str-list kakboard_paste_keys p P R <a-p> <a-P> <a-R>

declare-option -docstring 'keys to copy to clipboard' \
    str-list kakboard_copy_keys y c a

declare-option -hidden bool kakboard_enabled false

define-command -docstring 'copy system clipboard into the " reigster' \
    kakboard-pull-clipboard %{ evaluate-commands %sh{
    # Shell expansions are stripped of new lines, so the output of the
    # command has to be wrapped in quotes (and its quotes escaped)
    # 
    # (All of this quoting and escaping really messes up kakoune's syntax
    # highlighter)
    printf 'set-register dquote %s' \
        "'$($kak_opt_kakboard_paste_cmd | sed -e "s/'/''/g"; echo \')"
}}

define-command -docstring 'copy system clipboard if current register is "' \
    kakboard-pull-for-dquote %{ evaluate-commands %sh{
    if test -z "$kak_register" -o "$kak_register" = '"'; then
        echo "kakboard-pull-clipboard"
    fi
}}

# Pull the clipboard and execute the key with the same context
define-command -hidden kakboard-with-clipboard -params 1 %{
    evaluate-commands %sh{
        if test -n "$kak_register"; then
            register="$kak_register"
        else
            register='"'
        fi
        echo "kakboard-pull-for-dquote"
        echo "execute-keys '\"$register$kak_count$1'"
    }
}

define-command -docstring 'enable clipboard integration' kakboard-enable %{
    set-option window kakboard_enabled true

    evaluate-commands %sh{
        key_regex=
        for key in $kakboard_copy_keys; do
            key_regex="$key_regex|$key"
        done
    }

    hook window -group kakboard NormalKey %sh{
        eval echo "$kak_opt_kakboard_copy_keys" | tr ' ' '|'
    } %{ nop %sh{
        if test -z "$kak_register" -o "$kak_register" = '"'; then
            printf '%s' "$kak_main_reg_dquote" | $kak_opt_kakboard_copy_cmd
        fi
    }}

    evaluate-commands %sh{
        for key in $kak_opt_kakboard_paste_keys; do
            escaped=$(eval echo $key | sed -e 's/</<lt>/')
            echo map global normal "$key" \
                "': kakboard-with-clipboard $escaped<ret>'"
        done
    }
}

define-command -docstring 'disable clipboard integration' kakboard-disable %{
    set-option window kakboard_enabled false

    remove-hooks window kakboard

    evaluate-commands %sh{
        for key in $kak_opt_kakboard_paste_keys; do
            echo unmap global normal "$key"
        done
    }
}

define-command -docstring 'toggle clipboard integration' kakboard-toggle %{
    evaluate-commands %sh{
        if test "$kak_opt_kakboard_enabled" = true; then
            echo "kakboard-disable"
        else
            echo "kakboard-enable"
        fi
    }
}