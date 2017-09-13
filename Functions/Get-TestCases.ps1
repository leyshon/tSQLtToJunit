Function Get-TestCases {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$Results
    )
    
    $HeaderRegex = "\|No\|Test Case Name.*\|Dur\(ms\)\|Result \|"
    $Header = $Results -match $HeaderRegex
    $Start = $Results.IndexOf("$Header")
    $Start += 2
    $FooterRegex = "^---------*-$"
    $Footer = ($Results -match $FooterRegex)[0]
    #Write-Verbose $Footer
    $End = $Results.IndexOf("$Footer")
    Write-Verbose $End

    $Cases = @()
    for ($i=$Start; $i -lt $End; $i++){
        $Cases += $Results[$i]
    }

    $Failures = Get-FailureMsg -Results $Results
    
    $TestCases = @()
    foreach ($Case in $Cases) {
        $Test = New-Object System.object
        $Test | Add-Member -Type NoteProperty -Name id -Value $Case.Split("|")[1]
        $Test | Add-Member -Type NoteProperty -Name class -Value ($Case.Split("|")[2]).Split(".")[0].TrimStart().TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name test `
                           -Value ($Case.Split("|")[2]).Split([string[]]"$($($Case.Split("|")[2]).Split(".")[0]).", [StringSplitOptions]"None")[1].TrimStart().TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name time -Value $Case.Split("|")[3].TrimStart().TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name result -Value $Case.Split("|")[4].TrimStart().TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name reason -Value ($Failures | Where-Object {$_.test -eq "$($test.class).$($test.test)"}).reason
        $TestCases += $Test
    }
    Return $TestCases
}