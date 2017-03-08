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
    $Tests = Get-TestCases -Results $Sql 
    Out-JunitXml -Results $Tests -SaveTo $OutFile
}