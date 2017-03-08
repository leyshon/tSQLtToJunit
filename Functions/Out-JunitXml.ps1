# Heavily borrowed from http://merill.net/2013/06/creating-junitxunit-compatible-xml-test-tesults-in-powershell/
Function Out-JunitXml {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]$Results,
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
    # We must have a name for the testsuite.
    $Template.testsuites.testsuite.name = "tSQLt"
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