# ASM-Workbench

My workbench for 16-bit **8088 assembly language** assignments (NASM + DOSBox).
Every assignment lives in its own folder; this README grows as new ones are added.

| | |
|---|---|
| **Name** | Abdul Wahab Nauman |
| **Roll No.** | 25L-0616 |
| **Course** | Computer Organization & Assembly Language |

## Assignments

| Folder | Program | Status |
|---|---|---|
| [`Assignment03/`](Assignment03) | Text Viewport Manager with Windowed Scrolling & Live Keyword Highlighter (`viewport.asm`) | In progress |

## Tools Used

* **NASM** - assembler (flat binary output, DOS `.COM`)
* **DOSBox** - DOS emulator used to run the programs
* **Git / GitHub** - version control

## Folder Structure

```
ASM-Workbench/
├── README.md
├── .gitignore
├── screenshots/
│       ├── 00_assemble_and_run.png
│       ├── 01_initial_window_with_title.png
│       ├── 02_text_streamed_before_scroll.png
│       ├── 03_after_scroll_up.png
│       └── 04_final_highlighted_status_bar.png
└── Assignment03/
    └── viewport.asm
```

Each new assignment gets its own `AssignmentNN/` folder and a matching
`screenshots/AssignmentNN/` folder.

## How to Assemble and Run 

```bash
cd Assignment03
nasm viewport.asm -o viewport.com -l viewport.lst
```

Then in DOSBox:

```
mount c C:\path\to\ASM-Workbench\Assignment03
c:
viewport.com
```

## Program Description

`viewport.asm` is a 16-bit 8088 program (DOS `.COM`, `[org 0x0100]`) that builds a
text-mode document viewer directly in video memory (segment `0xB800`, 80x25):

1. Clears the screen using `REP STOSW`.
2. Draws a double-line window (rows 3-21, columns 8-72) with a centered title (attribute `0x1E`).
3. Streams a multi-line document into the window using `LODSB`/`STOSW`, inside 2-column margins.
4. Scrolls only the window interior upward one row at a time (`REP MOVSW`), blanks the vacated row, and streams in the next line. The border and outer screen are never touched.
5. After each scroll it searches the visible text for the keyword `stack` and highlights every match (attribute `0xCE`, blinking yellow on red) without changing the characters.
6. Shows a status bar on row 23: `Total Matches Found: N | Viewport Status: ACTIVE`.
7. When the document ends, it waits for a key press and exits to DOS.






