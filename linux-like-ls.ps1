$LinuxLikeLsExecutables = @(
    ".exe", ".bat", ".cmd",".ps1", ".sh", 
    ".js", ".py", ".rb", ".pl", ".cs", ".vbs"
)

$LinuxLikeLsSpaceLength = 2

$ANSI_ESC = [char]0x1B
$ANSI_RESET = "$ANSI_ESC[0m"
$LinuxLikeLsColorMap = @{
    "Directory"    = "$ANSI_ESC[94m" # Cyan
    "Executable"   = "$ANSI_ESC[32m" # Green
    "SymbolicLink" = "$ANSI_ESC[96m" # Bright cyan
    "Other"        = $ANSI_RESET     # reset color and styles
}

$LinuxLikeLsTypeIdMap = @{
    "Directory" = "/"
    "Executable" = "*"
    "SymbolicLink" = "@"
    "Other" = ""
}

$LinuxLikeLsHelpText = @"
linux-like-ls

Options:
-1     list one file per line
-f,F   append indicator (one of */@) to entries
-c,C   color the output.
-l,L   display items in a formatted table with borders.
       this option will be preferentially applied.
--help display this help message

Notice:
For redirect or pipe, you must use with the pass through option (-L)
or -1 without -F, -C option. 
When used with -L option, this function simply calls Get-ChildItem,
so returns an array of FileSystemInfo objects.
When used with -1 option, this function returns a string array of the
file names.
"@

# -----------------------------------------------------------------------------------------------------------------
$LinuxLikeLsDebugFlag = $false

enum FileType {
    Directory
    Executable
    SymbolicLink
    Other
}

# 辅助函数：计算字符串的显示宽度（中文算2个宽度）
function Get-StringDisplayWidth {
    param([string]$str)
    $len = 0
    foreach ($c in $str.ToCharArray()) {
        # 判断是否为中文字符（扩展Unicode范围）
        $codepoint = [int]$c
        if (($codepoint -ge 0x4E00 -and $codepoint -le 0x9FFF) -or 
            ($codepoint -ge 0x3400 -and $codepoint -le 0x4DBF) -or 
            ($codepoint -ge 0x20000 -and $codepoint -le 0x2A6DF) -or 
            ($codepoint -ge 0x2A700 -and $codepoint -le 0x2B73F)) {
            $len += 2  # 中文字符宽度
        } else {
            $len += 1  # 英文字符宽度
        }
    }
    return $len
}

# 辅助函数：按显示宽度填充字符串
function PadByWidth {
    param(
        [string]$str,
        [int]$totalWidth
    )
    $currentWidth = Get-StringDisplayWidth $str
    $padding = [Math]::Max(0, $totalWidth - $currentWidth)
    return $str + (' ' * $padding)
}

Function Linux-Like-LS {
    function Get-Args ($orgArgs, $lsArgs) {
        $i = 0
        while ($i -lt $orgArgs.Count) {
            $arg = $orgArgs[$i]
            $arg = "$arg" 
            if ($arg -eq "--help") {
                $lsArgs["showHelp"] = $true
                return
            }
            if ($arg.StartsWith("-")) {
                foreach ($char in $arg.ToLower().Substring(1).ToCharArray()) {
                    switch ($char) {
                        "1" { $lsArgs["onePerLine"] = $true }
                        "l" { $lsArgs["longFormat"] = $true }
                        "f" { $lsArgs["showFileType"] = $true }
                        "c" { $lsArgs["setColor"] = $true }
                    }
                }
            } else {
                $lsArgs["path"] = $arg
            }
            $i++
        }
        if ($lsArgs["longFormat"]) {
            $lsArgs["onePerLine"] = $false
        }
    }    

    function Get-FileType {
        param([System.IO.FileSystemInfo]$item)
    
        $name = $item.Name
        $type = [FileType]::Other
    
        try {
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $type = [FileType]::SymbolicLink
            }
            elseif ($item.PSIsContainer) {
                $type = [FileType]::Directory
            }
            elseif ($script:LinuxLikeLsExecutables -contains $item.Extension.ToLower()) {
                $type = [FileType]::Executable
            }
        } catch {
        }
        return $type
    }
    
    function Get-LineCount($displayWidths, $windowWidth, $padding=$null) {
        if($padding -eq $null){ $padding = $script:LinuxLikeLsSpaceLength }

        $rows = $displayWidths.Count 
        $cols = 1                    
        $colWidths = @()             

        function calc-width($displayWidths, $padding, $cols){
            $ret = 0
            $maxWidths = @() 
            $perLines = [math]::Ceiling($displayWidths.Count / $cols) 
            for ($i = 0; $i -lt $cols; $i++) {
                $startIdx = $i * $perLines
                $endIdx = [math]::Min($i * $perLines + $perLines -1, $displayWidths.Count - 1)

                $max = ($displayWidths[$startIdx..$endIdx] | Measure-Object -Maximum).Maximum
                $maxWidths += $max
            }
            $sum = ($maxWidths | Measure-Object -Sum).Sum
            $ret = $sum + ($cols - 1) * $padding
            return @($ret, $maxWidths)
        }

        $max = ($displayWidths| Measure-Object -Maximum).Maximum
        $colWidths = @($max)
        while($true){
            $nextCols = $cols + 1

            if ($nextCols -gt $displayWidths.Count) { 
                break
            }
            $tmpWidth, $tmpColWidths = calc-width $displayWidths $padding $nextCols
            if ($tmpWidth -gt $windowWidth) {
                break
            }
            $colWidths = $tmpColWidths
            $cols = $nextCols
        }
        $rows = [math]::Ceiling($displayWidths.Count / $cols)
        return @($rows, $cols, $colWidths)
    }

    $lsArgs = @{
        "path" = "."  
        "onePerLine" = $false  
        "longFormat" = $false  
        "showFileType" = $false  
        "setColor" = $false 
        "showHelp" = $false 
    }
    Get-Args $args $lsArgs

    if ($lsArgs["showHelp"]) {
        Write-Output $script:LinuxLikeLsHelpText
        return
    }

    try {
        # 替换 -l 选项的处理：使用表格输出
        if ($lsArgs["longFormat"]) {
            # 获取指定路径的项目
            $items = Get-ChildItem -Path $lsArgs["path"] -ErrorAction Stop | 
                     Select-Object Mode, LastWriteTime, Name

            # 如果没有项目则直接返回
            if (-not $items -or $items.Count -eq 0) {
                Write-Output "No items found in $($lsArgs['path'])"
                return
            }

            # 动态计算Name列显示宽度（考虑中文字符）
            $nameDisplayWidth = 10
            $maxWidth = ($items | ForEach-Object { 
                Get-StringDisplayWidth $_.Name 
            } | Measure-Object -Maximum).Maximum
            $nameDisplayWidth = [Math]::Max($maxWidth, 10)

            # 定义列宽（显示宽度）
            $modeWidth = 5      # 显示宽度5
            $timeWidth = 16     # 显示宽度16
            $nameWidth = $nameDisplayWidth  # 动态计算

            # 构建表格边框
            $topLine    = "┌─────┬────────────────┬" + ("─" * $nameWidth) + "┐"
            $header     = "│" + (PadByWidth "Mode" $modeWidth) + 
                          "│" + (PadByWidth "LastWriteTime" $timeWidth) + 
                          "│" + (PadByWidth "Name" $nameWidth) + "│"
            $divider    = "├─────┼────────────────┼" + ("─" * $nameWidth) + "┤"
            $bottomLine = "└─────┴────────────────┴" + ("─" * $nameWidth) + "┘"

            # 输出表格
            $topLine
            $header
            $divider

            # 输出数据行
            $items | ForEach-Object {
                $mode = PadByWidth $_.Mode $modeWidth
                $time = PadByWidth ($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm')) $timeWidth
                $name = PadByWidth $_.Name $nameWidth
                "│$mode│$time│$name│"
            }

            $bottomLine
            return
        } 
        
        $items = Get-ChildItem -Path $lsArgs["path"] -ErrorAction Stop
        if($script:LinuxLikeLsDebugFlag){
            Write-Host "items count : "$items.Count
        }

        if ($items.Count -eq 0) { return }

        $displayNames = @()
        $fileTypes = @()

        if ((-not $lsArgs["showFileType"]) -and (-not $lsArgs["setColor"])) {
            $displayNames = $items | Select-Object -ExpandProperty Name
        }
        else {
            foreach ($item in $items) {
                $type = Get-FileType -item $item
                $fileTypes += $type

                $baseName = $item.Name

                if ($lsArgs["showFileType"]) {
                    $baseName += $script:LinuxLikeLsTypeIdMap[$type.ToString()]
                }

                if ($lsArgs["setColor"] -and ($type -ne [FileType]::Other)) {
                    $color = $script:LinuxLikeLsColorMap[$type.ToString()]
                    $displayNames += $color + $baseName + $ANSI_RESET
                }
                else {
                    $displayNames += $baseName
                }
            }
        }

        if ($lsArgs["onePerLine"]) {
            foreach ($name in $displayNames) {
                Write-Output $name
            }
            return
        }

        $windowWidth = $Host.UI.RawUI.WindowSize.Width
        $displayWidths = @($displayNames | ForEach-Object { Get-StringDisplayWidth $_ })
        $rows, $cols, $colWidths = Get-LineCount $displayWidths $windowWidth

        if($script:LinuxLikeLsDebugFlag){
            Write-Host "(row, col) = ($rows, $cols)"
            Write-Host "column widths = " $colWidths
            Write-Host "display names = " $displayNames
            Write-Host "each width = " $displayWidths
        }

        $lines = @()
        for ($i = 0; $i -lt $rows; $i++) {
            $lines += ,@()
        }

        $tmpX = 0
        $tmpY = 0
        for ($idx=0; $idx -lt $displayNames.Count; $idx++ ){
            $name = $displayNames[$idx]
            $tmpX = [math]::Floor($idx / $rows)
            $tmpY = $idx - ($tmpX * $rows)

            $name += (" " * ($colWidths[$tmpX] - $displayWidths[$idx]) -join "")

            $lines[$tmpY] += $name
        }

        $space = (" " * $script:LinuxLikeLsSpaceLength) -join ""
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $tmp = $lines[$i] -join $space
            Write-Output $tmp
        }
        return
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error -Message "Get-ChildItem: $_" -Category ObjectNotFound -ErrorAction Continue
    }
}
