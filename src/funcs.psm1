Import-Module "$PSScriptRoot\Version.psm1"
function Get-UserInput {
    <#
    .SYNOPSIS
    Gets and checks input from user
    .DESCRIPTION
    Prompts the user for input with the message provided, checks the input with the function provided and will write the error message provided to the console if the check fails. Sends response to pipeline once user gives valid input. Optional switch to return an integer
    .PARAMETER Prompt
    What you'd like for the function to prompt the user with
    .PARAMETER ErrorMessage
    What you'd like for the function to prompt the user with if they provide invalid input
    .PARAMETER CheckMethod
    The function you'd like to be used to check if input is valid - pass by value
    .PARAMETER IsInt
    Optional switch to make the function convert input to an integer
    .EXAMPLE
    $Text = Get-UserInput -Prompt "Please choose if you'd like [r]ed, [g]reen or [b]lue" `
                          -ErrorMessage "Please only input `"r`", `"g`" or `"b`"."
                          -CheckMethod {$args[0] -iin "r", "g", "b"}
    #>
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
    <#
    .DESCRIPTION
    Extracts the YAML from a MarkDown-formatted string#
    .SYNOPSIS
    Takes Markdown-formatted string as an input and outputs YAML in it if present, otherwise throws System.ArgumentException and returns $null
    .PARAMETER Markdown
    Markdown-formatted string to have th YAML extracted from
    #>
    param (
        [string] $Markdown
    )

    $Metadata = ($Markdown | Select-String -Pattern "(?s)---\n(.*?)\n---\n").Matches.Value
    if ($null -eq $Metadata) {
        throw [System.ArgumentException]"No YAML found in document"
    }
    $Metadata
}

function Find-TapesContaining {
    param (
        [string] $SearchString,
        [int] $MaxTape
    )
    
    $TapesContainingString = @()

    for ($TapeIndex = 1; $TapeIndex -le $MaxTape; $TapeIndex++) {
        $MatchObject = [pscustomobject]@{
                    Index = ($TapeIndex)
                    MatchInBody = $false
                    MatchInMetadata = $false
                }

                if ((Get-TapeContent -TapeNumber $TapeIndex -ContentType Body) -like "*$SearchString*") {
                    $MatchObject.MatchInBody = $true
                }
                if ((Get-TapeContent -TapeNumber $TapeIndex -ContentType Metadata) -like "*$SearchString*") {
                    $MatchObject.MatchInMetadata = $true
                }

            if ($MatchObject.MatchInBody -or $MatchObject.MatchInMetadata) {
                $TapesContainingString += $MatchObject
            }
    }


    $TapesContainingString
}

function Get-TapeContent {
    param (
        [int] $TapeNumber,
        [ValidateSet('Body', 'Metadata', 'Title', 'All')]
        [string] $ContentType
    )

    $TapeContent = (Get-ChildItem -Path ".\src\Transcripts")[$TapeNumber - 1] | Get-Content -Raw

    switch ($ContentType) {
        'All' {$Return = $TapeContent  }
        'Title' {$Return = ($TapeContent | Select-String -Pattern 'title: *"(.*)"').Matches.Groups[1].Value}
        'Metadata' {$Return = Select-MarkdownMetadata -Markdown $TapeContent}
        'Body' {$Return = ($TapeContent | Select-String -Pattern '(?s)\n---\n(.*)').Matches[0].Value}
    }

    $Return
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
    Write-Host "Loading" -NoNewline
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 200
    Write-Host "." -NoNewline
    Start-Sleep -Milliseconds 200
    Write-Host "."
    Start-Sleep -Milliseconds 220
    Write-Host ""
    Write-Host "Hello, Archivist."
    Start-Sleep -Milliseconds 100
}

function Find-Update {
    $Response = Invoke-WebRequest -Uri "https://github.com/Lunas-Lab/Archivists-Assistant/raw/master/src/Version.psm1" -UseBasicParsing
    if ([version] $Response.Content.Split('"')[1] -gt $Version) {
        Write-Host "There is an update for Archivists Assistant available." -BackgroundColor DarkYellow -ForegroundColor White
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

function Find-Yaoi {
    [cmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string] $SearchString
    )

    if ($SearchString -ieq "yaoi") {
        Clear-Host
        Write-Host "Ohhhh Archivist... feeling a certain kind of way are we?"
        Start-Sleep -Milliseconds 1000
        Clear-Host
        [Console]::BackgroundColor = "Red"
        [Console]::ForegroundColor = "Red"
        Clear-Host
        Start-Sleep -Milliseconds 900
        [Console]::BackgroundColor = "Yellow"
        [Console]::ForegroundColor = "Yellow"
        Clear-Host
        Start-Sleep -Milliseconds 900
        [Console]::BackgroundColor = "Green"
        [Console]::ForegroundColor = "Green"
        Clear-Host
        Start-Sleep -Milliseconds 900
        [Console]::BackgroundColor = "Blue"
        [Console]::ForegroundColor = "Blue"
        Clear-Host
        Start-Sleep -Milliseconds 900
        [Console]::BackgroundColor = "Magenta"
        [Console]::ForegroundColor = "Magenta"
        Clear-Host
        Start-Sleep -Milliseconds 900
        [Console]::BackgroundColor = "Black"
        [Console]::ForegroundColor = "White"
        Clear-Host
    }
    
    $SearchString

}