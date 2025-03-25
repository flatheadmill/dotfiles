
# Example of a function that optionally reads a heredoc from standard input.
# In this case `-v variable` argument will be interpreted as a warning
# message.
function warn {
    typeset message
    if (( ! $# )); then
        warn -
    else
        case $1 in
            -f | -q | - )
                heredoc "$@" 1>&2
                ;;
            -- )
                shift
                ;&
            * )
                printf -v message -- "$@"
                printf '%s\n' $message 1>&2
                ;;
        esac
    fi
}

function abend {
    typeset message
    if (( ! $# )); then
        warn -
    else
        case $1 in
            -f | -q | - )
                heredoc "$@" 1>&2
                ;;
            -- )
                shift
                ;&
            * )
                printf -v message -- "$@"
                printf '%s\n' $message 1>&2
                ;;
        esac
    fi
    exit 1
}

function heredoc {
    if [[ $# -eq 0 || ( $# -eq 1 && $1 = - ) ]]; then
        function {
            typeset match=() lines=() chomped=()
            typeset spaces=65536 leading='^( *)([^[:space:]])' line heredoc
            IFS= read -rd '' heredoc
            for line in "${(@Af)heredoc}"; do
                lines+=( "$line" ) # remove the double quotes and blank lines disappear
                if [[ $line =~ $leading && ${#match[1]} -lt $spaces ]]; then
                    spaces=${#match[1]}
                fi
            done
            for line in "${(@)lines}"; do
                chomped+=( "${line[spaces + 1,-1]}" ) # remove the double quotes and blank lines disappear
            done
            printf '%s' ${(pj:\n:)chomped[1,-2]}$'\n'
        }
    else
        # We create code to source that will not shadow any variables
        # specified with `-v`.
        #
        # Inclined to use `eval "$()"` but it will not syntax highlight
        # correction in ViM.
        source <(
            function {
                typeset mode=- variable=() vargs=() emit=() heredoc
                while (( $# )); do
                    case $1 in
                        -v )
                            variable=( $1 $2 )
                            shift 2
                            ;;
                        - )
                            mode=-
                            ;;
                        -q )
                            mode=q
                            shift
                            ;;
                        -f )
                            mode=f
                            shift
                            ;;
                        -- )
                            shift
                            vargs=( "$@" )
                            break
                            ;;
                        * )
                            [[ $mode = f ]] || { print -u 2 bad; exit 1; }
                            vargs=( "$@" )
                            break
                            ;;
                    esac
                done
                case $mode in
                    - )
                        IFS= read -rd '' heredoc < <(heredoc)
                        emit=( 'printf' "${(@)variable}" '%s' $heredoc )
                        printf '%s' ${(j: :)${(@qq)emit}}
                        ;;
                    f )
                        IFS= read -rd '' heredoc < <(heredoc)
                        emit=( 'printf' "${(@)variable}" -- $heredoc "${(@)vargs}" )
                        printf '%s' ${(j: :)${(@qq)emit}}
                        ;;
                    q )
                        if (( ${#variable} )); then
                            printf "IFS= read -rd '' %s < <(heredoc -q)\n" $variable[2]
                        else
                            IFS= read -rd '' heredoc < <(heredoc)
                            printf 'cat <<__HEREDOC_Q_EOF__\n%s__HEREDOC_Q_EOF__\n' $heredoc
                        fi
                        ;;
                esac
            } "$@"
        )
    fi
}

function {
    [[ $1 == 'toplevel' ]] || return
    heredoc -q <<'    EOF'
        hello, world

        hello, world
    EOF
    return
    heredoc - <<'    EOF'
        hello, world
    EOF
    typeset hello=hello world=world value
    heredoc -v value -q <<'    EOF'
        $hello, $world
    EOF
    heredoc -f hello world <<'    EOF'
        %s, %s
    EOF
    heredoc -f -- hello world <<'    EOF'
        %s, %s
    EOF
    print -- -- values --
    value=
    heredoc -v value <<'    EOF'
        hello, world
    EOF
    printf -- $value
    value=
    heredoc -v value -f hello world <<'    EOF'
        %s, %s
    EOF
    printf -- $value
    value=
    heredoc -f -v value -- hello world <<'    EOF'
        %s, %s
    EOF
    value=
    heredoc -v value -q <<'    EOF'
        $hello, $world
    EOF
    printf -- $value
} $ZSH_EVAL_CONTEXT
