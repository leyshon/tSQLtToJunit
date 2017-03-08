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

    $TestCases = @()
    foreach ($Case in $Cases) {
        $Test = New-Object System.object
        $Test | Add-Member -Type NoteProperty -Name id -Value $Case.Split("|")[1]
        $Test | Add-Member -Type NoteProperty -Name class -Value ($Case.Split("|")[2]).Split(".")[0].TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name test -Value ($Case.Split("|")[2]).Split(".")[1].TrimEnd()
        $Test | Add-Member -Type NoteProperty -Name time -Value $Case.Split("|")[3].TrimStart()
        $Test | Add-Member -Type NoteProperty -Name result -Value $Case.Split("|")[4]
        $Test | Add-Member -Type NoteProperty -Name reason -Value (Get-FailureMsg -TestName $Test.test -Results $Results)
        $TestCases += $Test
    }
    Return $TestCases
}