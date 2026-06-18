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
Write-Host $MaxEpisode -NoNewline -ForegroundColor Blue
Write-Host " will be shown."

Write-Host "Enter `"[f]ind`", `"[r]ead`", `"[l]ist`", `"[o]pen`" or `"[e]xit`" to either find text in The Archives, read an archive, list the tapes you've read so far, open a tape/the homepage in your browser or exit the program."

Do {
    $Command = Get-UserInput -ErrorMessage "Please only enter `"find`", `"exit`", `"read`", `"list`", `"open`", `"f`", `"e`", `"r`", `"l`" or `"o`"" `
        -CheckMethod { $args[0] -iin ("find", "exit", "read", "list", "open", "f", "e", "r", "l", "o") }

    switch ($Command[0]) {
        "f" {
            $SearchString = Get-UserInput -Prompt "Please enter the text you wish to search for" | Find-Yaoi
            $SearchString = (Get-Culture).TextInfo.ToTitleCase($SearchString.ToLower())
            $SearchInMetadata = (Get-UserInput -Prompt "Would you like to search in archive metadata (y) or only body text (n)?" `
                    -ErrorMessage "You may only enter a `"y`" or an `"n`"" `
                    -CheckMethod { $args[0] -iin "y", "n" }) -ieq "y"

            Write-Host "Okay, searching for " -NoNewline
            Write-Host $SearchString -ForegroundColor Blue -NoNewline
            Write-Host " in the archives, " -NoNewline
            if ($SearchInMetadata) {
                Write-Host "including" -ForegroundColor Green -NoNewline
            }
            else {
                Write-Host "excluding" -ForegroundColor Red -NoNewline
            }
            Write-Host " in metadata."
            Write-Host "Searching for " -NoNewline
            Write-Host $SearchString -ForegroundColor Blue -NoNewline
            Write-Host "..."
            $FoundTapes = Find-TapesContaining -SearchString $SearchString -MaxTape $MaxEpisode
            
            if (!$FoundTapes) {
                Write-Host "No archives were found containing " -NoNewline
                Write-Host $SearchString -ForegroundColor Red
                break
            }


            $TapeCount = 0
            foreach ($Tape in $FoundTapes) {
                if ($SearchInMetadata -and ($Tape.MatchInMetadata -or $Tape.MatchInBody)) {
                    $TapeTitles += (Get-TapeContent -TapeNumber $Tape.Index -ContentType Title) + "`n"
                    $TapeCount++
                    continue
                }
                if (!$SearchInMetadata -and $Tape.MatchInBody) {
                    $TapeTitles += (Get-TapeContent -TapeNumber $Tape.Index -ContentType Title) + "`n"
                    $TapeCount++
                }
            }
            Write-Host $TapeCount -ForegroundColor Green -NoNewline
            Write-Host " matches to " -NoNewline
            Write-Host $SearchString -ForegroundColor Green -NoNewline
            Write-Host " found in The Archives"
            Write-Host $TapeTitles

            $TapeTitles = ""
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
                Get-TapeContent -TapeNumber $TapeNumber -ContentType All | .\src\leaf.exe
            }
            else {
                Get-TapeContent -TapeNumber $TapeNumber -ContentType Body | .\src\leaf.exe
                
            }
        }
        "l" {
            for ($TapeIndex = 1; $TapeIndex -le $MaxEpisode; $TapeIndex++) {
                Get-TapeContent -TapeNumber $TapeIndex -ContentType Title
            }
        }

        "o" {
            $TapeIndex = Get-UserInput -Prompt "Please enter the number of the episode you wish to open in your browser, or just press enter to open the homepage" `
                            -ErrorMessage "Please only input a number or press enter, and ensure you're only looking for an episode you have listened to already" `
                            -CheckMethod {($args[0] -le $MaxEpisode)} `
                            -IsInt
            $TapeNumber = Get-TapeContent -TapeNumber $TapeIndex -ContentType Number
            if ($TapeIndex -eq 0) {Start-Process "https://snarp.github.io/magnus_archives_transcripts/"; break}
            else {Start-Process "https://snarp.github.io/magnus_archives_transcripts/episode/$TapeNumber.html"}
            
        }
    }

} while ($true) 