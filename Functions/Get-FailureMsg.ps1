Function Get-FailureMsg {
    [cmdletbinding()]
    param(
        $TestName,
        $Results
    )
    
    # Escape regex characters to make them literals
    $Test = $TestName.Replace('[','\[')
    $Test = $Test.Replace('(','\(')
    $Test = $Test.Replace(')','\)')
    $Test = $Test.Replace('.','\.')
    $Match = "$Test failed:"
    Write-Verbose "Matching to $Match"
    $Failure = $Results | Select-String -Pattern $Match
    If ($Failure) {
        $FailureIndex = $Results.IndexOf("$Failure")
        $Failure = ($Failure.ToString()).Substring(($Failure.ToString()).LastIndexOf('(Failure)')+10)
        # If the only word on the line is "(Failure)" then the full message is split across the next two lines
        if (!$failure) {
            Write-Verbose "Failure message is empty. Reading next two lines"
            $FailureStart = $FailureIndex + 1
            $FailureEnd = $FailureStart + 1
            $Failure = $Results["$FailureStart"]
            $Failure += " " + $Results["$FailureEnd"]
        }
        return $Failure
    }
    Else {
        Write-Verbose "No failure message"
    }
}