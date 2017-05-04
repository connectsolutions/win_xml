#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

Set-StrictMode -Version 2

function Compare-XmlDocs($actual, $expected) {
    if ($actual.Name -ne $expected.Name) {
        throw "Actual name not same as expected: actual=" + $actual.Name + ", expected=" + $expected.Name
    }
    ##attributes...

    if ($actual.Attributes -ne $null -and $expected.Attributes -ne $null) {
        if ($actual.Attributes.Count -ne $expected.Attributes.Count) {
           throw "attribute mismatch for actual=" + $actual.Name
        }
        for ($i=0;$i -lt $expected.Attributes.Count; $i =$i+1) {
            if ($expected.Attributes[$i].Name -ne $actual.Attributes[$i].Name) {
                throw "attribute name mismatch for actual=" + $actual.Name
            }
            if ($expected.Attributes[$i].Value -ne $actual.Attributes[$i].Value) {
                throw "attribute value mismatch for actual=" + $actual.Name
            }           
        }
    }

    ##children
    if ($expected.ChildNodes.Count -ne $actual.ChildNodes.Count)  {
        throw "child node mismatch. for actual=" + $actual.Name
    }

    for ($i=0;$i -lt $expected.ChildNodes.Count; $i =$i+1) {
        if (-not $actual.ChildNodes[$i]) {
            throw "actual missing child nodes. for actual=" + $actual.Name
        }
        Compare-XmlDocs $expected.ChildNodes[$i] $actual.ChildNodes[$i]
    }

    if ($expected.InnerText) {
        if ($expected.InnerText -ne $actual.InnerText) {
           throw "inner text mismatch for actual=" + $actual.Name
        }
    }
    elseif ($actual.InnerText) {
        throw "actual has inner text but expected does not for actual=" + $actual.Name
    }
}

function FindElementsByName($node, $name) {
    $elements = @()
    foreach ($n in $node.ChildNodes) {
        if ($n.Name -eq $name) {
            $elements += $n
        }
    }
    return ,$elements
}

function BackupFile($path) {
	$backuppath = $path + "." + [DateTime]::Now.ToString("yyyyMMdd-HHmmss");
	Copy-Item $path $backuppath;
	return $backuppath;
}

$params = Parse-Args $args -supports_check_mode $true
$dest = Get-AnsibleParam $params "path" -FailIfEmpty $true
$xml = Get-AnsibleParam $params "xml" -FailIfEmpty $true
$root = Get-AnsibleParam $params "root" -FailIfEmpty $false -Default "DocumentElement"
$backup = Get-AnsibleParam $params "backup" -FailIfEmpty $false -Default "no"

$result = New-Object PSObject @{
    win_xml = New-Object PSObject
    changed = $FALSE
}

If (-Not (Test-Path -Path $dest -PathType Leaf)){
    Fail-Json $result "Specified path $dest does exist or is not a file."
}
$ext = [System.IO.Path]::GetExtension($dest)
If ( $ext -notin '.xml'){
    Fail-Json $result "Specified path $dest is not a vaild file type; must be XML."
}

[xml]$xmlorig = Get-Content -Path $dest
$xmlnew = $xmlorig.Clone()
$xmlchild = [xml]$xml

$child = $xmlnew.CreateElement($xmlchild.DocumentElement.Name, $xmlnew.$root.NamespaceURI)
foreach ($attr in $xmlchild.DocumentElement.Attributes) {
    $child.SetAttribute($attr);
}

foreach ($node in $xmlchild.DocumentElement.ChildNodes) {
    $newnode = $xmlnew.CreateElement($node.Name, $xmlnew.$root.NamespaceURI)
    foreach ($attr in $node.Attributes) {
       $newnode.SetAttribute($attr)
    }
    $newnode.InnerText = $node.InnerText
    $child.AppendChild($newnode) | Out-Null
 }

$elements = FindElementsByName $xmlnew.$root $xmlchild.DocumentElement.Name

[bool]$add = $TRUE
if ($elements.Count) {
    foreach ($element in $elements) {
        try {
           Compare-XmlDocs $xmlchild.DocumentElement $element 
           $add = $FALSE
           break
        } catch {
           $_.InvocationInfo | Out-File c:\win_xml.log
        }
    }
    if ($add) {
        [void]$xmlnew.$root.AppendChild($child)
   }
} else {
    [void]$xmlnew.$root.AppendChild($child)
}

if ($add) {
   $result.changed = $TRUE
   if (-Not $params._ansible_check_mode) {
      if ($backup -eq "yes") {
         $result.backup = BackupFile($dest)
      }
      $result.msg = "xml added"
      $xmlnew.Save($dest)
   } else {
     $result.msg = "added check mode"
   }
} else {
  $result.msg = "already present"

Exit-Json $result