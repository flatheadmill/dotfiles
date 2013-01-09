alias hideme='history -d $((HISTCMD-1))'
alias hideprev='history -d $((HISTCMD-2)) && history -d $((HISTCMD-1))'

function hidegrep()
{
  if [ ! -z "$1" ]; then
    while true; do
      hist=$(history | grep -e "$1" | head -n 1)
      if [ -z "$hist" ]; then break; fi
      echo $hist
      history -d $(echo $hist | awk '{ print $1 }' | sed 's/[^0-9]//g')
    done
  fi
}

# Launch screen with a name name and a fresh bash login.
function scn ()
{
    screen -t $1 zsh -l
}
