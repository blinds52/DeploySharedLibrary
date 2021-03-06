function Convert-ISOtoVHD
{
<#
.SYNOPSIS
Convert an Windows Installation ISO to VHD
.DESCRIPTION
Will mount the ISO image (if not already mounted)
.NOTES
Copyright Keith Garner, Deployment Live.
#>
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ImagePath,
        [parameter(Mandatory=$true)]
        [string] $VHDFile,
        [parameter(Mandatory=$true,ParameterSetName="Index")]
        [int]    $Index,
        [parameter(Mandatory=$true,ParameterSetName="Name")]
        [string] $Name,
        [int]    $Generation = 1,
        [uint64]  $SizeBytes = 120GB,

        [scriptblock] $AdditionalContent,
        $AdditionalContentArgs,

        [switch] $Turbo = $true,
        [switch] $Force
    )

    if ( -not ( Test-Path $ImagePath ) ) { throw "missing ISOFile: $ImagePath" }

    $OKToDismount= $False
    $FoundVolume = get-diskimage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Get-Volume
    if ( -not $FoundVolume )
    {
        Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -Access ReadOnly
        start-sleep -Milliseconds 250
        $FoundVolume = get-diskimage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Get-Volume
        $OKToDismount= $True
    }

    if ( -not $FoundVolume )
    {
        throw "Missing ISO: $ImagePath"
    }

    $FoundVolume | Out-String | Write-Verbose
    $DriveLetter =  $FoundVolume | %{ "$($_.DriveLetter)`:" }

    if ( -not $DriveLetter ) {throw "DriveLetter not found after mounting" }
    if ( -not ( Test-Path "$DriveLetter\Sources\Install.wim" ) ) { throw "Windows Install.wim not found" }

    $StdArgs = $PSBoundParameters | get-HashTableSubset -exclude ImagePath
    Convert-WIMtoVHD -ImagePath "$DriveLetter\Sources\Install.wim" @StdArgs | Out-Default

    if ( $OKToDismount )
    {
        Dismount-DiskImage -ImagePath $ImagePath | out-string
    }

}
