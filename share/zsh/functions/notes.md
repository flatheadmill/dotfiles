## Zsh Functions

My first function is something that I'd had around for a bit as a snippet saver
script that would run a command with arguments. It was a place to put small
pipelines without having to maintain a directory of one-liner programs.

I've updated this to be a zsh function now. It loads the snippet into the zsh
history. More in the spirit of what I'm trying to accomplish. There are tasks
that I know are in my history and I want to bring them forward and into my line
editor where I adjust the last invocation of the task for the task at hand.

Running a script meant that to edit the script I'd have to edit the file in
which it is stored, so instead of using the utility I'd copy and paste the
snippet out of `~/.dotfiles/fu`. Actually, more likely, if a snippet has fallen
off the end of history on one computer I'd go to another computer and fish it
out of the history there.

That is the primary goal, to preserve history and re-run history.

Parameterization is now done with variables. I specify variables at the start of
the line for the snippet. I store them with the variables blanked out, or if the
command is destructive, I might prime the variable in such a way that the
command won't work in case I move to fast and fire it off without editing.

Thus, workflow is read in your snippet, edit the variables.

It is my hope that by reloading the pipelines into the editor it will encourage
me to write new pipelines and store them back into fu.

The name `fu` comes from the web site [commandlinefu.com](https://www.commandlinefu.com/).
Which is a snippet sharing web site. This function does not interact with that
web site in any way, however.

Near term goals for this function are to add bash completion which could list
the available snippets and then expand the parameters which it could easily
parse out of the command line so long as they where left blank.

Saving a command. Type command and history number and redirect the head to the
`~/.dotfiles/fu` file. Then edit it in the file.

```zsh
fc -l 98 > ~/.dotfiles/ru
```

Reading from the file.

```
 % history
1 ls
2 cd
 % fu echo
 % history
1 ls
2 cd
3 fu echo
4 e=; echo "$e"
```

Tasks.

 - [ ] Snippet completion based on name.
 - [ ] Snippet completion based parameters.

Rather than try to illustrate with ASCII, let's say you'd type echo and then tab
to see you had the parameter `e` and if you filled it out `e` and then a value
you would have no more parameters if you pressed tab again.

I'd also like a nicer listing when I type `fu list`, something that is
structured and indented. Adding comments to describe the snippets would be
nice to have but in a fashion that does not require the comments. Actually,
might be bad to have. Extra work. This is really supposed to be a means to
capture my own madness. Well, comment the command but let's not get to where
we're writing a JavaDoc like parser.
