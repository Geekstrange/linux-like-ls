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
# 定义ANSI转义序列
$ANSI_ESC = [char]0x1B
$ANSI_RESET = "$ANSI_ESC[0m"

# 颜色映射表
$LinuxLikeLsColorMap = @{
    "Directory"    = "$ANSI_ESC[94m" # 亮蓝色
    "Executable"   = "$ANSI_ESC[32m" # 绿色
    "SymbolicLink" = "$ANSI_ESC[96m" # 亮青色
    "Archive"      = "$ANSI_ESC[91m" # 红色
    "Media"        = "$ANSI_ESC[95m" # 紫色
    "Backup"       = "$ANSI_ESC[90m" # 灰色
    "Other"        = $ANSI_RESET     # 重置颜色
}

# 渐变着色函数
function Add-Gradient {
    param(
        [string]$Text,
        [int[]]$StartRGB = @(0, 150, 255),  # 起始色（蓝）
        [int[]]$EndRGB = @(50, 255, 50)     # 终止色（绿）
    )
    $result = ""
    $chars = $Text.ToCharArray()
    for ($i = 0; $i -lt $chars.Count; $i++) {
        # 计算颜色插值（线性渐变算法）
        $ratio = $i / ($chars.Count - 1)
        $r = [int]($StartRGB[0] + ($EndRGB[0] - $StartRGB[0]) * $ratio)
        $g = [int]($StartRGB[1] + ($EndRGB[1] - $StartRGB[1]) * $ratio)
        $b = [int]($StartRGB[2] + ($EndRGB[2] - $StartRGB[2]) * $ratio)
        
        # 生成ANSI真彩色序列
        $result += "${ANSI_ESC}[38;2;${r};${g};${b}m$($chars[$i])"
    }
    $result + $ANSI_RESET
}

# 生成渐变标题
$gradientTitle = Add-Gradient -Text "Linux-like-ls for PowerShell"

# 创建超链接（兼容不同PS版本）
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7.2+ 优化写法
    $link = $PSStyle.FormatHyperlink(
        $gradientTitle, 
        "https://github.com/Geekstrange/linux-like-ls-for-powershell"
    )
} else {
    # 兼容PowerShell 5.1
    $esc = [char]0x1B
    $url = "https://github.com/Geekstrange/linux-like-ls-for-powershell"
    $link = "${esc}]8;;$url${esc}\" + $gradientTitle + "${esc}]8;;${esc}\"
}

# 文件类型标识符
$LinuxLikeLsTypeIdMap = @{
    "Directory"    = "/"
    "Executable"   = "*"
    "SymbolicLink" = "@"
    "Archive"      = "#"  
    "Media"        = "~"  
    "Backup"       = "%"
    "Other"        = ""
}

# 更新帮助文本说明
$LinuxLikeLsHelpText = @"

        ${link}

${ANSI_ESC}[96mOptions:${ANSI_RESET}
    ${ANSI_ESC}[32m-1${ANSI_RESET}     list one file per line.
    ${ANSI_ESC}[32m-f,F${ANSI_RESET}   append indicator (one of */@/#/~/%) to entries.
    ${ANSI_ESC}[32m-c,C${ANSI_RESET}   color the output.
    ${ANSI_ESC}[32m-l,L${ANSI_RESET}   display items in a formatted table with borders.
    ${ANSI_ESC}[32m-s${ANSI_RESET}     search files (case-insensitive).
    ${ANSI_ESC}[32m-S${ANSI_RESET}     search files (case-sensitive).
    ${ANSI_ESC}[32m--help${ANSI_RESET} display this help message.

${ANSI_ESC}[96mFile Type Indicators:${ANSI_RESET}
    ${ANSI_ESC}[94m/${ANSI_RESET} = Directory
    ${ANSI_ESC}[94m*${ANSI_RESET} = Executable
    ${ANSI_ESC}[94m@${ANSI_RESET} = Symbolic Link
    ${ANSI_ESC}[94m#${ANSI_RESET} = Archive (compressed file)
    ${ANSI_ESC}[94m~${ANSI_RESET} = Media file (audio/video/image)
    ${ANSI_ESC}[94m%${ANSI_RESET} = Backup/Temporary file
"@

# -----------------------------------------------------------------------------------------------------------------
$LinuxLikeLsDebugFlag = $false

# 文件类型枚举
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
        $codepoint = [int]$c
        if (($codepoint -ge 0x4E00 -and $codepoint -le 0x9FFF) -or 
            ($codepoint -ge 0x3400 -and $codepoint -le 0x4DBF) -or 
            ($codepoint -ge 0x20000 -and $codepoint -le 0x2A6DF) -or 
            ($codepoint -ge 0x2A700 -and $codepoint -le 0x2B73F)) {
            $len += 2
        } else {
            $len += 1
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
    $isOutputRedirected = [Console]::IsOutputRedirected

    function Get-Args ($orgArgs, $lsArgs) {
        $i = 0
        while ($i -lt $orgArgs.Count) {
            $arg = $orgArgs[$i]
            $arg = "$arg" 
        
            # 处理帮助参数
            if ($arg -eq "--help") {
                $lsArgs["showHelp"] = $true
                return
            }
        
            # 严格区分大小写的搜索参数
            if ($arg -cmatch "-S") {
                $i++
                $lsArgs["searchTerm"] = $orgArgs[$i]
                $lsArgs["strictCase"] = $true  # 严格匹配大小写标志
            }
            # 忽略大小写的搜索参数
            elseif ($arg -cmatch "-s") {
                $i++
                $lsArgs["searchTerm"] = $orgArgs[$i]
                $lsArgs["ignoreCase"] = $true  # 忽略大小写标志
            }
            # 其他单字母参数组合（如 -lc）
            elseif ($arg.StartsWith("-")) {
                foreach ($char in $arg.ToLower().Substring(1).ToCharArray()) {
                    switch ($char) {
                        "1" { $lsArgs["onePerLine"] = $true }    # 每行显示一个文件
                        "l" { $lsArgs["longFormat"] = $true }    # 长格式表格显示
                        "f" { $lsArgs["showFileType"] = $true }  # 显示文件类型标识符
                        "c" { $lsArgs["setColor"] = $true }      # 启用彩色输出
                    }
                }
            } 
            # 非参数项视为路径
            else {
                $lsArgs["path"] = $arg
            }
            $i++
        }
    
        # 长格式优先处理逻辑
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
            elseif ($script:LinuxLikeLsBackupExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Backup
            }
            elseif ($script:LinuxLikeLsMediaExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Media
            }
            elseif ($script:LinuxLikeLsArchiveExtensions -contains $item.Extension.ToLower()) {
                $type = [FileType]::Archive
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
        "searchTerm" = $null
        "ignoreCase" = $false
        "strictCase" = $false
    }
    Get-Args $args $lsArgs

    if ($lsArgs["showHelp"]) {
        Write-Output $script:LinuxLikeLsHelpText
        return
    }

    try {
        $items = Get-ChildItem -Path $lsArgs["path"] -ErrorAction Stop
        
        # 搜索过滤逻辑（区分大小写）
        if ($lsArgs["searchTerm"]) {
            if ($lsArgs["ignoreCase"]) {
                # 忽略大小写搜索
                $items = $items | Where-Object { 
                    $_.Name -like "*$($lsArgs['searchTerm'])*" 
                }
            }
            elseif ($lsArgs["strictCase"]) {
                # 严格匹配大小写
                $items = $items | Where-Object { 
                    $_.Name -clike "*$($lsArgs['searchTerm'])*" 
                }
            }
        }

        # 表格输出模式
        if ($lsArgs["longFormat"]) {
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

            $modeWidth = 5
            $timeWidth = 16
            $nameWidth = $nameDisplayWidth

            # 构建表格边框
            $topLine    = "┌─────┬────────────────┬" + ("─" * $nameWidth) + "┐"
            $header     = "│" + (PadByWidth "Mode" $modeWidth) + 
                          "│" + (PadByWidth "LastWriteTime" $timeWidth) + 
                          "│" + (PadByWidth "Name" $nameWidth) + "│"
            $divider    = "├─────┼────────────────┼" + ("─" * $nameWidth) + "┤"
            $bottomLine = "└─────┴────────────────┴" + ("─" * $nameWidth) + "┘"

            $topLine
            $header
            $divider

            $items | ForEach-Object {
                $mode = PadByWidth $_.Mode $modeWidth
                $time = PadByWidth ($_.LastWriteTime.ToString('yyyy/MM/dd HH:mm')) $timeWidth
                
                $type = Get-FileType $_
                
                $baseName = $_.Name
                if ($lsArgs["showFileType"]) {
                    $baseName += $script:LinuxLikeLsTypeIdMap[$type.ToString()]
                }
                
                $currentWidth = Get-StringDisplayWidth $baseName
                $paddingSpaces = [Math]::Max(0, $nameWidth - $currentWidth)
                
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
