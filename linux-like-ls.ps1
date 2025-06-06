# 可执行文件扩展名列表
$LinuxLikeLsExecutables = @(
    ".exe", ".bat", ".cmd",".ps1", ".sh", 
    ".js", ".py", ".rb", ".pl", ".cs", ".vbs"
)

# 压缩文件扩展名列表
$LinuxLikeLsArchiveExtensions = @(
	".7z", ".zip", ".rar", ".tar", ".gz", ".xz", ".bz2", 
	".cab", ".img", ".iso", ".jar", ".pea", ".rpm", ".tgz", ".z", ".deb", ".arj", ".lzh", 
	".lzma", ".lzma2", ".war", ".zst", ".part", ".s7z", ".split"
)

# 媒体文件扩展名列表
$LinuxLikeLsMediaExtensions = @(
# 音频格式
	".aac", ".amr", ".caf", ".m3u", ".midi", ".mod", ".mp1", ".mp2", ".mp3", ".ogg", ".opus", ".ra", ".wma", ".wav", ".wv",
# 视频格式
	".3gp", ".3g2", ".asf", ".avi", ".flv", ".m4v", ".mkv", ".mov", ".mp4", ".mpeg", ".mpg", ".mpe", ".mts", ".rm", ".rmvb", ".swf", ".vob", ".webm", ".wmv",
# 图像格式
	".ai", ".avage", ".art", ".blend", ".cgm", ".cin", ".cur", ".cut", ".dcx", ".dng", ".dpx", ".emf", ".fit", ".fits", ".fpx", ".g3", ".hdr", ".ief", ".jbig", ".jfif", ".jls", ".jp2", ".jpc", ".jpx", ".jpg", ".jpeg", ".jxl", ".pbm", ".pcd", ".pcx", ".pgm", ".pict", ".png", ".pnm", ".ppm", ".psd", ".ras", ".rgb", ".svg", ".tga", ".tif", ".tiff", ".wbmp", ".xpm"
)

# 备份文件扩展名列表
$LinuxLikeLsBackupExtensions = @(
    ".bak", ".backup", ".orig", ".old", ".tmp", ".temp", ".swap", 
    ".chklist", ".chk", ".ms", ".diz", ".wbk", ".xlk", ".cdr_", 
    ".nch", ".ftg", ".gid", ".syd"
)

$LinuxLikeLsSpaceLength = 2

$ANSI_ESC = [char]0x1B
$ANSI_RESET = "$ANSI_ESC[0m"
$LinuxLikeLsColorMap = @{
    "Directory"    = "$ANSI_ESC[94m" # 亮蓝色
    "Executable"   = "$ANSI_ESC[32m" # 绿色
    "SymbolicLink" = "$ANSI_ESC[96m" # 亮青色
    "Archive"      = "$ANSI_ESC[91m" # 红色
    "Media"        = "$ANSI_ESC[95m" # 紫色
	"Backup"       = "$ANSI_ESC[90m" # 灰色
    "Other"        = $ANSI_RESET     # 默认颜色
}

$LinuxLikeLsTypeIdMap = @{
    "Directory" = "/"
    "Executable" = "*"
    "SymbolicLink" = "@"
    "Archive"    = "#"  
    "Media"      = "~"
	"Backup"       = "%"
    "Other" = ""
}

$LinuxLikeLsHelpText = @"
linux-like-ls

Options:
-1     list one file per line
-f,F   append indicator (one of */@/#/~) to entries
-c,C   color the output.
-l,L   display items in a formatted table with borders.
       this option will be preferentially applied.
--help display this help message

Notice:
For redirect or pipe, you must use with the pass through option (-L)
or -1 without -F, -C option. 

File Type Indicators:
/ = Directory
* = Executable
@ = Symbolic Link
# = Archive (compressed file)
~ = Media file (audio/video/image)
"@

# -----------------------------------------------------------------------------------------------------------------
$LinuxLikeLsDebugFlag = $false

enum FileType {
    Directory
    Executable
    SymbolicLink
    Archive
    Media
	Backup
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
    # 检测输出是否被重定向（管道或文件）
    $isOutputRedirected = [Console]::IsOutputRedirected

    function Get-Args ($orgArgs, $lsArgs) {
        $i = 0
        while ($i -lt $orgArgs.Count) {
            $arg = $orgArgs[$i]
            $arg = "$arg" 
            if ($arg -eq "--help") {
                $lsArgs["showHelp"] = $true
                return
            }
            if ($arg -eq "-s" -or $arg -eq "--search") {
                $i++
                $lsArgs["searchTerm"] = $orgArgs[$i]
            }
            elseif ($arg.StartsWith("-")) {
                foreach ($char in $arg.ToLower().Substring(1).ToCharArray()) {
                    switch ($char) {
                        "1" { $lsArgs["onePerLine"] = $true }
                        "l" { $lsArgs["longFormat"] = $true }
                        "f" { $lsArgs["showFileType"] = $true }
                        "c" { $lsArgs["setColor"] = $true }
                        "s" { $lsArgs["searchMode"] = $true }
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
			# 临时文件类型检测
            elseif ($script:LinuxLikeLsBackupExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Backup
            }
            elseif ($item.PSIsContainer) {
                $type = [FileType]::Directory
            }
            # 媒体文件类型检测
            elseif ($script:LinuxLikeLsMediaExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Media
            }
            # 压缩文件类型检测
            elseif ($script:LinuxLikeLsArchiveExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Archive
            }
			# 可执行文件类型检测
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
        "searchTerm" = $null
        "searchMode" = $false
    }
    Get-Args $args $lsArgs

    if ($lsArgs["showHelp"]) {
        Write-Output $script:LinuxLikeLsHelpText
        return
    }

    try {
        # 获取文件列表（支持搜索过滤）
        $items = Get-ChildItem -Path $lsArgs["path"] -ErrorAction Stop
        
        # 搜索筛选逻辑
        if ($lsArgs["searchTerm"] -or $lsArgs["searchMode"]) {
            $searchTerm = if ($lsArgs["searchTerm"]) { 
                $lsArgs["searchTerm"] 
            } else { 
                $lsArgs["path"] = $args[-1]
                $args[-1]
            }
            
            $items = $items | Where-Object { 
                $_.Name -like "*$searchTerm*" 
            }
        }

        # 替换 -l 选项的处理：使用表格输出
        if ($lsArgs["longFormat"]) {
            # 动态计算Name列显示宽度
            $nameDisplayWidth = 10
            if ($items) {
                $maxWidth = $items | ForEach-Object { 
                    $baseName = $_.Name
                    if ($lsArgs["showFileType"]) {
                        $type = Get-FileType $_
                        $baseName += $script:LinuxLikeLsTypeIdMap[$type.ToString()]
                    }
                    Get-StringDisplayWidth $baseName
                } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
                $nameDisplayWidth = [Math]::Max($maxWidth, 10)
            }

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

            # 输出数据行（带颜色和文件类型标识）
            $items | ForEach-Object {
                $mode = PadByWidth $_.Mode $modeWidth
                $time = PadByWidth ($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm')) $timeWidth
                
                # 获取文件类型
                $type = Get-FileType $_
                
                # 构建基础文件名（含类型标识）
                $baseName = $_.Name
                if ($lsArgs["showFileType"]) {
                    $baseName += $script:LinuxLikeLsTypeIdMap[$type.ToString()]
                }
                
                # 计算显示宽度和填充空格
                $currentWidth = Get-StringDisplayWidth $baseName
                $paddingSpaces = [Math]::Max(0, $nameWidth - $currentWidth)
                
                # 应用颜色（如启用且未重定向）
                if ((-not $isOutputRedirected) -and $lsArgs["setColor"] -and ($type -ne [FileType]::Other)) {
                    $color = $script:LinuxLikeLsColorMap[$type.ToString()]
                    $name = $color + $baseName + $ANSI_RESET + (' ' * $paddingSpaces)
                } else {
                    $name = $baseName + (' ' * $paddingSpaces)
                }

                "│$mode│$time│$name│"
            }

            $bottomLine
            return
        } 
        
        if($script:LinuxLikeLsDebugFlag){
            Write-Host "items count : "$items.Count
        }

        if ($items.Count -eq 0) { 
            Write-Output "No matching files found"
            return 
        }

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

                # 应用颜色（如启用且未重定向）
                if ((-not $isOutputRedirected) -and $lsArgs["setColor"] -and ($type -ne [FileType]::Other)) {
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
