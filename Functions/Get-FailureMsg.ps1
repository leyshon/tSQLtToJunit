Function Get-FailureMsg {
    [cmdletbinding()]
    param(
        $TestName,
        $Results
    )
    
    # Escape regex characters to make them literals
    <#
    $Test = $TestName.Replace('[','\[')
    $Test = $Test.Replace('(','\(')
    $Test = $Test.Replace(')','\)')
    $Test = $Test.Replace('.','\.')
    #>
    # "Querying ServerInstance" and "Test Execution Summary" bound the possible failure messages
    $FailureStartLine = (($Results | Select-String -Pattern "Querying ServerInstance *").LineNumber)
    $FailureEndLine = (($Results | Select-String -Pattern "\|Test Execution Summary\|").LineNumber) 

    # Index of the array starts at 0 but line numbers atart at 1. 
    # Also line numbers are actually the line after the pattern
    # For the first line then we have the right index. For the final line we want to strip out the text around Test Execution Summary
    $Failures = $Results[$FailureStartLine..($FailureEndLine - 3)] | Where-Object {$_}

    $Match = '(\[.*?]\.\[.*?])'
    $Split = [regex]::Split($Failures, $Match, [System.StringSplitOptions]::RemoveEmptyEntries)
    $Lines = ($Split | Select-String -Pattern $Match).LineNumber

    $FailureObj = @()
    foreach ($Line in $Lines) {
        switch ($Split[$Line].Length)
        {
            {$_ -le 9} {$Reason = ($Split[$Line]).TrimStart().TrimEnd()}
            {$_ -ge 10} {$Reason = ($Split[$Line].Substring($Split[$Line].LastIndexOf('(Failure)')+10)).TrimStart().TrimEnd()}
        }
        $Fail = New-Object System.Object
        $Fail | Add-Member -Type NoteProperty -Name test -Value $Split[($Line -1)]
        $Fail | Add-Member -Type NoteProperty -Name reason -Value $Reason
        $FailureObj += $Fail
    }

    return $FailureObj
    #return ($FailureObj | Where-Object {$_.test -eq $TestName}).reason
}