" Vim plugin - restore environment var name after filename completion
" General: "{{{
" File:         cxf_mod.vim
" Created:      2008 Jul 06
" Last Change:  2017 Oct 14
" Version:      0.6
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim license

" Description:
"   Modifies i_Ctrl-X_Ctrl-F (file name completion):
"
"   When i_Ctrl-X_Ctrl-F expands an environment variable, the expansion will
"   be made undone when Insert mode is left.  You can keep the path expanded
"   by leaving Insert mode with CTRL-C.
"
"   This makes sense unless there is a way to surpress the expansion at all.

" Notes:
" - uses mark 's
" - adjusts cursor position
" - will only restore one env var per Insert mode, exception: several vars
"   in sequence, for example $HOMEDRIVE$HOMEPATH
" - will not restore an env var name that is typed in after the first
"   Ctrl-X_Ctrl-F

" TODO
" - check env var name pattern and env var name chars to escape for
"   subst-repl
" - no adjust if cursor at or before env var position
" - save/restore mark s
" - cursor adjustment with multi-byte file names?  Ok, but to be tested.
" + check Ctrl-C
" + BF: no longer tries to restore a partial env var name

" History:
" 2017 Oct 14	restoring fails if C-x C-f exceeds textwidth boundary,
"		moving the filename to another line on InsertLeave
" 2016 Oct 30	moved from more\plugin to autoload, no default key
" 2015 Apr 10	ff=unix
" 2011 Mar 16	added a way to keep the path expanded

"}}}

" Init Folklore: "{{{1
" if exists("loaded_cxf_mod")
"     finish
" endif

if &cp
    echomsg "cxf_mod: 'nocompatible' required"
    finish
elseif &cpo =~# '[<C]'
    echomsg "cxf_mod: these cpo flags are evil: cpo-< cpo-C"
    " maybe some more
    finish
endif

" Mappings: {{{1
imap <Plug>(nwo-cxf-mod) <SID>CxfMod

" Internal Mappings: {{{1
inoremap <script> <SID>CxfMod <SID>SetupAu<SID>GetEnvName<C-X><C-F>
inoremap <expr> <SID>SetupAu <sid>SetupAutocmd()
inoremap <expr> <SID>GetEnvName <sid>MatchEnvVarName()

" Autocommands: {{{1
augroup cxf_mod
    " InsertLeave
augroup End

" Functions: {{{1

func! nwo#mappings#cxf_mod#Plug()
    return "\<Plug>(nwo-cxf-mod)"
endfunc

func! <sid>SetupAutocmd()
    au! cxf_mod InsertLeave * call s:CxfRestoreEnvVarName()
    " recover after Ctrl-C:
    au! cxf_mod InsertEnter * call s:CxfReset()
    return ""
endfunc

func! <sid>MatchEnvVarName()
    mark s
    let s:envvarname = matchstr(getline("'s"), '\%(\$\w\+\)\+')
    " include special case $HOMEDRIVE$HOMEPATH
    if s:envvarname != "" && exists(s:envvarname)
	inoremap <SID>CxfMod <C-X><C-F>
    endif
    return ""
endfunc

func! s:CxfReset()
    let s:envvarname = ""
    inoremap <script> <SID>CxfMod <SID>SetupAu<SID>GetEnvName<C-X><C-F>
    au! cxf_mod
endfunc

func! s:CxfRestoreEnvVarName()
    " assumptions: cursor is right from the env var position (if not on
    " another line); there is only one occurence of s:envvarname in the line
    if s:envvarname != ""
	let envvalue = expand(s:envvarname)
	let pat_envvalue = escape(envvalue, '\.*$^~[')
	let repl_varname = s:envvarname
	let oldline = getline("'s")
	if oldline !~# pat_envvalue && getline('.') =~# pat_envvalue
	    " auto-formatting moved the filename to another line (only check
	    " if the current line is the "other" line)
	    let oldline = getline('.')
	    mark s
	endif
	let oldlen = strlen(substitute(oldline,".","x","g"))
	let newline = substitute(oldline, pat_envvalue, repl_varname, '')
	let newlen = strlen(substitute(newline,".","x","g"))
	let newcol = col(".") + newlen - oldlen
	call setline("'s", newline)
	if line(".") == line("'s")
	    call cursor(".", newcol)
	    " negative newcol doesn't move the cursor, just what we want
	endif
    endif
    call s:CxfReset()
endfunc

" Success And Modeline: {{{1
let loaded_cxf_mod = 1

" vim:set ts=8 noet fdm=marker:
