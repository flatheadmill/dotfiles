function parser {
    setopt localoptions extendedglob
    typeset error=$1 depth=$2
    shift 2

    typeset is_number='
        (){
            case ${1#[-+]} in
                *[!0-9]* | "" )
                    %s %s integer %s
                    ;;
            esac
        } %s
    '

    {
        typeset -A option=( kind scalar defined 0 required 0 ) short options missing
        typeset full part split long=() declared=() stack=( "${(@Oa)@}" ) popped arrival=() intersperse=0
        integer top=${#stack}
        while (( top )); do
            popped=$stack[$top]
            case $popped in
                -- )
                    ((top--))
                    break
                    ;;
                -* )
                    case $popped in
                        -! )
                            option[negatable]=1
                            ;;
                        -@* )
                            intersperse=1
                            ;;
                        -a* )
                            option[kind]=array
                            ;;
                        -A* )
                            option[kind]=map
                            ;;
                        -b* )
                            option[kind]=boolean
                            ;;
                        -c* )
                            option[kind]=counter
                            ;;
                        -d* )
                            option[defined]=1
                            ;;
                        -i* )
                            option[kind]=number
                            ;;
                        -r* )
                            option[required]=1
                            ;;
                        -s* )
                            option[kind]=scalar
                            ;;
                        -x* )
                            option[execute]=1
                            ;;
                    esac
                    if (( ${#popped} > 2 )); then
                        stack[$top]="-${popped[3,-1]}"
                    else
                        ((top--))
                    fi
                    ;;
                [a-z]#,[a-z][a-z-]##[a-z] )
                    split=( "${(@s:,:)popped}" )
                    if [[ -n $split[1] ]]; then
                        short[$split[1]]=$split[2]
                    fi
                    option[short]=$split[1]
                    option[long]=$split[2]
                    options[$split[2]]=${(j: :)${(@qqkv)option}}
                    long+=( $split[2] )
                    case $option[kind] in
                        counter | boolean | toggle )
                            printf 'integer o_%s=0\n' ${option[long]//-/_}
                            ;;
                        * )
                            if (( ! $option[defined] )); then
                                printf 'typeset o_%s\n' ${option[long]//-/_}
                                printf 'unset o_%s\n' ${option[long]//-/_}
                            fi
                            ;;
                    esac
                    if (( $option[required] )); then
                        missing[$option[long]]=1
                    fi
                    option=( kind $option[kind] defined 0 required 0 )
                    ((top--))
                    ;;
                * )
                    print -u 2 "unable to interpet $full"
                    printf '%s %s compile -' $error $funcstack[$depth]
                    exit 1
                    ;;
            esac
        done

        long=( ${(@o)long} )

        typeset index state=switch key interspersed=() expect=() flag
        while (( top )); do
            popped=$stack[$top]
            case $state$popped in
                switch-- )
                    ((top--))
                    break
                    ;;
                switch--no-* )
                    ;;
                switch--* )
                    case $popped in
                        (#b)--no-([^=]##) )
                            flag=$match[1]
                            stack[$top]=$match[1]
                            expect=( boolean )
                            ;;
                        (#b)--([^=]##)=(*) )
                            flag=$match[1]
                            stack[$top]=$match[1]
                            ;;
                        (#b)--(*) )
                            flag=$match[1]
                            ((top--))
                    esac
                    index=$long[(I)$flag*]
                    if (( ! index )); then
                        printf '%s %s unknown %s\n' $error $funcstack[$depth] $flag
                        return
                    fi
                    option=( "${(@QA)${(z)options[$long[$index]]}}" )
                    missing[$option[long]]=0
                    case $popped in
                        (#b)--no-([^=]##) )
                            if (( ! $option[negatable] )); then
                                printf '%s %s unknown %s\n' $error $funcstack[$depth] --$match[1]
                            fi
                            ;;
                        (#b)--([^=]##)=* )
                            case $option[kind] in
                                boolean | counter )
                                    printf '%s %s unassignable %s\n' $error $funcstack[$depth] --$match[1]
                                    ;;
                            esac
                            ;;
                    esac
                    ;;
                switch-* )
                    flag=${popped[2,2]}
                    if (( ! ${+short[${popped[2,2]}]} )); then
                        printf '%s %s unknown %s\n' $error $funcstack[$depth] $popped[1,2]
                        exit 1
                    fi
                    index=$long[(Ie)$short[$popped[2,2]]]
                    option=( "${(@QA)${(z)options[$long[$index]]}}" )
                    case $option[kind] in
                        boolean | counter )
                            if (( ${#popped} == 2 )); then
                                ((top--))
                            else
                                stack[$top]=-${popped[3,-1]}
                            fi
                            ;;
                        * )
                            if (( ${#popped} == 2 )); then
                                ((top--))
                            else
                                stack[$top]=${popped[3,-1]}
                            fi
                            ;;
                    esac
                    ;;
                switch* )
                    (( intersperse )) || break
                    interspersed+=( $popped )
                    ((top--))
                    continue
                    ;;
                key* )
                    if [[ $popped = (#b)([^=]##)=(*) ]]; then
                        key=$match[1]
                        stack[$top]=$match[2]
                    else
                        key=$popped
                        ((top--))
                    fi
                    state=value
                    continue
                    ;;
                value* )
                    case $option[kind] in
                        array )
                            printf 'o_%s+=( %s )\n' ${option[long]//-/_} ${(qq)popped}
                            ;;
                        map )
                            printf '(){ typeset key=%s; o_%s[$key]=%s; }\n' ${(qq)key} ${option[long]//-/_} ${(qq)popped}
                            ;;
                        scalar )
                            printf 'o_%s=%s\n' ${option[long]//-/_} ${(qq)popped}
                            ;;
                    esac
                    stack[$top]=0
                    state=execute
                    continue
                    ;;
                execute0 )
                    if (( $option[execute] )); then
                        printf '%s %s %s %s\n' $error $funcstack[$depth] execute "--$option[long]"
                    fi
                    state=switch
                    ((top--))
                    continue
                    ;;
                * )
                    print derp
                    exit 1
                    ;;
            esac
            if (( ! $declared[(Ie)$option[long]] )); then
                if (( $option[defined] )); then
                    case $option[kind] in
                        array | map )
                            printf 'o_%s=()\n' ${option[long]//-/_}
                            ;;
                    esac
                else
                    case $option[kind] in
                        number )
                            printf 'integer o_%s\n' ${option[long]//-/_}
                            ;;
                        array )
                            printf 'typeset o_%s=()\n' ${option[long]//-/_}
                            ;;
                        map )
                            printf 'typeset -A o_%s=()\n' ${option[long]//-/_}
                            ;;
                        scalar )
                            printf 'typeset o_%s\n' ${option[long]//-/_}
                            ;;
                    esac
                fi
                declared+=( $option[long] )
                arrival+=( $option[long] )
            fi
            case $option[kind] in
                boolean )
                    printf 'o_%s=1\n' ${option[long]//-/_}
                    ;;
                counter )
                    printf '((o_%s++))\n' ${option[long]//-/_}
                    ;;
            esac
            case $option[kind] in
                boolean | counter | toggle )
                    state=execute
                    ((top++))
                    stack[$top]=0
                    ;;
                map )
                    state=key
                    ;;
                * )
                    state=value
                    ;;
            esac
        done
        for flag in ${(@)long}; do
            if (( $missing[$flag] )); then
                printf '%s %s %s %s\n' $error $funcstack[$depth] required "--$flag"
            fi
        done
    } always {
        typeset combined=( "${(@)interspersed}" "${(@Oa)stack[1,$top]}" )
        if (( ${#combined} )); then
            printf 'set -- %s\n' ${(j: :)${(@qq)combined}}
        else
            printf 'set --\n'
        fi
    }
}

function error {
    typeset func=${1:-} reason=${2:-} flag=${3:-}
    case $reason in
        required )
            printf '`%s` is a required argument.\n' $flag 1>&2
            exit 1
            ;;
        execute )
            print "here's some help"
            exit
    esac
}

function strict {
    #parser error -b a,alfa -s b,bravo -a c,charlie -c d,delta -A f,foxtrot -- "$@"
    parser error 2 -bx h,help -s a,alfa -A b,bravo -- "$@"
}

function sprinkle {
    #parser error -b a,alfa -s b,bravo -a c,charlie -c d,delta -A f,foxtrot -- "$@"
    parser error 2 -@ -bx h,help -s a,alfa -A b,bravo -b c,charlie ,delta -- "$@"
}

function example {
    sprinkle --help
    print -- ---
    sprinkle --alf a
    print -- ---
    sprinkle --bra key value
    print -- ---
    sprinkle --bravo key=value
    print -- ---
    sprinkle bar --bravo key=value baz -- --qux
    print -- ---
    strict bar --bravo key=value baz -- --qux
    print -- --
    sprinkle -cafoo -h
    print -- --
    sprinkle --delta
    print -- --
    sprinkle -b key=value
}
