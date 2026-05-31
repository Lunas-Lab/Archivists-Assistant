Import-Module "$PSScriptRoot\Version.psm1"
function Get-UserInput {
    param (
        [string] $Prompt = " ",
        [string] $ErrorMessage,
        [scriptblock] $CheckMethod = { $true },
        [switch] $IsInt
    )
    if ($IsInt) {
        Do {
            try {
                [int]$Result = Read-Host -Prompt $Prompt
            }
            catch [System.Management.Automation.ArgumentTransformationMetadataException] {}
            if (!(& $CheckMethod $Result)) {
                Write-Host "ERROR:" -NoNewline -ForegroundColor White -BackgroundColor Red
                Write-Host " " $ErrorMessage
            }
        } Until (& $CheckMethod $Result)
    }
    else {
        Do {
            $Result = Read-Host -Prompt $Prompt
            if (!(& $CheckMethod $Result)) {
                Write-Host "ERROR:" -NoNewline -ForegroundColor White -BackgroundColor Red
                Write-Host " " $ErrorMessage
            }
        } Until (& $CheckMethod $Result)
    }
    

    $Result
}

function Select-MarkdownMetadata {
    param (
        [string] $Markdown
    )

    $Metadata = ($Markdown | Select-String -Pattern "(?s)---\n(.*?)\n---\n").Matches.Value
    $Metadata
}

function Find-TapesContaining {
    param (
        [string] $SearchString,
        [int] $MaxTape
    )
    
    $CurrentTape = 0
    $TapesContainingString = @()
    foreach ($Tape in (Get-ChildItem -Path ".\src\Transcripts\")) {
        if ($CurrentTape -ge $MaxTape) { break }

        $TapeContent = Get-Content -Path $Tape.FullName -Raw
        $TapeMetadata = Select-MarkdownMetadata -Markdown $TapeContent
        if ($TapeContent -like ("*" + $SearchString + "*")) {
            $TapeData = [pscustomobject]@{
                    Index = ($CurrentTape + 1)
                    Content = $TapeContent
                    MatchInBody = $true
                    MatchInMetadata = $false
                }
            if ($TapeMetadata -like ("*" + $SearchString + "*")) {
                $TapeData.MatchInMetadata = $true
            }
            $TapesContainingString += $TapeData
        }
        $CurrentTape ++
    }

    $TapesContainingString
}

function Get-TapeContent {
    param (
        [int] $TapeNumber,
        [switch] $GetTitle
    )

    $TapePath = (Get-ChildItem -Path ".\src\Transcripts")[$TapeNumber - 1].FullName
    if ($GetTitle) {
        $Return = ((Select-String -Path $TapePath -Pattern "title")[0].Line -replace "title:", "").Trim() -replace "`"", ""
    }
    else {
        $Return = Get-Content -Path $TapePath
    }

    $Return
}

function Invoke-Find {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string] $SearchString,
        [int] $MaxTape
    )
    
    begin {

    }
    
    process {
        Write-Host "Searching for " -NoNewline
        Write-Host $SearchString -ForegroundColor White -BackgroundColor Blue
        $FoundTapes = Find-TapesContaining -SearchString $SearchString -MaxTape $MaxTape
    }
    
    end {
        $FoundTapes
    }
}

function Write-Intro {
    Write-Host " __  __                               _____           _   _ _         _       " -ForegroundColor Green
    Write-Host "|  \/  |                             |_   _|         | | (_) |       | |      " -ForegroundColor Green
    Write-Host "| \  / | __ _  __ _ _ __  _   _ ___    | |  _ __  ___| |_ _| |_ _   _| |_ ___ " -ForegroundColor Green
    Write-Host "| |\/| |/ _`` |/ _`` | '_ \| | | / __|   | | | '_ \/ __| __| | __| | | | __/ _ \" -ForegroundColor Green
    Write-Host "| |  | | (_| | (_| | | | | |_| \__ \  _| |_| | | \__ \ |_| | |_| |_| | ||  __/" -ForegroundColor Green
    Write-Host "|_|  |_|\__,_|\__, |_| |_|\__,_|___/ |_____|_| |_|___/\__|_|\__|\__,_|\__\___|" -ForegroundColor Green
    Write-Host "                 / |                                                          " -ForegroundColor Green
    Write-Host "              |___/                                                           " -ForegroundColor Green
    Write-Host "Est. 1887" -ForegroundColor Green
    Write-Host ""
    Write-Host "Loading" -NoNewline -BackgroundColor Blue
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 500
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 500
    Write-Host "."
    Start-Sleep -Milliseconds 300
    Write-Host ""
    Write-Host "Hello, Archivist."
    Start-Sleep -Milliseconds 200
}

function Find-Update {
    $Response = Invoke-WebRequest -Uri "https://github.com/Lunas-Lab/Archivists-Assistant/raw/master/src/Version.psm1" -UseBasicParsing
    if ([version] $Response.Content.Split('"')[1] -gt $Version) {
        Write-Host "There is an update for Archivists Assistant available." -BackgroundColor Yellow -ForegroundColor White
        $ShouldUpdate = Get-UserInput -Prompt "Would you like to update now? (y/n)" `
            -ErrorMessage "Please only enter `"y`" for `"yes`" or `"n`" for `"no`"" `
            -CheckMethod { $args[0] -iin "y", "n" }
        if ($ShouldUpdate -ieq "y") {
            Install-Update
            Exit
        }
    }
}

function Install-Update {
    & "..\MinGit\cmd\git.exe" "fetch" "--all"
    & "..\MinGit\cmd\git.exe" "reset" "--hard" "origin/master"
    & ".\Archivists Assistant.bat"
}