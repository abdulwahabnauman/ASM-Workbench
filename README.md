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
│   └── Assignment03/
│       ├── 01_initial_view.png
│       ├── 02_after_scroll.png
│       └── 03_end_of_document.png
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






