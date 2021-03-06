format PE GUI 6.0
entry start

include 'INCLUDE/win32ax.inc'

struct PROCESSENTRY32
       dwSize                  dd ?
       cntUsage                dd ?
       th32ProcessID           dd ?
       th32DefaultHeapID       dd ?
       th32ModuleID            dd ?
       cntThreads              dd ?
       th32ParentProcessID     dd ?
       pcPriClassBase          dd ?
       dwFlags                 dd ?
       szExeFile               rb MAX_PATH
ends

struct MODULEENTRY32
       dwSize                  dd ?
       th32ModuleID            dd ?
       th32ProcessID           dd ?
       GlblcntUsage            dd ?
       ProccntUsage            dd ?
       modBaseAddr             dd ?
       modBaseSize             dd ?
       hModule                 dd ?
       szModule                rb 256
       szExeFile               rb MAX_PATH
ends

struct CLIENT_ID
       UniqueProcess dd ?
       UniqueThread  dd ?
ends

struct OBJECT_ATTRIBUTES
       Length                      dd ?
       RootDirectory               dd ?
       ObjectName                  dd ?
       Attributes                  dd ?
       SecurityDescriptor          dd ?
       SecurityQualityOfService    dd ?
ends

section '.text' code executable

localPlayerOffset equ 0xD3DD14
flagsOffset equ 0x104
forceJumpOffset equ 0x51FBFA8
mouseEnableOffset equ 0xD438B8
forceJump dd 6
sleepDuration dq -1

start:
    invoke CreateToolhelp32Snapshot, 0x2, 0
    mov [snapshot], eax
    mov [processEntry.dwSize], sizeof.PROCESSENTRY32
    invoke Process32First, [snapshot], processEntry
    test eax, eax
    jz exit
    loop1:
        invoke Process32Next, [snapshot], processEntry
        test eax, eax
        jz exit
        cinvoke strcmp, <'csgo.exe', 0>, processEntry.szExeFile
        test eax, eax
        jnz loop1


    mov eax, [processEntry.th32ProcessID]
    mov [clientId.UniqueProcess], eax

    invoke CreateToolhelp32Snapshot, 0x8, eax
    mov [snapshot], eax
    mov [clientDll.dwSize], sizeof.MODULEENTRY32
    invoke Module32First, [snapshot], clientDll
    test eax, eax
    jz exit
    loop2:
        invoke Module32Next, [snapshot], clientDll
        test eax, eax
        jz exit
        cinvoke strcmp, <'client.dll', 0>, clientDll.szModule
        test eax, eax
        jnz loop2

    mov eax, [clientDll.modBaseAddr]

    mov [clientBase], eax
    mov [objectAttributes.Length], sizeof.OBJECT_ATTRIBUTES
    invoke NtOpenProcess, processHandle, PROCESS_VM_READ + PROCESS_VM_WRITE + PROCESS_VM_OPERATION, objectAttributes, clientId
    test eax, eax
    jnz exit

bunnyhop:
    invoke NtDelayExecution, FALSE, sleepDuration
    mov eax, [clientBase]
    add eax, localPlayerOffset
    invoke NtReadVirtualMemory, [processHandle], eax, localPlayer, 4, NULL
    test eax, eax
    jnz exit
    invoke GetAsyncKeyState, 0x20
    test eax, eax
    jz bunnyhop
    mov eax, [clientBase]
    add eax, mouseEnableOffset
    invoke NtReadVirtualMemory, [processHandle], eax, mouseEnable, 4, NULL
    and [mouseEnable], 1
    jz bunnyhop
    mov eax, [localPlayer]
    add eax, flagsOffset
    invoke NtReadVirtualMemory, [processHandle], eax, localPlayerFlags, 4, NULL
    and [localPlayerFlags], 1
    jz bunnyhop
    mov eax, [clientBase]
    add eax, forceJumpOffset
    invoke NtWriteVirtualMemory, [processHandle], eax, forceJump, 4, NULL
    jmp bunnyhop

exit:
    retn

section '.bss' data readable writable

processEntry PROCESSENTRY32 ?
clientDll MODULEENTRY32 ?

snapshot dd ?
clientId CLIENT_ID ?
objectAttributes OBJECT_ATTRIBUTES ?
processHandle dd ?
clientBase dd ?
localPlayer dd ?
localPlayerFlags dd ?
mouseEnable dd ?

section '.idata' import readable

library kernel32, 'kernel32.dll', \
        msvcrt, 'msvcrt.dll', \
        user32, 'user32.dll', \
        ntdll, 'ntdll.dll'

import kernel32, \
       CreateToolhelp32Snapshot, 'CreateToolhelp32Snapshot', \
       Module32First, 'Module32First', \
       Module32Next, 'Module32Next', \
       Process32First, 'Process32First', \
       Process32Next, 'Process32Next'

import msvcrt, \
       strcmp, 'strcmp'

import user32, \
       GetAsyncKeyState, 'GetAsyncKeyState'

import ntdll, \
       NtDelayExecution, 'NtDelayExecution', \
       NtReadVirtualMemory, 'NtReadVirtualMemory', \
       NtWriteVirtualMemory, 'NtWriteVirtualMemory', \
       NtOpenProcess, 'NtOpenProcess'
