﻿#requires -Module EZOut
#                 https://github.com/StartAutomating/EZOut
#              OR Install-Module EZOut   
$myRoot = $MyInvocation.MyCommand.ScriptBlock.File | Split-Path
$myName = $MyInvocation.MyCommand.Name -replace '\.ezformat\.ps1', ''


Write-FormatView -Action {
    $h = Get-History -Count 1
    $testOut = $_
    if ($global:_LastHistoryId -ne $h.id) {
        # New scoppe
        $global:_LastGroup = ''
        $global:_LastFile = ''
        $global:_LastHistoryId = $h.id
    }
    

    if ($global:_LastFile -ne $testOut.File.FullPath) {
        Write-Host -ForegroundColor Magenta "Validating $($testOut.File.FullPath | Split-Path | split-Path -Leaf)\$($testOut.File.Name)" 

        $global:_LastFile = $testOut.File.FullPath    
    }

    if ($global:_LastGroup -ne $testOut.Group) {
        $global:_LastGroup = $testOut.Group
        Write-Host -ForegroundColor Magenta "  $($testOut.Group)" 
    }
    $errorCount = $testOut.Errors.Count
    $warningCount = $testOut.Warnings.Count
    $foregroundColor = 'Green'
    $statusChar = '+'

    
    $errorLines = @(
        foreach ($_ in $testOut.Errors) {
            "$_"
        })
    $warningLines = @(
        foreach ($_ in $testOut.Warnings) {
            "$_"
        }
    )

    

    if ($errorCount) {
        $foregroundColor = 'Red'
        $statusChar = '-'        
    } elseif ($warningCount) {
        $foregroundColor = 'Yellow'
        $statusChar = '?'        
    }
    
    $statusLine = "    [$statusChar] $($testOut.Name) ($([Math]::Round($testOut.Timespan.TotalMilliseconds)) ms)"
    Write-Host $statusLine -ForegroundColor $foregroundColor -NoNewline

    $azoErrorStatus = if ($ENV:Agent_ID) { "##vso[task.logissue type=error;]"} else { '' }
    
    $indent = 8
    if ($testOut.AllOutput) {
        Write-Host " " # end of line
         
        foreach ($line in $testOut.AllOutput) {
            if ($line -is [Management.Automation.ErrorRecord] -or $line -is [Exception]) {
                Write-Host "$azoErrorStatus$(' ' * $indent)$line" -foregroundColor Red
            }
            elseif ($line -is [Management.Automation.WarningRecord]) {
                Write-Host "$azoWarnStatus$(' ' * $indent)$line" -foregroundColor Yellow
            }
            elseif ($line -is [string]) {
                Write-Host "$(' ' * $indent)$line"
            } 
            else {
                $line | 
                    Out-String -Width ($Host.UI.RawUI.BufferSize.Width - $indent) |
                    & { process {
                        Write-Host "$(' ' * $indent)$_"
                    } } 
            }
        }
    }    
} -TypeName 'Template.Validation.Test.Result' |
    Out-FormatData |
    Set-Content -Path (Join-Path $myRoot "$myName.format.ps1xml") -Encoding UTF8
