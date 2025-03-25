
function splat:parse {
    typeset arguments=() stack=( "${(@Oa)@}" )
    typeset -A options=( dashes -- kind scalar separator = scalar scalar )
    typeset -A control=( prefix o_ quote 0 delimiter : outcome execute )
    typeset top=${#stack} popped state=boot flag value arg reset reflag=1
    while (( top )); do
        popped=$stack[$top]
        case $state:$popped in
            arg:* )
                : ${(P)arg::=$popped}
                state=$reset arg=
                ((top--))
                ;;
            boot:-* )
                case $popped in
                    -q* )
                        control[outcome]=quote
                        ;;
                    -i* )
                        control[outcome]=intermediate
                        ;;
                    -x* )
                        control[outcome]=execute
                        ;;
                    -d* )
                        control[delimiter]=$popped[3,-1]
                        arg=control[delimiter]
                        reflag=0
                        ;;
                    -e* )
                        state=user
                        arguments+=( @$control[outcome] )
                        ;;
                    * )
                        printf 'splat: unknown global switch %s.\n' ${(qqq)popped[1,2]}
                        ;;
                esac
                if [[ -n $arg ]]; then
                    reset=$state state=arg
                fi
                if (( ${#popped} > 2 )); then
                    if (( reflag )); then
                        stack[$top]="-${popped[3,-1]}"
                    else
                        stack[$top]="${popped[3,-1]}"
                        reflag=1
                    fi
                else
                    ((top--))
                fi
                ;;
            boot:* )
                state=user
                arguments+=( @$control[outcome] )
                arguments+=( @literal @$popped )
                ((top--))
                ;;
            user:$control[delimiter] )
                state=splat
                ((top--))
                ;;
            user:* )
                arguments+=( @literal @$popped )
                ((top--))
                ;;
            pluck:* )
                arguments+=( @association @pluck association $popped )
                state=splat
                ((top--))
                ;;
            verbatim:* )
                arguments+=( @literal @$popped )
                state=splat
                ((top--))
                ;;
            splat:-- )
                state=slurp
                ((top--))
                ;;
            splat:$control[delimiter] )
                state=user
                ((top--))
                ;;
            splat:-* )
                case $popped in
                    -A* )
                        options[kind]=association
                        ;;
                    -c* )
                        options[kind]=count
                        ;;
                    -!* )
                        options[kind]=negatable
                        ;;
                    -m* )
                        state=pluck
                        options[scalar]=key
                        ;;
                    -M* )
                        options[scalar]=scalar
                        ;;
                    -a* )
                        options[kind]=array
                        options[scalar]=scalar
                        ;;
                    -b* )
                        options[kind]=boolean
                        ;;
                    -s* )
                        options[kind]=scalar
                        ;;
                    -v* )
                        state=verbatim
                        reflag=0
                        ;;
                    -=* )
                        options[separator]==
                        ;;
                    -_* )
                        options[separator]=' '
                        ;;
                    -+* )
                        options[separator]=''
                        ;;
                    -[0-2]* )
                        # https://unix.stackexchange.com/questions/675237/repeat-char-n-times-in-zsh-prompt
                        options[dashes]=${(l:${popped[2,2]}::-:)}
                        ;;
                esac
                if (( ${#popped} > 2 )); then
                    if (( reflag )); then
                        stack[$top]="-${popped[3,-1]}"
                    else
                        stack[$top]=${popped[3,-1]}
                        reflag=1
                    fi
                else
                    ((top--))
                fi
                ;;
            splat:*=* )
                flag=${popped%%=*} value=${popped#*=}
                case $options[kind] in
                    # For arrays the value comes last so we can loop through
                    # the tape and print the array instead of having to build
                    # an array first.
                    array )
                        arguments+=( @array @${options[dashes]}$flag @$options[separator] array $value )
                        ((top--))
                        ;;
                    # We always build the association for the sake of plucking
                    # when we could just loop through for flattening.
                    association )
                        arguments+=( @association @flatten @${options[dashes]}$flag @$options[separator] association $value )
                        ((top--))
                        ;;
                    # All of these have the value at the same place in front
                    # so we can have one case statement to pluck scalar
                    # values.
                    boolean | count )
                        arguments+=( @$options[kind] $options[scalar] $value @${options[dashes]}${flag} )
                        ((top--))
                        ;;
                    negatable )
                        arguments+=( @$options[kind] $options[scalar] $value @${options[dashes]}${flag} @${options[dashes]}no-${flag} )
                        ((top--))
                        ;;
                    scalar )
                        arguments+=( @scalar $options[scalar] $value @${options[dashes]}$flag @$options[separator])
                        ((top--))
                        ;;
                esac
                ;;
            splat:* )
                flag=$popped
                stack[$top]=${flag#$control[prefix]}=$flag
                ;;
            slurp:* )
                arguments+=( @literal @$popped )
                ((top--))
                ;;
        esac
    done
    print -- "${(qq@)arguments}"
}

function splat:association {
    typeset key value
    printf -- ' %s' $operation $(( $# / 2 ))
    for key value in "$@"; do
        printf -- ' %s %s' ${(qq)key} ${(qq)value}
    done
}

function splat:array {
    typeset item
    printf -- ' %s' $#
    for item in "$@"; do
        printf -- ' %s' ${(qq)item}
    done
}

function splat:expand {
    while (( $# )); do
        case $1 in
            association | array | scalar )
                if [[ ! -v $2 ]]; then
                    printf 'splat: variable %s is not defined' ${(qqq)2} 1>&2
                    printf ' error'
                    return
                fi
                ;;
        esac
        case $1 in
            association )
                case ${(t)${(P)2}} in
                    association* )
                        splat:association "${(@kv)${(P)2}}"
                        shift 2
                        ;;
                    array* )
                        if (( ${#${(P)3}} % 2 )); then
                            printf 'splat: bad set of key/value pairs for associative array %s.' ${(qqq)${2[2,-1]}} 1>&2
                            printf ' error'
                            return
                        fi
                        splat:association $3 "${(@)${(P)2}}"
                        ;;
                    * )
                        printf 'splat: not an associative array %s.' ${(qqq)${2[2,-1]}} 1>&2
                        ;;
                esac
                ;;
            array )
                if [[ ${(t)${(P)2}} != array* ]]; then
                    printf 'splat: not an array %s.' ${(qqq)${2[2,-1]}} 1>&2
                    printf ' error'
                    return
                fi
                splat:array "${(@PA)2}"
                shift 2
                ;;
            key )
                printf -- ' %s %s' $1 $2
                shift 2
                ;;
            scalar )
                printf -- ' value %s' "${(qq)${(P)2}}"
                shift 2
                ;;
            * )
                printf -- ' %s' "${(qq)1[2,-1]}"
                shift
                ;;
        esac
    done
    printf -- ' good'
}

function splat {
    set -- "${(@QA)${(z)$(splat:expand "${(@QA)${(z)$(splat:parse "$@")}}")}}"
    typeset outcome=$1
    shift
    if [[ $outcome = intermediate ]]; then
        print -r "${(qq)@}"
        return
    fi
    if [[ $@[-1] = error ]]; then
        return 1
    fi
    typeset popped arguments=() separator flag value
    typeset -A association=()
    integer count
    while (( $# != 1 )); do
        popped=$1
        shift
        case $popped in
            boolean | count | negatable | scalar )
                case $1 in
                    key )
                        value=$association[$2]
                        ;;
                    value )
                        value=$2
                        ;;
                esac
                ;;
        esac
        case $popped in
            array )
                flag=$1 separator=$2 count=$3
                shift 3
                while (( count-- )); do
                    case $separator in
                        ' ' )
                            arguments+=( $flag "$1" )
                            ;;
                        * )
                            arguments+=( $flag$separator$1 )
                            ;;
                    esac
                    shift
                done
                ;;
            association )
                case $1 in
                    pluck )
                        shift
                        count=$1
                        shift
                        while (( count-- )); do
                            association+=( $1 "$2" )
                            shift 2
                        done
                        ;;
                    flatten )
                        shift
                        flag=$1 separator=$2 count=$3
                        shift 3
                        while (( count-- )); do
                            case $separator in
                                ' ' )
                                    arguments+=( "$flag" $1 "$2" )
                                    ;;
                                * )
                                    arguments+=( "$flag" "$1$separator$2" )
                                    ;;
                            esac
                            shift 2
                        done
                        ;;
                esac
                ;;
            boolean )
                if (( value )); then
                    arguments+=( $3 )
                fi
                shift 3
                ;;
            count )
                while (( value-- )); do
                    arguments+=( $3 )
                done
                shift 3
                ;;
            literal )
                arguments+=( "$1" )
                shift
                ;;
            negatable )
                if (( value )); then
                    arguments+=( $3 )
                else
                    arguments+=( $4 )
                fi
                shift 4
                ;;
            scalar )
                case $4 in
                    ' ' )
                        arguments+=( $3 "$value" )
                        ;;
                    * )
                        arguments+=( $3$4$value )
                        ;;
                esac
                shift 4
                ;;
        esac
    done
    if [[ $outcome = quote ]]; then
        typeset words=()
        if (( ${#arguments} )); then
            for arg in "${(@)arguments}"; do
                printf -v arg '%q' "$arg"
                words+=( $arg )
            done
            printf '%s\n' ${(j: :)words}
        else
            print
        fi
    else
        "${(@)arguments}"
    fi
}

function {
    [[ $1 = toplevel ]] || return
    typeset o_fqn=1
    splat -q print -r -- true : -b o_fqn
    o_fqn=0
    splat -q print -r -- false : -b o_fqn
    o_fqn=1
    splat -q print -r -- terminate : -b o_fqn -- :
    splat -q print -r -- scalar : o_fqn
    splat -q print -r -- rename : foo=o_fqn
    typeset o_task=finally
    splat -q print -r -- equals/space : -= fqn=o_fqn -_ o_task
    splat -qd++ print -r -- delimited ++ -= fqn=o_fqn -_ o_task
    splat -qd ++ print -r -- delimited ++ -= fqn=o_fqn -_ o_task
    splat -q print -r -- short : -1+ t=o_task -b b=o_fqn
    splat -qe print -r -- evaluate : o_task -b o_fqn
    typeset o_array=( alfa bravo charlie )
    splat -q print -r -- array : -a o_array
    typeset -A o_kubernetes=( cluster cluster-foo hostname cluster.foo.com ready 1 other '' )
    splat -q print -r -- map : -m o_kubernetes cluster hostname missing -b ready -Mb o_fqn
    integer o_count=3
    splat -q print -r -- count : -c o_count
    o_fqn=1
    splat -q print -r -- negatable : -! o_fqn
    splat -q print -r -- : -0 -v -o o_task
    splat -q print -r -- : -0 -v-o o_task -b2 o_fqn
    splat -q print -r -- : -A o_kubernetes -b o_fqn
    typeset o_spaced='hello world'
    splat -q print -r -- : o_spaced
    typeset o_empty=
    splat -q print -r -- : -_ o_empty
    typeset -A param
    splat -q print -r -- : -A param
} $ZSH_EVAL_CONTEXT
