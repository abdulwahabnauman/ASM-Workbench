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

## Subroutines

All procedures take their parameters on the stack (pushed left to right, accessed through `[bp + offset]`),
keep locals at `[bp - offset]`, preserve every register they modify, and clean up the stack with `ret n`.

| Subroutine | Parameters (push order) | Returns | Cleanup | Description |
|---|---|---|---|---|
| `calculate_offset` | row, col | AX = byte offset | `ret 4` | Computes `(row*80 + col)*2`, the offset into video memory. |
| `clear_screen` | attribute | none | `ret 2` | Fills all 2000 cells with a space and the given attribute using `REP STOSW`. |
| `draw_window` | top, left, bottom, right, attribute | none | `ret 10` | Draws the double-line frame (`0xC9 0xBB 0xBA 0xCD 0xC8 0xBC`). Locals: interior width, current row. |
| `printString` | row, col, string, attribute | AX = next free column | `ret 8` | Prints a 0-terminated string with `LODSB`/`STOSW`. Local: length counter. |
| `printNum` | row, col, number, attribute | AX = next free column | `ret 8` | Prints an unsigned integer. It divides by 10, pushes the digits on the stack, then pops them most significant digit first. Locals: digits left, digits printed. |
| `stream_text` | firstRow, lastRow, left, right, textPtr, attribute | AX = pointer to next unread text | `ret 12` | Streams lines from the document buffer into the window. Long lines wrap, and `0xFF` marks the end of the document. Locals: current row, usable width. |
| `scroll_window_up` | top, left, bottom, right, n | none | `ret 10` | Moves interior rows up by `n` with `REP MOVSW` (row-stride offsets via `calculate_offset`) and blanks the bottom `n` rows with `REP STOSW`. `n` is clamped to the interior height. Locals: interior width/height, clamped n, current row, row counter. |
| `find_and_highlight` | top, left, bottom, right, pattern, attribute | AX = match count | `ret 12` | Copies each interior row's characters into an 80-byte stack buffer, then scans it using `SCASB` (first character) and `REPE CMPSB` (rest of the pattern). Each match overwrites only the attribute bytes in video memory. Locals: match count, current row, interior width, pattern length, scan position, row buffer. |
| `draw_status` | count | none | `ret 2` | Builds the row-23 status bar using `printString` and `printNum`. Local: next free column. |
| `delay` | n | none | `ret 2` | Busy-wait loop so the scrolling is visible. |
| `refresh` | none | none | `ret` | Helper that calls `find_and_highlight` and then `draw_status` for the current view. It is called after every scroll. |





