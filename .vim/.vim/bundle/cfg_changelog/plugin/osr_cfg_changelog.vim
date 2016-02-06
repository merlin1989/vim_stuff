"vim plugin to write a changelog on osr cfg changes
"most of the stuff is stolen <-- 03.12.2014 now not anymore ;)
"modified by Mathias Enzensberger to fit needs (changelog writing and not only
"patching or diffs)
"
"!adaptation in ~/.vimrc --> autocmd BufWrite *cfg.py :DiffChanges 
"
"Changelog:
"	 1.0 initial creation
"	 1.1 dirty hack to append in vim < 7.3.150 because it's a silly piece of shit that doesn't know about "a" as append
"	     added regex for osrid (now it doesn't matter anymore if the path contains trunk or branch)
"	 1.2 add username (if defined by ip in hosts file) to changelog, if not defined add ip (not finished yet)
"	 1.3 added a check if the changelog file already exists, if not create it
"	 1.4 fixed previous added check (it wrote the whole file to the changelog at first save)
"	     fixed bugs Anton found
"	     added the path to the changelog file
"	     added .no_id instead of an empyt string in case cfg file is anywhere on the system

if exists("g:diffchanges_loaded")
    finish
endif

let g:diffchanges_loaded = 1

let g:diffchanges_diff = []
let g:diffchanges_patch = []
let s:diffchanges_modes = ['diff', 'patch']

if !exists('g:diffchanges_patch_cmd')
    let g:diffchanges_patch_cmd = 'diff -u'
endif

let s:save_cpo = &cpo
set cpo&vim

function g:GetUser() "{{{1
    let g:userid = matchstr($SSH_CONNECTION, '^\S*')
    return g:userid
endfunction

function! g:OsrId() "{{{1
    let g:osrid = expand('%:p')
    let g:osrid = matchstr(g:osrid, 'osr\w')
    ""echom g:osrid
    if g:osrid  !~? 'osr\d'
       let g:osrid = 'no_id'
    endif
    return g:osrid
endfunction

command! -bar -complete=file -nargs=? DiffChanges :call s:DiffChanges(<q-args>)
command! -bar DiffChangesDiffToggle :call s:DiffChangesToggle('diff')
command! -bar DiffChangesPatchToggle :call s:DiffChangesToggle('patch')
nnoremenu <script> &Plugin.&DiffChanges.&Write\ Patch  <SID>DiffChanges

function! AppendToFile(diff, filename)
  new
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
  put=a:diff
  execute 'w! >>' a:filename
  q
endfunction

function! s:GetDiff() "{{{1
    let filename = expand('%')
    let diffname = tempname()
    execute 'silent w! '.diffname
    let diff = system(g:diffchanges_patch_cmd.' '.shellescape(filename).' '.diffname)
    call delete(diffname)
    return diff
endfunction

function! s:GetPatchFilename(filename) "{{{1
    call g:OsrId()
    return '/users/osr/changelog/'.a:filename.'.changelog.'.g:osrid
endfunction

function! CheckFile()
    let filename = s:GetPatchFilename(expand('%'))
    if !empty(glob(filename))
    else
       silent execute 'w' filename
    endif
endfunction

function! s:DiffChanges(...) "{{{1
    if a:0 == 0 || len(a:1) == 0
        let filename = s:GetPatchFilename(expand('%:t'))
    else
        let filename = a:1
    endif
    let diff = s:GetDiff()
    ""echo filename
    if !empty(diff)
       call g:GetUser()
       call AppendToFile(diff, filename)
       call AppendToFile(expand('%:p'), filename)
       call AppendToFile('Last editor: '.g:userid, filename)
    endif
endfunction

function! s:DiffChangesToggle(mode) "{{{1
    if count(s:diffchanges_modes, a:mode) == 0
        call s:Warn("Invalid mode '".a:mode."'")
        return
    endif
    if len(expand('%')) == 0
        call s:Warn("Unable to show changes for unsaved buffer")
        return
    endif
    let [dcm, pair] = s:DiffChangesPair(bufnr('%'))
    if count(s:diffchanges_modes, dcm) == 0
        call s:DiffChangesOn(a:mode)
    else
        call s:DiffChangesOff()
    endif
endfunction

function! s:DiffChangesOn(mode) "{{{1
    if count(s:diffchanges_modes, a:mode) == 0
        return
    endif
    let filename = expand('%')
    let buforig = bufnr('%')
    let diff = s:GetDiff()
    call g:OsrId()
    if a:mode == 'diff'
        let b:diffchanges_savefdm = &fdm
        let b:diffchanges_savefdl = &fdl
        let save_ft=&ft
		1
        vert new
        let &ft=save_ft
        execute '0read /users/osr/changelog/'.filename.'.changelog.'.g:osrid
        1
        set buftype=nofile
        let bufname = "Changes made to '".filename."'"
    elseif a:mode == 'patch'
        below new
        setlocal filetype=diff
        setlocal foldmethod=manual
        silent 0put=diff
        1
        let bufname = s:GetPatchFilename(filename)
    endif
    silent file `=bufname`
    autocmd BufUnload <buffer> call s:DiffChangesOff()
    let bufdiff = bufnr('%')
    call add(g:diffchanges_{a:mode}, [buforig, bufdiff])
endfunction

function! s:DiffChangesOff() "{{{1
    let [dcm, pair] = s:DiffChangesPair(bufnr('%'))
    execute 'autocmd! BufUnload <buffer='.pair[1].'>'
    execute 'bdelete! '.pair[1]
    execute bufwinnr(pair[0]).'wincmd w'
    if dcm == 'diff'
        diffoff
        let &fdm = b:diffchanges_savefdm
        let &fdl = b:diffchanges_savefdl
    endif
    let dcp = g:diffchanges_{dcm}
    call remove(dcp, index(dcp, pair))
endfunction

function! s:DiffChangesPair(buf_num) "{{{1
    for dcm in s:diffchanges_modes
        let pairs = g:diffchanges_{dcm}
        for pair in pairs
            if count(pair, a:buf_num) > 0
                return [dcm, pair]
            endif
        endfor
    endfor
    return [0, 0]
endfunction

function! s:Warn(message) "{{{1
    echohl WarningMsg | echo a:message | echohl None
endfunction

function! s:Error(message) "{{{1
    echohl ErrorMsg | echo a:message | echohl None
endfunction

"}}}

let &cpo = s:save_cpo
