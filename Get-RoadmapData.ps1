#region Settings and variables
$dataFolder = 'data'
$roadmapRSSUri = 'https://www.microsoft.com/en-us/microsoft-365/RoadmapFeatureRSS/'
#endregion Settings and variables

#region Functions
function ConvertRSSToFile {
	param(
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[Object]
		$InputObject
	)
	$matches = $null
	$publicPreviewDate = $null
	$GADate = $null 
	if ($InputObject.description -match '(?: *<br>Preview date: )([\w ]+)') {
		$publicPreviewDate = $matches.1
		$InputObject.description = $InputObject.description.Replace($matches.0, '')
	}
	if ($InputObject.description -match '(?: *<br>GA date: )([\w ]+)') {
		$GADate = $matches.1
		$InputObject.description = $InputObject.description.Replace($matches.0, '')
	}

	$objProperties = [ordered]@{
		'guid'                             = $InputObject.guid.'#text'
		'link'                             = $InputObject.link
		'category'                         = $InputObject.category | Sort-Object
		'title'                            = $InputObject.title
		'description'                      = $InputObject.description
		'pubDate'                          = $InputObject.pubDate
		'updated'                          = $InputObject.updated
		'publicDisclosureAvailabilityDate' = $GADate
		'publicPreviewDate'                = $publicPreviewDate
	}
	$processedObj = [PSCustomObject]$objProperties

	ConvertTo-Json -InputObject $processedObj
}
#endregion Functions

#region Processing
Write-Host 'Script starting'
$res = Invoke-RestMethod $roadmapRSSUri

if (-not (Test-Path $dataFolder)) {
	New-Item -ItemType Directory $dataFolder
	Write-Host "Creating $dataFolder folder"
}

foreach ($entry in $res) {
	<#
	$entry = $res[0]
	#>
	$fileName = $entry.guid.'#text'
	$jsonEntry = $entry | ConvertRSSToFile
	$outFilePath = Join-Path -Path $dataFolder -ChildPath "$fileName.json"
	$jsonEntry | Out-File -FilePath $outFilePath -Force
}
Write-Host 'Script finished'
#endregion Processing