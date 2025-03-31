# When you go nuts with `coproc` you're going to find that your programs hang,
# and you're going to spend hours picking at things and purpousefully forgetting
# how pipes work. Do I need to send a terminator down the pipe or something? No,
# dum dum, when was that ever? How would anything work?
#
# Look at all the places were a file handle is inherited and immediately closed.
# One of those, the last one, too hours to find. Yes, I spend some time
# wondering if I should send an unusual line down the pipe and catch it as an
# exit in a while loop, but no, I knew that wasn't how pipes work.
#
# What you can do to find your open file handles is this.
#
# `pstree -p` will give you a process tree with PIDs. I didn't need more than
# this because I could easily see my hung process running under the Perl program
# I use to launch a program from a TMUX chord. You an use...

zmodload zsh/system 2>/dev/null

# ... to get the PID of a `coproc`. $$ will always be the PID of the parent
# shell of any subshells, but `$sysparams[pid]` will have the PID of the child.

# The problem with this was that I wanted some sort of blocky syntax for blocks
# of work in a Tekton pipeline. It didn't have to look exactly like a try/catch
# block a la C++, JavaScript, Python, etc. It just had to be easier than typing
# "or exit with this error message" on each line, it had to  boilerplate without
# variables, and it the boilerplate had to be at the start and the end of the
# block where you could easily see typos.

# With this, it can be fragile as all shell hacks are. So long as you can spot
# it by looking.

# Some things to know about shell programming to understand this code.

# What does `exec {out}>&1` do and why `exec`?
# https://stackoverflow.com/a/39881482/90123

# `coproc` notes.
# https://www.zsh.org/mla/users/1999/msg00619.html

# Pretty print just the pipes. Useful for the development of the block
# functions, and might be useful for debugging their usage. Note that, once you
# start using `coproc`, you'll always have two anonymous pipes hanging around.

#
function pipes {
    typeset split=() file long pipes=() pipe
    pushd /proc/$sysparams[pid]/fd
    {
        for file in *; do
            # The glob itself opens an fd that disappears once the glob is collected.
            [[ -e $file ]] || continue
            long=$( ls -l $file )
            # Split on spaces and reverse, `a` means index order, `O` means reverse.
            split=( ${(aO@s: :)long} )
            printf -v pipe '%2s %s' $split[3] $split[1]
            pipes+=( $pipe )
        done
    } always {
        popd
    }
    print ${(pj:\n:)pipes} | sort -nk 1,1
}

# We track file descriptors in a widely scoped `o_block` associative array. This
# is a convience function for when we want to close one, but only if it is open.

#
function tekton::close {
    typeset name=${1:-}
    integer fd=$o_block[$name]
    if (( fd )); then
        exec {fd}>&-
        o_block[$name]=0
    fi
}

# The banner starts a block and creates a subshell that we can use to indent the
# output of a series of build pipeline commands.

#
function banner {
    o_block[pids]=''
    o_block[stop]=0
    integer fd out
    # Worked on making it so that we could just close the input to terminte the
    # loop, but unlike the `indent` input, the `try` input cannot be closed
    # inside the block. Running `/bin/true {try}>&-` will prevent `/bin/true`
    # from inheriting the file handle, as will `true {try}>&-`, but in the
    # latter the file handle will be closed in the parent process because `true`
    # is a built in. Similarly, calling `zsh my_program.zsh {try}>&-` will leave
    # the handle open in the block, but calling calling `my_function {try}&>-`
    # will close it in the block. Since we are looking for one command line by
    # line, we may as well look for another.
    #
    # `while` is slow so someday we can replace with this an `awk` program.
    coproc awk '
    /^reset$/ { split("", arr) }
    /^$/ || /^ / { arr[length(arr) + 1] = $0 }
    /^end$/ {
        for (i = 1; i <= length(arr); i++) {
            print arr[i]
        }
        exit 0
    }
    '
    # Keep both the input and output.
    exec {fd}>&p; o_block[try]=$fd
    exec {fd}<&p; o_block[tried]=$fd
    # No block intender.
    o_block[sed]=0
    # Create the initial empty AWK array.
    print reset >&${o_block[try]}
    # Copy the standard output of the main process for use in the indent `coproc`.
    exec {out}>&1
    # This is our indent `coproc`.
    coproc {
        # Start a character count for our pipe.
        coproc wc -c
        # We are going to wait for our word count to finish.
        integer wc=$! count
        # Clone the output fd of the word count.
        exec {count}<&p
        # Format and print the banner.
        if (( $# )); then
            typeset message
            printf -v message "$@"
            printf '--- %s ---\n\n' $message >&$out
        else
            print -- >&$out
        fi
        # Tee into the word count, indent, and print to parent's standard out.
        tee >(>&p) | sed -ue 's/^\(..*\)$/    \1/' >&$out
        # Close the >&p and <&p of our word count `coproc`.
        coproc :
        # If we had any output at all, print a new line.
        [[ $(<&${count}) != 0 ]] && print >&$out
        # Wait for word count to finish.
        wait $wc
    }
    # We are going to wait on the indent `coproc` to finish in out `always` block.
    o_block[pid]=${!}
    # Close our duplicate of standard out.
    exec {out}>&-
    # Duplicate the input pipe of our indent `coproc`.
    exec {fd}>&p; o_block[indent]=$fd
    # Close the >&p and <&p of our indent `coproc`.
    coproc :
    # Set the DIY `try` fd to zero so we know its unallocated.
    o_block[user]=0
}

# Why all the `coproc`? Here's why. Because the path we are following most of
# the time expects that it remains in the parent process and not in a subhell.
# Functions like `try` are supposed to be transparent wrappers, but if we were
# to use the StackOverflow tricks, we'd be forking a subshell and the command
# might want to set a variable in the scope of the calling function. By
# redirecting to a subshell, the command stays in the parent process.

# Original idea...
# https://stackoverflow.com/a/59829273/90123
# ...but this means that the comand given to try runs in a subshell.

# Note that we are doing what we can to keep from shadowing the variable name
# given by the user in `try -v`, even though it will probably always be `err`
# because we are the user and that's what we like. Ergo, no `typedef` and
# sneaking some local state into `o_block`.

# When you step back an squint, the try indent `coproc` looks superflous. Why
# not just indent in the try `coproc`. The indentation is part of the line
# format is why.

#
function try {
    # TODO Wait on previous set to exit, if it exists.
    # Close the indent file handle so that a long running process like
    # `ssh-agent` does not inherit it and hold it open.
    tekton::close indent
    # Close the user `try` handle if one exists.
    tekton::close user
    # Create an indentation `coproc` to feed to our try `coproc`.
    coproc {
        coproc :
        sed -ue 's/^\(..*\)$/    \1/' >&${o_block[try]}
    }
    # We will wait for our standard error intent `coproc` to exit.
    o_block[sed]=${!}
    o_block[pids]+=" try $o_block[sed]"
    # Tell the try `coproc` to clear any error lines it's gathered.
    print reset >&${o_block[try]}
    # If called with `-v` we're going to give the user a handle to the `try`
    # coproc and trust they will do the right thing with it. Otherwise, we
    # invoke the given arguments and return the error code.
    if [[ $1 = '-v' ]]; then
        # Duplicate the standard error indent `coproc` into a variable named by
        # the user. Note how we're abusing `$1` here, which could never be a
        # variable given to `try -v`. I'm surprised it works.
        exec {1}>&p; o_block[user]=$1
        # Close the >&p and <&p of our standard error indent `coproc`.
        coproc :
        # Assign the fd to the variable given by the user.
        : ${(P)2::=$1}
    else
        {
            # Run the command and redirect the output to the standard error
            # indent `coproc`.
            "$@" 2>&p
        } always {
            # Capture the error code.
            o_block[code]=$?
            # Close the >&p and <&p of our standard error indent `coproc`.
            coproc :
        }
        # Retrun the error code.
        return $o_block[code]
    fi
}

# Called after a command has failed with an optional error message. We've
# captured the standard error of the failed command, so an error message is
# probably not necessary.

# Note that the throw comes from invalid syntax. In the inspiration thread TK
# suggests using ${:?} because it is valid syntax and invalid syntax may some
# day become valid, so this is resistent to that change. However, ${:?} will
# exit on the line where it is invoked whereas the bad syntax will propagate the
# error to a finally block.

# Inspiration. There are other try/catch Zsh hacks out there.
# https://www.zsh.org/mla/users/2005/msg00162.html

# Similiary `set -e`, which is Zsh is `setopt localoptions errexit` will exit
# immediately and `setopt localoptions errreturn` will trigger the `always`,
# but it means having to deal with `set -e` everywhere in the program.

# Thoughts on `set -e`.
# https://www.mail-archive.com/bug-bash@gnu.org/msg19497.html

# Remember that we're not trying to make a try/catch, though. We're trying to
# make a block formatter according to requirements above.

#
function tried {
    typeset message
    if (( $# )); then
        printf -v message "$@"
        o_block[abend]=$message
    fi
    # Note that `exit 1` will just exit the program immediately.
    typeset -r THROW
    THROW= 2>/dev/null
}

# Often we want to show the user that we're going to give up on a task.
# Perhaps it has already been performed, or perhaps flags indicate that
# members of a set should be skipped.

# In the case of skipping, we are probably already in a loop, so we can show
# the user using `show eval '(( skip )) && continue'`. If we are not in a
# loop, we've taken to creating a dummy loop with `while true;` so we have a
# loop to `break` from. We can't do `(( skip )) && return` since it would only
# return from the `eval` used by `show`.

# The dummy loops are making the code a little bit ugly, so now we have
# `stop`. #  `stop` will raise an error that can be caught by our `always`
# block and if the `o_block[stop]` flag is true, it will reset the
# `TRY_BLOCK_ERROR` instead of doing an `exit 1`.

# We have now changed `show` to create a function `show:eval` using `eval` and
# then invoke that function. This is because thrown errors do not propagate
# out of `eval`. So far, using `show:eval` works and when there are compile
# errors, the line numbers are correct.

#
function stop {
    o_block[stop]=1
    if (( $# )); then
        printf -v message "$@"
        printf -v message '# stopping: %s' $message
        print $message
    fi
    typeset -r THROW
    THROW= 2>/dev/null
}

#
function throw {
    # Wait on the last standard error indenter `coproc`.
    if (( $o_block[sed] )); then
        wait $o_block[sed]
    fi
    # Clear indenter pid.
    o_block[sed]=0
    # Dump the messages.
    print reset >&${o_block[try]}
    # Format the throw message.
    typeset message
    if (( $# )); then
        printf -v message "$@"
        o_block[abend]=$message
    fi
    # Note that `exit 1` will just exit the program immediately.
    typeset -r THROW
    THROW= 2>/dev/null
}

function okay {
    ! (( $TRY_BLOCK_ERROR && ! o_block[stop] ))
}

# This one contains the close that was hard to find. It is obvious now but I'd
# introduced additional nested blocks in a search for something that works.
function caught {
    # We close the handles to both sides of the try `coproc`.
    tekton::close user
    # Wait on the last standard error indenter `coproc`.
    typeset waited
    if (( $o_block[sed] )); then
        wait $o_block[sed]
        waited=$?
        # See `wait` in `man zshbuiltins`. Also,https://stackoverflow.com/a/56879673
        if (( waited )); then
            print -u 2 $waited$o_block[pids]
        fi
        o_block[sed]=0
    fi
    # We have a copy of the input to the indent `coproc`. We opened it and left
    # it open so that the `indent` program could inherit the file handle. It was
    # open for the whole block in the parent process, our process, but it is
    # time to close it now.
    print end >&${o_block[try]}
    # Close the input side of the try `coproc`.
    tekton::close try
    # Gather the last batch of error messages.
    typeset err="$(<&${o_block[tried]})"
    # Close the ouptut side of the try `coproc`.
    tekton::close tried
    # We close the handle to the standard output indent `coproc`.
    tekton::close indent
    # And we close our standard output, which is redirected to the `indent`
    # process, so now the `indent` process will have no more input to feed to
    # its copy of the input file handle and it will close it's copy of the file
    # handle.
    exec >&-
    # When that file descriptor closes and when all the output has been written
    # to the copy of standard out in the indent `coproc`, then the indent
    # `coproc` will exit. We await it's exit.
    wait $o_block[pid]
    # And now we can print an error message, if any, after all the indented
    # output from the block.
    if (( TRY_BLOCK_ERROR )); then
        if (( o_block[stop] )); then
            TRY_BLOCK_ERROR=0
        else
            if (( ${+o_block[abend]} )); then
                printf 'abend: %s\n' $o_block[abend] 1>&2
            else
                print -u 2 'abend:'
            fi
            if [[ -n $err ]]; then
                printf '\n%s\n' $err 1>&2
            fi
            exit 1
        fi
    fi
}

# The entire `always` block, the try and the catch part, get redirected to this
# function running in a process substitution subshell. When we close our
# duplicate of the fd and the `caught` function closes its file descriptor the
# standard output indent `coproc` exits.

#
function indent {
    integer indent=$o_block[indent]
    >&${indent}
    # TODO Does it work without this?
    exec {indent}>&-
}

function bad {
    integer i
    for i in {1..100}; do
        print -u 2 error
    done
    return 1
}

# Convience function, will return non-zero if any programs in a pipeline
# exited with a non-zero status.

#
function piped {
    (( ! ${#${(@)pipestatus:#0}} ))
}

function show:eval {
}

function show:compile {
    typeset code
    printf -v code 'function show:eval {
        %s
    }' $1
    eval $code 2> /dev/null
}

# TODO for variables just use heredocs.
function show {
    [[ $1 = -v ]] && {
        print -u 2 -- '-v no longer supported'
        exit 1
    }
    function {
        typeset code
        if [[ $# -eq 0 || $1 = - || $1 = -f || $1 = -q ]]; then
            heredoc -v code "$@"
            printf '$ %s' "$code"
            show:compile $code || eval "$code"
        elif [[ $1 = eval ]]; then
            printf '$ %s\n' $2
            show:compile $2 || eval "$2"
        else
            code=$({
                typeset word words=()
                for word in "$@"; do
                    if [[ -z $word || ${(q)word} = *"\\"* ]]; then
                        words+=( ${(qqq)word} )
                    else
                        words+=( $word )
                    fi
                done
                printf '%s\n' ${(j: :)words}
            })
            printf '$ %s\n' $code
            show:compile $code || eval "$code"
        fi
    } "$@" && show:eval
}

function {
    [[ $1 = toplevel ]] || return
    source ${ZSH_ARGZERO:A:h}/heredoc.zsh
    typeset -A o_block
    banner zsh
    {
        show eval '('
        print $?
    } always {
        caught
    } > >(indent)
    banner stop
    {
        show <<'        EOF'
            print called && stop finis
        EOF
        print continued
    } always {
        print catching
        okay && print okay
        caught
    } > >(indent)
    banner 'this is a banner, hello %s' world
    {
        typeset var
        print good
        try show echo 1 || tried
        { try show || tried; } <<'        EOF'
            cat <<EOF
                hello
            EOF
        EOF
        show cat <<< "Hello"
        show <<'        EOF'
            for i in {1..2}; do print $i; done
        EOF
    } always {
        caught
    } > >(indent)
    print done
    exit
    banner 'this is a banner, hello %s' world
    {
        integer err
        print good
        try -v err
        bad 2>&${err} || tried
    } always {
        caught
    } > >(indent)
    print okay
} $ZSH_EVAL_CONTEXT
