" Heredocs whose quoted delimiter carries its own indentation.
"
" The heredoc function takes blocks written as <<'        EOF' where the
" leading whitespace sits inside the quotes and the closing tag sits at the
" same indentation, so the source reads as a flowing, indented block. The
" upstream zsh syntax captures the delimiter with \S\+, which is non-whitespace
" and therefore stops at the first space — it never sees a delimiter that
" begins with indentation, so the region never starts and the body bleeds into
" surrounding code.
"
" The fix mirrors how upstream already handles <<- : skip the leading
" whitespace inside the quotes with \s*, capture only the EOF token, and close
" on ^\s*EOF\> so the closing tag matches at whatever indentation it lands. An
" exact ^\z1$ anchor that includes the captured indentation does not close
" reliably, which left the region running to the bottom of the file. Matching
" the token with a tolerant leading-whitespace anchor is both robust and true
" to the function, which dedents regardless of how deep the block is nested.
"
" This appends a region rather than patching upstream, so a change to the
" runtime zsh.vim cannot break it — it only ever adds.
syn region  zshHereDoc          matchgroup=zshRedir
                                \ start=+<\@<!<<\s*\(["']\)\s*\z(\S\+\)\1+
                                \ end='^\s*\z1\>'
                                \ contains=@Spell
