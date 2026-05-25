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

function Find-TapesContaining {
    param (
        [string] $SearchString,
        [int] $MaxTape
    )
    
    $CurrentTape = 0
    $TapesContainingString = @()
    foreach ($Tape in (Get-ChildItem -Path ".\src\Transcripts\")) {
        if ($CurrentTape -ge $MaxTape) { break }
        $TapeContent = Get-Content -Path $Tape.FullName
        if ($TapeContent -like ("*" + $SearchString + "*")) {
            $TapesContainingString += ($CurrentTape + 1)
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
    Write-Host " __  __                               _____           _   _ _         _" -ForegroundColor Green
    Write-Host "|  \/  |                             |_   _|         | | (_) |       | |      " -ForegroundColor Green
    Write-Host "| \  / | __ _  __ _ _ __  _   _ ___    | |  _ __  ___| |_ _| |_ _   _| |_ ___ " -ForegroundColor Green
    Write-Host "| |\/| |/ _` |/ _` | '_ \| | | / __|   | | | '_ \/ __| __| | __| | | | __/ _ \" -ForegroundColor Green
    Write-Host "| |  | | (_| | (_| | | | | |_| \__ \  _| |_| | | \__ \ |_| | |_| |_| | ||  __/" -ForegroundColor Green
    Write-Host "|_|  |_|\__,_|\__, |_| |_|\__,_|___/ |_____|_| |_|___/\__|_|\__|\__,_|\__\___|" -ForegroundColor Green
    Write-Host "                 / |                                                          " -ForegroundColor Green
    Write-Host "              |___/                                                           " -ForegroundColor Green
    Write-Host "Est. 1887" -ForegroundColor Green
    Write-Host ""
    Write-Host "Loading" -NoNewline -BackgroundColor Blue
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host "."
    Start-Sleep -Milliseconds 800
    Write-Host "Hello, Archivist."
    Start-Sleep -Milliseconds 700
}