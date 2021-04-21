## ArchiveIntegrity.ps1 - ElasticSearch / Exabeam DL Archive Checking Script.
#  In order to work properly, this script needs to be run via PowerShell from
#  an account with read access to the NAS share where the archive resides.
#  In the case of Kelsey-Seybold that share is \\kscfs\exabeam$ and is both
#  a CIFS & NFS share.

## Declare a list of snapshot IDs to compare againsts INDICES
#
$IDS =  New-Object -TypeName "System.Collections.ArrayList"

## Figure out which index file we need to use:
#
$d = get-childitem '\\kscfs\exabeam$\index-*' | select-object name
$d = $d.name
$d = $d | sort -Descending
$file = '\\kscfs\exabeam$\' + $d[0]

## Tell the user what we are about to do
#
Write-Output "========================================================================="
Write-Output "Exabeam DL NAS Archive Integrity Check - By John Morgan 2021-03-12"
Write-Output "-------------------------------------------------------------------------"
Write-Output "Index Files in Archive"
Write-Output $d
Write-Output "Processing $file"
Write-Output "-------------------------------------------------------------------------"
Write-Output " "

## Get current listing of indices
#  Later on we will compare this
#  to the contents of the file
#
$list = Get-ChildItem '\\kscfs\exabeam$\indices\'

## Grab the highest index-*** file to compare against the directory structure
#
$content = get-content $file
$json = $content | ConvertFrom-Json
$indices = $json.indices
$indexNames = $indices | get-member | Where-Object name -like "exabeam*" | Select-Object name

## Run a quick check to see what the index-xxx files are (and select the newest one).
#  HINT: If there are more than two we have an issue.
#
Write-Output "========================================================================="
Write-Output "Indices in Archive"
Write-Output "-------------------------------------------------------------------------"
Write-Output " "
Write-Output "INDEX NAME         ID                     SNAP                    MATCHES"
Write-Output "------------------ ---------------------- ----------------------  -------"
              
$missing = 0

## Go throug each entry in the JSON file and ensure that a corresponding directory
#  exists in \\kscfs\exabeam$\indices\
#
foreach($i in $indexNames.Name){
    [string]$id = $indices.$i.id 
    $IDS.add($id) > $null
    [string]$snap = $indices.$i.snapshots

    if($list.name -match $id)
    { 
        $matches = ' OK'
    } else { 
        $matches = '- Missing Indices'
        $missing++
    }

    Write-Output "$i $id $snap $matches"
}

Write-Output " "
Write-Output "Checking for Orphaned Indices"
Write-Output "-----------------------------------"

## Now go through the list of files in \\kscfs\exabeam$\indices
#  And see if any files exist for which there are no entires in
#  the index-xxx json file.
#
$orphaned = 0
foreach($l in $list.name){
    if($IDS -contains $l){
        ## No Output
    }else{
        write-output "$l is Orphanded"
        $orphaned++
    }
}

$indexCount = $IDS.count
Write-Output " "
Write-Output "==================================="
Write-Output "Total Indices: $indexCount"
Write-Output "Total Orphanded Indices: $orphaned"
Write-Output "Total Missing Indices: $missing"