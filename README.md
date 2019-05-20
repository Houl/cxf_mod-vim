# cxf_mod-vim
Restore an environment variable name after file name completion

Usage: add a mapping for i_CTRL-X_CTRL-F in your vimrc

    imap <expr> <C-X><C-F>  nwo#mappings#cxf_mod#Plug() 
