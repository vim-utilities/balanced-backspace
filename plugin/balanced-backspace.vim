#!/usr/bin/env vim
" balanced-quotes.vim - Attempts to balance removal of quotes and braces
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" License: AGPL-3.0
" Version: 0.0.1


if exists('g:balanced_backspace__loaded') || v:version < 700
  finish
endif
let g:balanced_backspace__loaded = 1


""
" Type Definition: {dictionary} define__configurations_entry
" Property: {string} input - Character from keyboard input
" Property: {string} open - Opening brace/peren
" Property: {string} close - Closing brace/peren


""
" Type Definition: {dictionary} define__configurations
" [key: string]: define__configurations_entry


""
" Merged dictionaries without mutation
" Parameter: {dict} defaults - Dictionary of default key/value pares
" Parameter: {...dict[]} override - Up to 20 dictionaries to merge into return
" Return: {dict}
" See: {docs} :help type()
" See: {link} https://vi.stackexchange.com/questions/20842/how-can-i-merge-two-dictionaries-in-vim
function s:Dict_Merge(defaults, ...) abort
  let l:new = copy(a:defaults)
  if a:0 == 0
    return l:new
  endif

  for l:override in a:000
    for [l:key, l:value] in items(l:override)
      if type(l:value) == type({}) && type(get(l:new, l:key)) == type({})
        let l:new[l:key] = s:Dict_Merge(l:new[l:key], l:value)
      else
        let l:new[l:key] = l:value
      endif
    endfor
  endfor

  return l:new
endfunction


""
" Registers Insert mode re-mapping
" See: {docs} :help :map-<buffer>
" function! s:Register_Insert_Remapping(configurations_entry) abort
function! s:Register_Insert_Remapping() abort
  let l:exclude_file_types = get(g:balanced_backspace, 'exclude', [])
  if count(l:exclude_file_types, &filetype)
    return
  endif

  let l:configure_filetype = get(g:balanced_backspace, &filetype, {})
  let l:configure_filetype = s:Dict_Merge(g:balanced_backspace['all'], l:configure_filetype)

  let b:balanced_backspace__normalized_configs = []
  for [l:name, l:config] in items(l:configure_filetype)
    if type(l:config) != type({})
      continue
    endif

    let l:open = l:config['open']
    let l:close = get(l:config, 'close', l:config['open'])
    call add(b:balanced_backspace__normalized_configs, { 'open': l:open, 'close': l:close })
  endfor

  if len(b:balanced_backspace__normalized_configs)
    inoremap <buffer> <expr> <BS> Balanced_Backspace()
  endif
endfunction


""
" Parses `b:balanced_backspace__normalized_configs` every time `<BS>` is pressed
function! Balanced_Backspace() abort
  let l:current_character = getline('.')[col('.') - 1]
  let l:previous_character = getline('.')[col('.') - 2]

  if len(l:previous_character) && len(l:current_character)
    for l:symbol_pares in b:balanced_backspace__normalized_configs
      if l:previous_character == l:symbol_pares['open'] && l:current_character == l:symbol_pares['close']
        return "\<BS>\<Del>"
      endif
    endfor
  endif

  return "\<BS>"
endfunction


""
" Configurations that may be overwritten
" Type: define__configurations
let s:defaults = {
      \   'exclude': [],
      \   'all': {
      \     'parentheses': { 'open': '(', 'close': ')' },
      \     'curly-brace': { 'open': '{', 'close': '}' },
      \     'square-bracket': { 'open': '[', 'close': ']' },
      \     'single-quote': { 'open': "'" },
      \     'double-quote': { 'open': '"' },
      \     'backtick': { 'open': "`" },
      \   },
      \ }


""
" See: {docs} :help fnamemodify()
" See: {docs} :help readfile()
" See: {docs} :help json_decode()
if exists('g:balanced_backspace')
  if type(g:balanced_backspace) == type('') && fnamemodify(g:balanced_backspace, ':e') == 'json'
    let g:balanced_backspace = json_decode(join(readfile(g:balanced_backspace), ''))
  endif

  if type(g:balanced_backspace) == type({})
    let g:balanced_backspace = s:Dict_Merge(s:defaults, g:balanced_backspace)
  else
    let g:balanced_backspace = s:defaults
  endif
else
  let g:balanced_backspace = s:defaults
endif


""
" Register insert remapping after &filetype is defined
autocmd BufWinEnter * :call s:Register_Insert_Remapping()

