
function catch {
    source <({
        integer output input try tried code
        coproc {
            coproc :
            tac | tac
        }
        exec {output}>&p
        exec {input}<&p
        coproc {
            coproc :
            tac | tac
        }
        exec {try}>&p
        exec {tried}<&p
        coproc :
        "$@[3,-1]" 1>&${output} 2>&${try}
        code=$?
        exec {try}>&-
        exec {output}>&-
        IFS= read -rd '' out <&${input}
        IFS= read -rd '' err <&${tried}
        printf 'set -- %s %s %d %s %s\n' $1 $2 $code "${(qq)out}" "${(qq)err}"
    })
    : ${(P)1::=$4}
    : ${(P)2::=$5}
    return $3
}

function {
    [[ $1 == 'toplevel' ]] || return
    typeset out err
    catch out err print hello hello
    printf 'code %d, out <%s>, err <%s>\n' $? "$out" "$err"
    catch out err print -u 2 hello hello
    printf 'code %d, out <%s>, err <%s>\n' $? "$out" "$err"
    catch out err false
    printf 'code %d\n' $?
} $ZSH_EVAL_CONTEXT
