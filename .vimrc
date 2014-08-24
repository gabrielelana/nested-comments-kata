augroup GitCommitMessage
  au!
  au BufEnter COMMIT_EDITMSG call ExpandCommitMessageTokens()
augroup End

function! ExpandCommitMessageTokens()
  let l:line_with_take_value=search('\vdiff.*\d{3}-.*$', 'n')
  if l:line_with_take_value > 0
    let l:take_value=substitute(getline(l:line_with_take_value), '\vdiff.*(\d{3}-[[:alpha:]-]+).*$', '\1', '')
    call setline(1, substitute(getline(1), '\V[TAKE]:', l:take_value . ': ', ''))
    normal 1G$
  else
    normal 1Gdd
  endif
endfunction
