<p align=center><strong>A minimal bookmarks plugin for Neovim</strong></p> 
<br/>
<img src="https://github.com/yuriescl/minimal-bookmarks.nvim/assets/26092447/182bceb7-2fb3-4045-99c9-614bd7716e76" />

## Summary
- [Features](#features)
- [Installation](#installation)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [How to edit bookmarks](#how-to-edit-bookmarks)
- [Screenshots](#screenshots)
- [FAQ](#faq)

### Features

- Written in Lua as a very small file (~260 lines) with no dependencies
- Bookmark current line
- Edit bookmarks as a file
    - Bookmarks are stored in a single file located at ` ~/.cache/nvim/minimal_bookmarks/database`
- Toggle bookmarks window

### Installation

#### Plugin Manager

Using [vim-plug](https://github.com/junegunn/vim-plug):

_Vimscript_:
```
call plug#begin()
...
Plug 'yuriescl/minimal-bookmarks.nvim'
...
call plug#end()
```

_Lua_:
```
vim.call('plug#begin')
...
Plug('yuriescl/minimal-bookmarks.nvim')
...
vim.call('plug#end')
```

For installation instructions using other plugin managers (e.g. [packer.nvim](https://github.com/wbthomason/packer.nvim), [lazy.nvim](https://github.com/folke/lazy.nvim)), consult your plugin manager documentation.

#### Commands

Available commands:
- `:MinimalBookmarksToggle`: Toggle bookmarks window
- `:MinimalBookmarksAdd`: Add current line to bookmarks
- `:MinimalBookmarksEdit`: Edit bookmarks file (this is the only way to edit bookmarks)
- `:MinimalBookmarksShow`: Show bookmarks window
- `:MinimalBookmarksHide`: Hide bookmarks window

#### Keybindings

By default, this plugin does not create keybindings. You can set your own keybindings in your `init.vim` or `init.lua` file.

Examples:

_Vimscript_:
```
nnoremap <silent> <leader>bb :MinimalBookmarksToggle<CR>
nnoremap <silent> <leader>be :MinimalBookmarksEdit<CR>
nnoremap <silent> <leader>ba :MinimalBookmarksAdd<CR>
```

_Lua_:
```
vim.api.nvim_set_keymap('n', '<leader>bb', ':MinimalBookmarksToggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>be', ':MinimalBookmarksEdit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ba', ':MinimalBookmarksAdd<CR>', { noremap = true, silent = true })
```

### How to edit bookmarks

Run `:MinimalBookmarksEdit` to open the bookmarks file.  
The file is located at `~/.cache/nvim/minimal_bookmarks/database`.  

You can freely edit the file, but be careful not to break the format. The format is simple: each line is a bookmark, and each line has the format:
```
{line_number}|{name}|{file_path}|{a part of the original line content}
```

Example of a bookmark entry in the file:
```
13|location1|/home/yuri/.config/nvim/init.lua|vim.cmd([[
```

### Screenshots

Bookmarks window (press Enter in a bookmark to jump to it):

![image](https://github.com/yuriescl/minimal-bookmarks.nvim/assets/26092447/182bceb7-2fb3-4045-99c9-614bd7716e76)

Bookmarks file (freely edit the bookmarks database - it's a normal text file):

![image](https://github.com/yuriescl/minimal-bookmarks.nvim/assets/26092447/e037cca3-dbb9-4d15-9807-9314304fc0c6)


### FAQ

- Why not just use existing bookmark plugins like [vim-bookmarks](https://github.com/MattesGroeger/vim-bookmarks) or [bookmarks.nvim](https://github.com/tomasky/bookmarks.nvim)?
    - I tried them but found them difficult to configure, buggy and a bit bloated with unnecessary features. I just wanted something for quickly jumping to specific lines in my files. Searched for a plugin that does this, didn't find, so I wrote this one.

- Why aren't there more features?
    - With the goal of keeping this plugin minimalistic (therefore less prone to bugs, and less prone to unpredictable behavior), I decided to **not** include additional features like:
        - Per-directory bookmarks
        - Edit bookmarks inside bookmarks window
        - Line marks (e.g. bookmark sign on the line)
        - Bookmark tracking (e.g. track if bookmarked line goes up or down due to a file content change)
