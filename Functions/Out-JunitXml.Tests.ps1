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

Describe "Out-JunitXml" {
    $Results = $ResultString.Split("`n").TrimEnd("`r")
    $Results = Get-TestCases -Results $Results
    It "Should return an XML object" {
        (Out-JunitXml -Results $Results).GetType() | Should be "xml"
    }
    It "returns a testcase element for each test" {       
        (Out-JunitXml -Results $Results).TestSuites.TestSuite.TestCase.Count | Should be 11
    }
    It "returns no failure node" {
        $Results = $Results | ? {$_.Result -ne "failure"}
        ((Out-JunitXml -Results $Results).TestSuites.TestSuite.TestCase | ? {$_.failure -ne $null}).Count | Should be 0
    }
    It "returns 2 failure nodes" {
        ((Out-JunitXml -Results $Results).TestSuites.TestSuite.TestCase | ? {$_.failure -ne $null}).Count | Should be 2
    }
    It "substitutes in the class name" {
        (Out-JunitXml -Results $Results).TestSuites.TestSuite.TestCase.Classname | Should be "[AcceleratorTests]"
    }
}