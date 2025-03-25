`.dotfiles` of `@bigeasy`.

 * [dotfiles.github.io](https://dotfiles.github.io/)
 * [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles)

## `tmux`

To work with Unicode correctly, set iTerm2 to "Use Unicode version 9 widths."
You can find this setting by searching for in in the Preferences search.

For OS X, you now need to build a `tmux` from Homebrew.

```console
 $ brew install utf8proc
 $ brew install --build-from-source tmux --interactive
```

You'll drop into a shell. Copy the install destination that Homebrew gives you.

```console
Install to this prefix: /usr/local/Cellar/tmux/2.9a_1
 $ ./configure --enable-utf8proc --prefix=/usr/local/Cellar/tmux/2.9a_1
 $ make install
 $ exit
```

### TODO

 * Use `delta` for git diffs, install from homebrew or whereever.
 * Determine if you have any environments where installs have to be
 progressive, where you need a more-minimal install.
 * Source TMUX bit by bit.
