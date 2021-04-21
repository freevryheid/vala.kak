hook global BufCreate .*\.vala %{
    set-option buffer filetype vala
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=vala %{
    require-module vala

    # cleanup trailing whitespaces when exiting insert mode
    hook window ModeChange pop:insert:.* -group vala-trim-indent %{ try %{ execute-keys -draft <a-x>s^\h+$<ret>d } }
    hook window InsertChar \n -group vala-indent vala-indent-on-new-line
    hook window InsertChar \{ -group vala-indent vala-indent-on-opening-curly-brace
    hook window InsertChar \} -group vala-indent vala-indent-on-closing-curly-brace

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window vala-.+ }
}

hook -group vala-highlight global WinSetOption filetype=vala %{
    add-highlighter window/vala ref vala
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/vala }
}

provide-module vala %§

add-highlighter shared/vala regions
add-highlighter shared/vala/code default-region group
add-highlighter shared/vala/string region %{(?<!')"} %{(?<!\\)(\\\\)*"} fill string
add-highlighter shared/vala/comment region /\* \*/ fill comment
add-highlighter shared/vala/inline_documentation region /// $ fill documentation
add-highlighter shared/vala/line_comment region // $ fill comment

add-highlighter shared/vala/code/ regex %{\b(this|true|false|null)\b} 0:value
add-highlighter shared/vala/code/ regex "\b(void|int|uint|char|unichar|unsigned|float|bool|double|string|long|short|ushort)\b" 0:type
add-highlighter shared/vala/code/ regex "\b(while|for|foreach|if|else|do|static|switch|case|default|class|interface|enum|goto|break|continue|return|import|try|catch|throw|new|package|extends|implements|throws|instanceof|var|using|throw|delete)\b" 0:keyword
add-highlighter shared/vala/code/ regex "\b(final|public|protected|private|abstract|synchronized|native|transient|volatile|unowned|delegate|namespace|struct|enum|internal|this|static|signal|get|set|virtual)\b" 0:attribute
add-highlighter shared/vala/code/ regex "(?<!\w)@\w+\b" 0:meta
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b[1-9]('?\d+)*(ul?l?|ll?u?)?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0b[01]('?[01]+)*(ul?l?|ll?u?)?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0('?[0-7]+)*(ul?l?|ll?u?)?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0x[\da-f]('?[\da-f]+)*(ul?l?|ll?u?)?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b\d('?\d+)*\.([fl]\b|\B)(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b\d('?\d+)*\.?e[+-]?\d('?\d+)*[fl]?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)(\b(\d('?\d+)*)|\B)\.\d('?[\d]+)*(e[+-]?\d('?\d+)*)?[fl]?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0x[\da-f]('?[\da-f]+)*\.([fl]\b|\B)(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0x[\da-f]('?[\da-f]+)*\.?p[+-]?\d('?\d+)*)?[fl]?\b(?!\.)} 0:value
add-highlighter shared/vala/code/ regex %{(?i)(?<!\.)\b0x([\da-f]('?[\da-f]+)*)?\.\d('?[\d]+)*(p[+-]?\d('?\d+)*)?[fl]?\b(?!\.)} 0:value
add-highlighter shared/vala/code/char regex %{(\b(u8|u|U|L)|\B)'((\\.)|[^'\\])'\B} 0:value


# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden vala-indent-on-new-line %~
    evaluate-commands -draft -itersel %=
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon>K<a-&> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k<a-x> <a-k> [{(]\h*$ <ret> j<a-gt> ]
        # cleanup trailing white spaces on the previous line
        try %{ execute-keys -draft k<a-x> s \h+$ <ret>d }
        # align to opening paren of previous line
        try %{ execute-keys -draft [( <a-k> \A\([^\n]+\n[^\n]*\n?\z <ret> s \A\(\h*.|.\z <ret> '<a-;>' & }
        # copy // comments prefix
        try %{ execute-keys -draft <semicolon><c-s>k<a-x> s ^\h*\K/{2,} <ret> y<c-o>P<esc> }
        # indent after a switch's case/default statements
        try %[ execute-keys -draft k<a-x> <a-k> ^\h*(case|default).*:$ <ret> j<a-gt> ]
        # indent after keywords
        try %[ execute-keys -draft <semicolon><a-F>)MB <a-k> \A(if|else|while|for|try|catch)\h*\(.*\)\h*\n\h*\n?\z <ret> s \A|.\z <ret> 1<a-&>1<a-space><a-gt> ]
        # deindent closing brace(s) when after cursor
        try %[ execute-keys -draft <a-x> <a-k> ^\h*[})] <ret> gh / [})] <ret> m <a-S> 1<a-&> ]
    =
~

define-command -hidden vala-indent-on-opening-curly-brace %[
    # align indent with opening paren when { is entered on a new line after the closing paren
    try %[ execute-keys -draft -itersel h<a-F>)M <a-k> \A\(.*\)\h*\n\h*\{\z <ret> s \A|.\z <ret> 1<a-&> ]
]

define-command -hidden vala-indent-on-closing-curly-brace %[
    # align to opening curly brace when alone on a line
    try %[ execute-keys -itersel -draft <a-h><a-k>^\h+\}$<ret>hms\A|.\z<ret>1<a-&> ]
]

§
