Import-Module ".\src\funcs.psm1"
if (Test-Connection -Quiet -ComputerName "google.com" -Count 1) {
    Find-Update
}
Write-Intro

$MaxEpisode = Get-UserInput -Prompt "Please enter which tape you'd like to search up to" `
    -ErrorMessage "No silly! Enter a number between 1 and 200 (inclusive)" `
    -CheckMethod { (($args[0] -ge 1) -and ($args[0] -le 200)) } `
    -IsInt

Write-Host "Okay, no information past tape " -NoNewline
Write-Host $MaxEpisode -NoNewline -ForegroundColor White -BackgroundColor Blue
Write-Host " will be shown."

Write-Host "Enter `"[f]ind`", `"[r]ead`" or `"[e]xit`" to either find text in The Archives, read an archive, or exit the program."

Do {
    $Command = Get-UserInput -ErrorMessage "Please only enter `"find`", `"exit`", `"read`", `"f`", `"e`" or `"r`"" `
        -CheckMethod { $args[0] -iin ("find", "exit", "read", "f", "e", "r") }

    switch ($Command[0]) {
        "f" {
            $SearchString = Get-UserInput -Prompt "Please enter the text you wish to search for"
            $SearchInMetadata = (Get-UserInput -Prompt "Would you like to search in archive metadata (y) or only body text (n)?" `
                    -ErrorMessage "You may only enter a `"y`" or an `"n`"" `
                    -CheckMethod { $args[0] -iin "y", "n" }) -ieq "y"

            Write-Host "Okay, searching for " -NoNewline
            Write-Host $SearchString -BackgroundColor Blue -ForegroundColor White -NoNewline
            Write-Host " in the archives, " -NoNewline
            if ($SearchInMetadata) {
                Write-Host "including" -BackgroundColor Green -ForegroundColor White -NoNewline
            }
            else {
                Write-Host "excluding" -BackgroundColor Red -ForegroundColor White -NoNewline
            }
            Write-Host " in metadata."
            $FoundTapes = Invoke-Find -MaxTape $MaxEpisode -SearchString $SearchString
            
            if (!$FoundTapes) {
                Write-Host "No archives were found containing " -NoNewline
                Write-Host $SearchString -BackgroundColor Yellow -ForegroundColor White
                break
            }

            foreach ($Tape in $FoundTapes) {
                if ($SearchInMetadata -and ($Tape.MatchInMetadata -or $Tape.MatchInBody)) {
                    Get-TapeContent -TapeNumber $Tape.Index -GetTitle
                }
                if (!$SearchInMetadata -and $Tape.MatchInBody) {
                    Get-TapeContent -TapeNumber $Tape.Index -GetTitle
                }
            }
        }
        "e" {
            $Confirm = Get-UserInput -Prompt "Are you sure you wish to exit? (y/n)" `
                -ErrorMessage "You may only enter a `"y`" or an `"n`"" `
                -CheckMethod { $args[0] -iin "y", "n" }
            if ($Confirm -eq "y") {
                Write-Host "See you again soon, Archivist..." -BackgroundColor DarkMagenta
                Start-Sleep -Milliseconds 2000
                Exit                     
            } 
        }
        "r" {
            $TapeNumber = Get-UserInput -Prompt "Please enter which tape number you wish to view" `
                -ErrorMessage "Spoilers, Archivist! Only enter a number between 1 and $MaxEpisode." `
                -CheckMethod { (($args[0] -ge 1) -and ($args[0] -le $MaxEpisode)) } `
                -IsInt
            $ViewMetadata = (Get-UserInput -Prompt "Would you like metadata to be included at the top of the statement? (y/n)" `
                    -ErrorMessage "You may only enter a `"y`" or an `"n`"" `
                    -CheckMethod { $args[0] -iin "y", "n" }) -eq "y"
            if ($ViewMetadata) {
                & ".\src\leaf.exe" (Get-ChildItem -Path ".\src\Transcripts")[$TapeNumber - 1].FullName
            }
            else {
                ((Get-Content -Path ((Get-ChildItem -Path ".\src\Transcripts")[$TapeNumber - 1].FullName) -Raw) -split "---")[2] | .\src\leaf.exe
                
            }
        }
    }

} while ($true) 