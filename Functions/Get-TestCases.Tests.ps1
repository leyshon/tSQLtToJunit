$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$Here\$Sut"

Import-Module "$here\..\tSQLtToJunit.psm1"

$ResultString = @"
Running Invoke-Sqlcmd2 with ParameterSet 'Ins-Que'.  Performing query 'exec tsqlt.RunAll'
Querying ServerInstance '(local)'
[AcceleratorTests].[test ready for experimentation if 2 particles] failed: (Failure) Expected: <1> but was: <0>
[AcceleratorTests].[test status message includes the number of particles] failed: (Failure) 
Expected: <The Accelerator is prepared with 3 particles. HAHA>
but was : <The Accelerator is prepared with 3 particles.>
 
+----------------------+
|Test Execution Summary|
+----------------------+
  
|No|Test Case Name                                                                                            |Dur(ms)|Result |
+--+----------------------------------------------------------------------------------------------------------+-------+-------+
|1 |[AcceleratorTests].[test a particle is included only if it fits inside the boundaries of the rectangle]   |    780|Success|
|2 |[AcceleratorTests].[test a particle within the rectangle is returned with an Id, Point Location and Value]|    283|Success|
|3 |[AcceleratorTests].[test a particle within the rectangle is returned]                                     |    220|Success|
|4 |[AcceleratorTests].[test email is not sent if we detected something other than higgs-boson]               |    297|Success|
|5 |[AcceleratorTests].[test email is sent if we detected a higgs-boson]                                      |    250|Success|
|6 |[AcceleratorTests].[test foreign key is not violated if Particle color is in Color table]                 |   1530|Success|
|7 |[AcceleratorTests].[test foreign key violated if Particle color is not in Color table]                    |   1327|Success|
|8 |[AcceleratorTests].[test no particles are in a rectangle when there are no particles in the table]        |    563|Success|
|9 |[AcceleratorTests].[test we are not ready for experimentation if there is only 1 particle]                |    236|Success|
|10|[AcceleratorTests].[test ready for experimentation if 2 particles]                                        |    234|Failure|
|11|[AcceleratorTests].[test status message includes the number of particles]                                 |    263|Failure|
------------------------------------------------------------------------------
Capture SQL Error
SQL Error:  Test Case Summary: 11 test case(s) executed, 9 succeeded, 2 failed, 0 errored.
------------------------------------------------------------------------------
"@

Describe "Get-TestCases" {
    $Output = $ResultString.Split("`n").TrimEnd("`r")
    $Results = @()
    Foreach ($Out in $Output) {
        $Results += $Out
    }
    $arrayValues = "id", "name", "duration", "result"
    It "The first entry is the first test case" {
        (Get-TestCases -Results $Results)[0].Test | Should be "[test a particle is included only if it fits inside the boundaries of the rectangle]"
    }
    It "The last entry is the last test case" {
        (Get-TestCases -Results $Results)[-1].Test | Should be "[test status message includes the number of particles]"
    }
    It "Should return the schema as the class" {
        (Get-TestCases -Results $Results).Class | Should be "[AcceleratorTests]"
    }
    It "Returns id, test, duration, result, reason and class in the noteproperties" {
        $Array = (((Get-TestCases -Results $Results) | Get-Member | ? {$_.MemberType -eq "NoteProperty"}).name)  
        $Array -contains "id" | Should be $true
        $Array -contains "test" | Should be $true
        $Array -contains "time" | Should be $true
        $Array -contains "result" | Should be $true
        $Array -contains "reason" | Should be $true
        $Array -contains "class" | Should be $true
    }
    It "contains a reason for failures" {
        (Get-TestCases -Results $Results)[9].reason | Should be "Expected: <1> but was: <0>"
    }
} 