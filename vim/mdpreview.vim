" Markdown preview
" ,mp  -> toggle preview
"   inside tmux: rendered image (mdview: pandoc + chromium + sixel) in a tmux pane on the right,
"                it re-renders by itself whenever the file is saved, and scrolling it scrolls
"                this window to roughly the same place
"   otherwise:   glow in a vim terminal split (refreshed on save)
let g:md_preview_buf = -1
let g:md_preview_pane = ''
let g:md_preview_sync = ''
let g:md_preview_timer = -1
let s:md_sync_line = 0
let s:md_src_buf = -1

" mdview writes the source line at the top of the preview into g:md_preview_sync
function! s:MdSyncPoll(timer) abort
  if !filereadable(g:md_preview_sync)
    return
  endif
  let l:line = str2nr(get(readfile(g:md_preview_sync, '', 1), 0, '0'))
  if l:line == s:md_sync_line
    return
  endif
  let s:md_sync_line = l:line
  let l:win = bufwinid(s:md_src_buf)
  if l:line > 0 && l:win != -1
    call win_execute(l:win, 'keepjumps call cursor(' . l:line . ', 1) | normal! zt')
    redraw
  endif
endfunction

function! s:TmuxPaneAlive() abort
  return g:md_preview_pane != '' &&
        \ index(systemlist('tmux list-panes -a -F "#{pane_id}"'), g:md_preview_pane) >= 0
endfunction

function! s:MdPreviewClose() abort
  if g:md_preview_pane != ''
    call system('tmux kill-pane -t ' . g:md_preview_pane)
    let g:md_preview_pane = ''
  endif
  if g:md_preview_timer != -1
    call timer_stop(g:md_preview_timer)
    let g:md_preview_timer = -1
  endif
  if g:md_preview_sync != ''
    call delete(g:md_preview_sync)
    let g:md_preview_sync = ''
  endif
  if bufexists(g:md_preview_buf)
    execute 'bwipeout! ' . g:md_preview_buf
  endif
  let g:md_preview_buf = -1
endfunction

function! s:GlowOpen() abort
  let l:win = win_getid()
  if bufexists(g:md_preview_buf)
    execute 'bwipeout! ' . g:md_preview_buf
  endif
  let l:width = winwidth(0) / 2 - 2
  let g:md_preview_buf = term_start(['glow', '-s', 'dark', '-w', string(l:width), expand('%:p')],
        \ {'vertical': 1, 'term_finish': 'open', 'norestore': 1, 'term_name': 'md-preview'})
  call win_gotoid(l:win)
endfunction

function! s:MdPreviewToggle() abort
  if s:TmuxPaneAlive() || bufexists(g:md_preview_buf)
    call s:MdPreviewClose()
  elseif $TMUX != ''
    let g:md_preview_sync = tempname()
    let s:md_sync_line = 0
    let s:md_src_buf = bufnr('%')
    let g:md_preview_pane = trim(system('tmux split-window -h -d -l 50% -P -F "#{pane_id}" -e '
          \ . shellescape('MDVIEW_SYNC=' . g:md_preview_sync) . ' mdview ' . shellescape(expand('%:p'))))
    let g:md_preview_timer = timer_start(150, function('s:MdSyncPoll'), {'repeat': -1})
  else
    call s:GlowOpen()
  endif
endfunction

command! MdPreview call s:MdPreviewToggle()

augroup md_preview
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <leader>mp :MdPreview<CR>
  autocmd BufWritePost *.md,*.markdown if bufexists(g:md_preview_buf) | call s:GlowOpen() | endif
  autocmd VimLeavePre * call s:MdPreviewClose()
augroup END
