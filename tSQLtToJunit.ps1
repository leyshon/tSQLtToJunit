Function Get-FailureMsg {
    [cmdletbinding()]
    param(
        $TestName,
        $Results
    )
    
    # Have to escape the [ character in the test name
    $Test = $TestName.Replace('[','\[')
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

Function Out-JunitXml {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$Results,
        $SaveTo
    )
    $Template = [XML] @"
<testsuites>
    <testsuite name="" file="">
    <testcase classname="" name="" time="">
        <failure type=""></failure>
    </testcase>
    </testsuite>
</testsuites>
"@
    
    $TestCase = (@($Template.Testsuites.Testsuite.Testcase)[0]).Clone()
    foreach ($Result in $Results){
        $NewTestCase = $TestCase.Clone()
        $NewTestCase.classname = $Result.Class.ToString()
        $NewTestCase.time = $Result.Time.ToString()
        $NewTestCase.name = $Result.Test.ToString()
        if($Result.Result -eq "Success"){   
            $NewTestCase.RemoveChild($NewTestCase.ChildNodes[0]) | Out-Null
        }
        else{
            $NewTestCase.Failure.InnerText = $Result.Reason
        }
        $Template.Testsuites.Testsuite.AppendChild($NewTestCase) > $null
    }

    $Template.testsuites.testsuite.testcase | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$Template.testsuites.testsuite.RemoveChild($_) }
    if ($SaveTo){
        $Template.Save($SaveTo)
    }
    else {
        return $Template
    }
}

Function Get-TestCases {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]$Results
    )
    
    $Start = $Results.IndexOf("|No|Test Case Name                                                                                            |Dur(ms)|Result |")
    $Start += 2
    $End = $Results.IndexOf("------------------------------------------------------------------------------")

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

Function Invoke-Tsqlt {
    [cmdletbinding()]
    param (
        $SqlServer,
        $Database,
        $OutFile
    )

    $SqlOut = $(Invoke-SqlCmd2 -ServerInstance $SqlServer -Query "exec tsqlt.RunAll" -Database $Database -Verbose -ErrorAction SilentlyContinue) 4>&1
    $Sql = New-Object System.Collections.ArrayList($null)
    foreach ($S in $SqlOut){
        $Sql.Add($S.Message) > $null
    }
    Write-Verbose ($Sql | Out-String)
    Get-TestCases -Results $Sql | Out-JunitXml -SaveTo $OutFile
}


