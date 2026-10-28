<#
.SYNOPSIS
    Generate the hex value for DHCP option 119 (domain search list, RFC 3397).

.EXAMPLE
    .\dhcp-option-119-generate.ps1 z1.prod.hotgarbagellc.net prod.hotgarbagellc.net hotgarbagellc.net
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Domains
)

$ErrorActionPreference = 'Stop'

# Encode domains per RFC 1035 section 4.1.4, using suffix compression pointers
$data = [System.Collections.Generic.List[byte]]::new()
# Maps a domain suffix (e.g. "hotgarbagellc.net") to its offset in $data
$suffixOffsets = @{}

foreach ($domain in $Domains) {
    $labels = @($domain.Trim().TrimEnd('.').Split('.') | Where-Object { $_ })
    $compressed = $false

    for ($i = 0; $i -lt $labels.Count; $i++) {
        $suffix = ($labels[$i..($labels.Count - 1)] -join '.').ToLowerInvariant()

        if ($suffixOffsets.ContainsKey($suffix)) {
            $offset = $suffixOffsets[$suffix]
            $data.Add([byte](0xC0 -bor ($offset -shr 8)))
            $data.Add([byte]($offset -band 0xFF))
            $compressed = $true
            break
        }

        $label = [System.Text.Encoding]::ASCII.GetBytes($labels[$i])
        if ($label.Length -gt 63) {
            throw "Label '$($labels[$i])' exceeds 63 characters"
        }

        # Pointers can only address the first 0x3FFF bytes
        if ($data.Count -le 0x3FFF) {
            $suffixOffsets[$suffix] = $data.Count
        }

        $data.Add([byte]$label.Length)
        $data.AddRange($label)
    }

    if (-not $compressed) {
        $data.Add([byte]0x00)
    }
}

$hexString = ($data | ForEach-Object { $_.ToString('x2') }) -join ':'

Write-Output 'domains:'
$Domains | ForEach-Object { Write-Output "  $_" }
Write-Output "hexString: $hexString"
