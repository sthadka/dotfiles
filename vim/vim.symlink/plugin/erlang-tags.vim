" Generate erlang tags
" http://www.reddit.com/r/vim/comments/cve43/how_to_generate_tags_file_for_use_in_erlang/

let g:erlang_tags_file = $HOME . '/.vim/erlang_tags'

command! -nargs=+ -complete=file ErlangUpdateTags call s:ErlangUpdateTags(<q-args>)

function! s:ErlangUpdateTags(files_to_scan)
  " Read existing tags.
  let tags = []
  if filereadable(g:erlang_tags_file)
    let tags = readfile(g:erlang_tags_file)
    call map(tags, 'split(v:val, "\t")')
  endif
  " Scan for new/changed tags.
  for fname in split(expand(a:files_to_scan), "\n")
    redraw | echo "Scanning" fname
    let fname = fnamemodify(fname, ':p')
    " Filter existing tags for this file (avoid duplicate/outdated tags).
    call filter(tags, 'v:val[1] != fname')
    let lines = readfile(fname)
    " Find the module name.
    let modpat = '-module(\zs[^)]\+\ze)'
    let i = match(lines, modpat)
    let module = i >= 0 ? matchstr(lines[i], modpat) : ''
    " Now scan for function definitions.
    let funpat = '^\<\w\+\ze([^)]*).*[->]\?'
    let lnum = 1
    for line in lines
      let name = matchstr(line, funpat)
      if name != ''
        if module != ''
          let name = module . ':' . name
        endif
        call add(tags, [name, fname, '/' . escape(line, '/') . '/'])
      endif
      let lnum += 1
    endfor
  endfor
  " Write the results.
  call map(tags, 'join(v:val, "\t")')
  call writefile(tags, g:erlang_tags_file)
  execute 'silent ! sort' g:erlang_tags_file ' -o ' g:erlang_tags_file
  redraw | echomsg "Saved" len(tags) "tags to" g:erlang_tags_file
endfunction
