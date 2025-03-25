function struct {
    case $1 in
        put )
            [[ ${(Pt)2} = association-local ]] ||
                abend 'fatal: struct must be an associative array.'
            set -- $2 "${(PA@kv)2}" $3 ${${(j: :)${(@qq)@[4,-1]}}}
            : ${(PAA)1::=$@[2,-1]}
            ;;
        get )
            case ${(Pt)4} in
                association-local )
                    if [[ -n "${${(P)2}[$3]}" ]]; then
                        : ${(PAA)4::=${(@QA)${(@z)${(P)2}[$3]}}}
                    else
                        : ${(PAA)4::=$@[1,0]}
                    fi
                    ;;
                array-local )
                    if [[ -n "${${(P)2}[$3]}" ]]; then
                        : ${(PA)4::=${(@QA)${(@z)${(P)2}[$3]}}}
                    else
                        : ${(PA)4::=$@[1,0]}
                    fi
                    ;;
                * )
                    abend 'fatal: output must be an associative array or an array'
                    ;;
            esac
            ;;
    esac
}

function {
    [[ $1 == 'toplevel' ]] || return
    typeset array=()
    typeset -A struct=( name wrong ) associative
    struct put struct name key value
    struct get struct name associative
    print -- ---
    print -l "${(@kv)associative}"
    print -- ---
    struct get struct missing associative
    print "${#${(@kv)associative}}"
    print -- ---
    struct get struct name array
    print -l "${(@)array}"
    print -- ---
    struct get struct missing array
    print "${#array}"
} $ZSH_EVAL_CONTEXT
