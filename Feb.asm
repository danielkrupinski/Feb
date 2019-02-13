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

start:
    stdcall findProcessId
    mov [clientId.UniqueProcess], eax
    stdcall findModuleBase, eax
    mov [clientBase], eax
    mov [objectAttributes.Length], sizeof.OBJECT_ATTRIBUTES
    lea eax, [processHandle]
    lea ebx, [objectAttributes]
    lea ecx, [clientId]
    invoke NtOpenProcess, eax, PROCESS_VM_READ + PROCESS_VM_WRITE + PROCESS_VM_OPERATION, ebx, ecx
    test eax, eax
    jnz exit

bunnyhop:
    lea eax, [sleepDuration]
    invoke NtDelayExecution, FALSE, eax
    mov eax, [clientBase]
    add eax, [localPlayerOffset]
    lea ebx, [localPlayer]
    invoke NtReadVirtualMemory, [processHandle], eax, ebx, 4, NULL
    test eax, eax
    jnz exit
    invoke GetAsyncKeyState, 0x20
    test eax, eax
    jz bunnyhop
    mov eax, [localPlayer]
    add eax, [flagsOffset]
    lea ebx, [localPlayerFlags]
    invoke NtReadVirtualMemory, [processHandle], eax, ebx, 4, NULL
    and [localPlayerFlags], 1
    cmp [localPlayerFlags], 1
    jne bunnyhop
    mov eax, [clientBase]
    add eax, [forceJumpOffset]
    lea ebx, [forceJump]
    invoke NtWriteVirtualMemory, [processHandle], eax, ebx, 4, NULL
    jmp bunnyhop

exit:
    invoke NtTerminateProcess, NULL, 0

proc findProcessId
    locals
        processEntry PROCESSENTRY32 ?
        snapshot dd ?
    endl

    invoke CreateToolhelp32Snapshot, 0x2, 0
    mov [snapshot], eax
    mov [processEntry.dwSize], sizeof.PROCESSENTRY32
    lea eax, [processEntry]
    invoke Process32First, [snapshot], eax
    cmp eax, 1
    jne exit
    loop2:
        lea eax, [processEntry]
        invoke Process32Next, [snapshot], eax
        cmp eax, 1
        jne exit
        lea eax, [processEntry.szExeFile]
        cinvoke strcmp, <'csgo.exe', 0>, eax
        test eax, eax
        jnz loop2

    mov eax, [processEntry.th32ProcessID]
    ret
endp

proc findModuleBase, processID
    locals
        moduleEntry MODULEENTRY32 ?
        snapshot dd ?
    endl

    invoke CreateToolhelp32Snapshot, 0x8, [processID]
    mov [snapshot], eax
    mov [moduleEntry.dwSize], sizeof.MODULEENTRY32
    lea eax, [moduleEntry]
    invoke Module32First, [snapshot], eax
    cmp eax, 1
    jne exit
    loop3:
        lea eax, [moduleEntry]
        invoke Module32Next, [snapshot], eax
        cmp eax, 1
        jne exit
        lea eax, [moduleEntry.szModule]
        cinvoke strcmp, <'client_panorama.dll', 0>, eax
        test eax, eax
        jnz loop3

    mov eax, [moduleEntry.modBaseAddr]
    ret
endp

section '.bss' data readable writable

clientId CLIENT_ID ?
objectAttributes OBJECT_ATTRIBUTES ?
processHandle dd ?
clientBase dd ?
localPlayer dd ?
localPlayerFlags dd ?

section '.rdata' data readable

localPlayerOffset dd 0xCC96A4
flagsOffset dd 0x104
forceJumpOffset dd 0x517D1A4
forceJump dd 6
sleepDuration dq -1

section '.idata' data readable import

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
       NtTerminateProcess, 'NtTerminateProcess', \
       NtWriteVirtualMemory, 'NtWriteVirtualMemory', \
       NtOpenProcess, 'NtOpenProcess'
