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
        # Initial loop to grab the definition and to define the variables to which
        # arguments will be assigned.
        typeset -A option=( kind scalar defined 0 required 0 ) short options missing
        typeset split=() long=() declared=() stack=( "${(@Oa)@}" ) popped intersperse=0
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
                        -!* )
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
                        -t* )
                            option[kind]=toggle
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
                [a-zA-Z0-9]#,[a-zA-Z][a-zA-Z-]#[a-z] )
                    split=( "${(@s:,:)popped}" )
                    if [[ -n $split[1] ]]; then
                        short[$split[1]]=$split[2]
                    fi
                    option[short]=$split[1]
                    option[long]=$split[2]
                    options[$split[2]]=${(j: :)${(@qqkv)option}}
                    long+=( $split[2] )
                    if (( ! $option[defined] )); then
                        case $option[kind] in
                            counter | boolean | toggle )
                                printf 'integer o_%s=0\n' ${option[long]//-/_}
                                ;;
                            array )
                                printf 'typeset o_%s=()\n' ${option[long]//-/_}
                                ;;
                            map )
                                printf 'typeset -A o_%s=()\n' ${option[long]//-/_}
                                ;;
                            * )
                                printf 'typeset o_%s\n' ${option[long]//-/_}
                                printf 'unset o_%s\n' ${option[long]//-/_}
                                ;;
                        esac
                    fi
                    if (( $option[required] )); then
                        missing[$option[long]]=1
                    fi
                    option=( kind $option[kind] defined 0 required 0 )
                    ((top--))
                    ;;
                * )
                    print -u 2 "unable to interpret $popped"
                    printf '%s %s compile -' $error $funcstack[$depth]
                    exit 1
                    ;;
            esac
        done

        long=( ${(@o)long} )

        typeset index state=switch key interspersed=() flag truth=1
        while (( top )); do
            popped=$stack[$top]
            case $state:$popped in
                switch:-- )
                    ((top--))
                    break
                    ;;
                switch:--* )
                    # First determine the flag name so we can look up the options definition.
                    case $popped in
                        (#b)--no-([^=]##) )
                            flag=$match[1]
                            ((top--))
                            ;;
                        (#b)--([^=]##)=(*) )
                            flag=$match[1]
                            stack[$top]=$match[2]
                            ;;
                        (#b)--(*) )
                            flag=$match[1]
                            ((top--))
                    esac
                    # Should we complain if the argument is ambiguous? Currently, we are
                    # just accepting the first match in alphabetical order.
                    index=$long[(I)$flag*]
                    if (( ! index )); then
                        printf '%s %s unknown %s\n' $error $funcstack[$depth] $flag
                        return
                    fi
                    option=( "${(@QA)${(z)options[$long[$index]]}}" )
                    missing[$option[long]]=0
                    # Go back over our poppped argument to determine if it is a negated
                    # boolean or an assignment.
                    case $popped in
                        (#b)--no-([^=]##) )
                            if (( ! $option[negatable] )); then
                                printf '%s %s unknown %s\n' $error $funcstack[$depth] --$match[1]
                            fi
                            truth=0
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
                switch:-* )
                    flag=${popped[2,2]}
                    if [[ $flag = '!' ]]; then
                        truth=0
                        if (( ${#popped} == 2 )); then
                            printf '%s %s unknown %s\n' $error $funcstack[$depth] $popped[1,2]
                            exit 1
                        fi
                        stack[$top]=-${popped[3,-1]}
                        continue
                    elif (( ! ${+short[${popped[2,2]}]} )); then
                        printf '%s %s unknown %s\n' $error $funcstack[$depth] $popped[1,2]
                        exit 1
                    else
                        index=$long[(Ie)$short[$popped[2,2]]]
                        option=( "${(@QA)${(z)options[$long[$index]]}}" )
                        missing[$option[long]]=0
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
                    fi
                    ;;
                switch:* )
                    (( intersperse )) || break
                    interspersed+=( $popped )
                    ((top--))
                    continue
                    ;;
                key:* )
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
                value:* )
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
                        boolean )
                            printf 'o_%s=%d\n' ${option[long]//-/_} $popped
                            ;;
                        counter )
                            printf '((++o_%s))\n' ${option[long]//-/_}
                            ;;
                        toggle )
                            printf 'o_%s=$(( ! o_%s ))\n' ${option[long]//-/_} ${option[long]//-/_}
                            ;;
                    esac
                    stack[$top]=0
                    state=execute
                    continue
                    ;;
                execute:0 )
                    if (( $option[execute] )); then
                        printf '%s %s %s %s\n' $error $funcstack[$depth] execute "--$option[long]"
                    fi
                    truth=1
                    state=switch
                    ((top--))
                    continue
                    ;;
                * )
                    print derp
                    exit 1
                    ;;
            esac
            case $option[kind] in
                boolean | counter | toggle )
                    ((top++))
                    stack[$top]=$(( truth ))
                    state=value
                    ;;
                map )
                    state=key
                    ;;
                * )
                    state=value
                    ;;
            esac
        done
        for flag in ${(@k)missing}; do
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

function required {
    #parser error -b a,alfa -s b,bravo -a c,charlie -c d,delta -A f,foxtrot -- "$@"
    parser error 2 -sr a,alfa -br c,charlie -Ar b,bravo -- "$@"
}

function strict {
    #parser error -b a,alfa -s b,bravo -a c,charlie -c d,delta -A f,foxtrot -- "$@"
    parser error 2 -bx h,help -s a,alfa -A b,bravo -- "$@"
}

function sprinkle {
    #parser error -b a,alfa -s b,bravo -a c,charlie -c d,delta -A f,foxtrot -- "$@"
    typeset o_negate=1 o_foxtrot=foxtrot
    parser error 2 -@ -bx h,help -db! n,negate -s a,alfa -d f,foxtrot -A b,bravo -b c,charlie ,delta -a e,echo -t g,golf -c v,verbose -- "$@"
}

function {
    [[ $1 == 'toplevel' ]] || return
    required -ahello -c -b key=value
    print -- --
    required --alfa hello --charlie --bravo key=value
    print -- --
    required --charlie --bravo key=value
    print -- --
    sprinkle --verbose -vvv
    print -- --
    sprinkle -g --golf
    print -- --
    sprinkle --negate
    print -- ---
    sprinkle --no-negate
    print -- ---
    sprinkle -n
    print -- ---
    sprinkle -!n
    print -- ---
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
    print -- --
    sprinkle bar -e hello --ec world
    print -- --
    sprinkle --verbose
    print -- --
    sprinkle --alfa=hello
} $ZSH_EVAL_CONTEXT
