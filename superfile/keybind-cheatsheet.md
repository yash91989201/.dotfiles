# Superfile Vim Keybind Cheat Sheet

## Navigation

| Key                     | Action                       |
| ----------------------- | ---------------------------- |
| `j` / `↓`               | Move down                    |
| `k` / `↑`               | Move up                      |
| `h` / `←` / `Backspace` | Go to parent directory       |
| `l` / `→` / `Enter`     | Open file or directory       |
| `Ctrl+u` / `Page Up`    | Move one page up             |
| `Ctrl+d` / `Page Down`  | Move one page down           |
| `/`                     | Search the current directory |

## File Operations

| Key | Action                            |
| --- | --------------------------------- |
| `a` | Create a file or directory        |
| `r` | Rename the selected item          |
| `y` | Copy selected items               |
| `x` | Cut selected items                |
| `p` | Paste items                       |
| `d` | Move selected items to trash      |
| `D` | Permanently delete selected items |
| `Y` | Copy the selected item path       |
| `c` | Copy the current directory path   |

## Selection

| Key   | Action                                |
| ----- | ------------------------------------- |
| `v`   | Toggle selection mode                 |
| `J`   | Select the current item and move down |
| `K`   | Select the current item and move up   |
| `A`   | Select all items                      |
| `Esc` | Cancel or exit the current action     |

### Copy Multiple Files

```text
v → j → j → j → y → navigate to destination → p
```

Alternatively:

```text
J → J → J → y → navigate to destination → p
```

## Editor

| Key | Action                                    |
| --- | ----------------------------------------- |
| `e` | Open the selected file in your editor     |
| `E` | Open the current directory in your editor |

## File Panels

| Key         | Action                       |
| ----------- | ---------------------------- |
| `n`         | Create a new file panel      |
| `q`         | Close the current file panel |
| `Tab`       | Move to the next panel       |
| `Shift+Tab` | Move to the previous panel   |
| `N`         | Split the current panel      |

## Panel Focus

| Key | Action                   |
| --- | ------------------------ |
| `S` | Focus the sidebar        |
| `M` | Focus the metadata panel |
| `B` | Focus the process panel  |

## View and Sorting

| Key | Action                         |
| --- | ------------------------------ |
| `f` | Toggle file preview            |
| `.` | Show or hide hidden files      |
| `o` | Open sorting options           |
| `R` | Reverse the current sort order |
| `P` | Open pinned directories        |
| `F` | Toggle the footer              |

## Commands and Utilities

| Key | Action                    |
| --- | ------------------------- |
| `:` | Open the command line     |
| `>` | Open the Superfile prompt |
| `z` | Open Zoxide navigation    |
| `C` | Compress selected items   |
| `X` | Extract an archive        |
| `?` | Open the help menu        |

## Exit

| Key      | Action                                        |
| -------- | --------------------------------------------- |
| `q`      | Close the current panel                       |
| `Ctrl+c` | Exit Superfile                                |
| `Q`      | Exit Superfile and change the shell directory |

## Essential Keys

```text
h j k l    Navigate
a          Create
r          Rename
v          Selection mode
y          Copy
x          Cut
p          Paste
d          Move to trash
D          Permanently delete
e          Edit selected file
E          Open directory in editor
Tab        Switch panels
.          Toggle hidden files
/          Search
q          Close panel
Ctrl+c     Quit Superfile
```
