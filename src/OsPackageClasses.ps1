Class OsPackage
{
    [String] $Name
    [String] $Version
    [String] $Type

}

Class MacOsPackage:OsPackage
{
}

Class MacOsCaskPackage:MacOsPackage
{
}

Class MacOsFormulaPackage:MacOsPackage
{
}
