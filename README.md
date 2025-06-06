# linux-like-ls-for-powershell

一个为 PowerShell 提供类 Linux `ls` 命令功能的模块，支持彩色输出、文件类型指示符和多列布局。

## 功能特点

- 🎨 **彩色输出**：目录、可执行文件和符号链接使用不同颜色显示
- 📝 **文件类型指示符**：在文件名后添加 `/`（目录）、`*`（可执行文件）或 `@`（符号链接）
- 📊 **多列布局**：自动适应终端宽度进行多列显示
- 🖥️ **详细模式**：使用 `-l` 选项显示表格布局
- 📏 **CJK字符支持**：正确处理中文、日文、韩文字符的宽度计算
- 🚀 **轻量高效**：纯 PowerShell 实现，无需外部依赖

## 安装

1. 将项目克隆或下载到 PowerShell 模块目录：
   ```powershell
   git clone https://github.com/yourusername/linux-like-ls-for-powershell.git "$env:USERPROFILE\Documents\PowerShell\Modules\linux-like-ls-for-powershell"
   ```

2. 在 PowerShell 配置文件 (`$PROFILE`) 中添加以下内容：
   ```powershell
   # 导入 linux-like-ls 函数
   . "$env:USERPROFILE\Documents\PowerShell\Modules\linux-like-ls-for-powershell\linux-like-ls.ps1"
   
   # 移除现有的 ls 别名
   Remove-Item Alias:ls -ErrorAction SilentlyContinue
   
   # 设置 ls 别名指向我们的函数
   Set-Alias -Name ls -Value Linux-Like-LS
   ```

3. 重新加载配置文件：
   ```powershell
   . $PROFILE
   ```

## 使用说明

### 基本命令

```powershell
ls [路径] [选项]
```

### 选项

| 选项       | 描述                         |
| ---------- | ---------------------------- |
| `-1`       | 每行显示一个文件             |
| `-f`或`-F` | 显示文件类型指示符 (`*/@#~%`) |
| `-c`或`-C` | 启用彩色输出                 |
| `-l`或`-L` | 详细列表模式 |
| `-s` | 忽略大小写查询 |
| `-S` | 严格匹配大小写查询 |
| `--help`   | 显示帮助信息                 |

### 示例

1. **基本使用**（多列布局，自动适应终端宽度）：

   ```powershell
   ls
   ```

   ![](image\ls.png)

2. **彩色输出**：

   ```powershell
   ls -c
   ```

   ![](image\lsc.png)

3. **显示文件类型指示符**：

   ```powershell
   ls -f
   ```

   ![](image\lsf.png)

4. **每行显示一个文件**：

   ```powershell
   ls -1
   ```

   ![](image\ls1.png)

5. **组合选项**（彩色+文件类型+表格指示符）：

   ```powershell
   ls -c -f -l或ls -cfl
   ```

   ![](image\lslcf.png)

6. **指定路径**：

   ```powershell
   ls C:\Users
   ls -l D:\Projects
   ```

7. **忽略大小写查询**

   ```powershell
   ls -s "r"
   ```

   ![](image\lss.png)

8. **严格匹配大小写查询**

   ```powershell
   ls -S "R" -l
   ```

   ![](image\lssl.png)

## 自定义配置

你可以在脚本中修改以下变量来自定义行为：

```powershell
# 可执行文件扩展名
$LinuxLikeLsExecutables = @(".exe", ".bat", ".cmd", ".ps1", ".sh", ".js", ".py", ".rb", ".pl", ".cs", ".vbs")

# 列间距
$LinuxLikeLsSpaceLength = 2

# 颜色配置
$LinuxLikeLsColorMap = @{
    "Directory"    = "$ANSI_ESC[94m" # 蓝色
    "Executable"   = "$ANSI_ESC[32m" # 绿色
    "SymbolicLink" = "$ANSI_ESC[96m" # 亮青色
    "Other"        = $ANSI_RESET     # 默认
}
```

## 许可证

本项目采用 [MIT 许可证](LICENSE)

---

**让 PowerShell 拥有 Linux 终端的体验！**  
现在就开始使用 `ls` 命令，享受更直观、更丰富的文件列表体验！
