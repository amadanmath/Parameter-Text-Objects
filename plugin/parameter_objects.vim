" A Vim plugin that defines a parameter text object.
" Maintainer: David Larson <david@thesilverstream.com>
" Last Change: Mar 30, 2011
"
" This script defines a parameter text object. A parameter is the text between
" parentheses or commas, typically found in a function's argument list.
"
" See:
" :help text-objects
"   for a description of what can be done with text objects.
" Also See:
" :help a(
"   If you want to operate on the parentheses also.
"
" Like all the other text-objects, a parameter text object can be selected
" following these commands: 'd', 'c', 'y', 'v', etc. The script defines these
" operator mappings:
"
"    aP    "a parameter", select a parameter, including the preceding comma
"          (if there is one).
"
"    iP    "inner parameter", select a parameter, not including commas.
"
" If you would like to remap the commands then you can prevent the default
" mappings from getting set if you set g:no_parameter_object_maps = 1 in your
" .vimrc file. Then remap the commands as desired, like this:
"
"    let g:no_parameter_object_maps = 1
"    vmap     <silent> ia <Plug>ParameterObjectI
"    omap     <silent> ia <Plug>ParameterObjectI
"    vmap     <silent> aa <Plug>ParameterObjectA
"    omap     <silent> aa <Plug>ParameterObjectA
"
" By default, aP on the first parameter will not include a comma. This
" will make it behave just like iP in this special case.
"
" The behaviour in the previous version of this plugin was that aP must
" always capture at least one comma: in this way, if you delete a
" parameter, you will always end up with correct code (i.e. no extra
" commas). However, this is inconsistent with the behaviour of aP in
" non-first parameters in that the comma is sometimes at the beginning
" of the text-object (non-first parameters), and sometimes at the end
" (first parameters). This behaviour can be switched on by setting
" g:parameter_objects_force_comma.

if exists("loaded_parameter_objects") || &cp || v:version < 701
  finish
endif
let loaded_parameter_objects = 1

if !exists("g:no_parameter_object_maps") || !g:no_parameter_object_maps
   vmap     <silent> iP <Plug>ParameterObjectI
   omap     <silent> iP <Plug>ParameterObjectI
   vmap     <silent> aP <Plug>ParameterObjectA
   omap     <silent> aP <Plug>ParameterObjectA
endif
vnoremap <silent> <script> <Plug>ParameterObjectI :<C-U>call <SID>parameter_object("i")<cr>
onoremap <silent> <script> <Plug>ParameterObjectI :call <SID>parameter_object("i")<cr>
vnoremap <silent> <script> <Plug>ParameterObjectA :<C-U>call <SID>parameter_object("a")<cr>
onoremap <silent> <script> <Plug>ParameterObjectA :call <SID>parameter_object("a")<cr>

function s:parameter_object(mode)
   let c = v:count1
   let ve_save = &ve
   set virtualedit=onemore
   let orig_line = line(".")
   let orig_col = col(".")
   let ok = 0
   let need_comma = exists("g:parameter_objects_force_comma") && g:parameter_objects_force_comma
   try
      " if on closing paren, move to the opening one - do the outer scope
      let char = getline('.')[getpos('.')[2] - 1]
      if char == ')' || char == '}' || char == ']'
        normal! %
      endif

      " Comma belongs to the next parameter
      if char == ','
        let c_opt = 'c'
      else
        let c_opt = ''
      endif

      " Search for the start of the parameter text object
      if searchpair('(\|{\|\[',',',')\|}\|\]', 'bW' . c_opt, "s:skip()") <= 0
         return
      endif

      let char = getline('.')[getpos('.')[2] - 1]
      if a:mode == "a" && char == ','
         " don't skip the initial comma
         let need_comma = 0
         let c_opt = ''
      else
         " skip the possible initial comma and spaces
         if search('\S', 'W') <= 0
            return
         endif
         let c_opt = 'c'
      endif
      let start_line = line(".")
      let start_col = col(".")

      while c
         " Search for the end of the parameter text object
         if searchpair('(\|{\|\[',',',')\|}\|\]', 'W' . c_opt, "s:skip()") <= 0
            return
         endif
         let c_opt = ''
         let char = getline('.')[getpos('.')[2] - 1]
         if (char == ')' || char == '}' || char == ']') && c > 1
            " found the last parameter when more is asked for, so abort
            return
         endif
         let c -= 1
      endwhile

      " if the first parameter and g:parameter_objects_force_comma is on,
      " add the trailing comma and spaces
      if a:mode == "a" && char == ',' && need_comma
         if search('\S', 'W') <= 0
            return
         endif
      endif
      normal! hv
      execute start_line . "normal! " . start_col . "|"
      let ok = 1
   finally
      let &ve = ve_save
      if !ok
         execute orig_line . "normal! " . orig_col . "|"
      endif
   endtry
endfunction
function s:skip()
   let name = synIDattr(synID(line("."), col("."), 0), "name")
   if name =~? "comment"
      return 1
   elseif name =~? "string"
      return 1
   endif
   return 0
endfunction

" vim:fdm=marker fmr=function\ ,endfunction
