

Write-Host "What would you like to do? "
Write-Host "`n     A) Collect new baseline? "
Write-Host "     B) Begin monitoring files with saved baseline? "

Function Calculate-File-Hash($filepath){
    $filehash = Get-FileHash $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        #Delete existing baseline
        Remove-Item -Path .\baseline.txt
    }
}

$response = Read-Host -Prompt "`nPlease enter 'A' or 'B'"
if ($response -eq "A".ToUpper()) {
    #Delete baseline if it already exists 
    Erase-Baseline-If-Already-Exists
    #Calculate Hash from the target files and store in baseline.txt
    
    #Collect all files in the target folder 
    $files =  Get-Childitem -Path .\Files
    
    #For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    $fileHashDictionary = @{}
    
    #Load file hash from baseline.txt and store them in a dictionary 
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    foreach ($f in $filePathsAndHashes){
        $fileHashDictionary.Add($f.Split("|")[0],$f.Split("|")[1])
    }
    
    #Begin continously(forever loop) monitoring files with saved baseline
    while ($true) {
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path .\Files
        #for each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files){
            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

            #Notify if a new file has been created 
            if ($fileHashDictionary[$hash.Path] -eq $null){
                #a new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Yellow
            }
            # notify if a new file has been changed 
            else{
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                #the file has not been changed
                }
                else {
                #the file has been changed/compromised notify the user 
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Green

                }
            }

            

        }
        foreach ($key in $fileHashDictionary.Keys){
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                    #One of the baseline files has been deleted, notify user
                    Write-Host "$($key) has been deleted!!!!" -ForegroundColor Red
            }
        }

    }
}