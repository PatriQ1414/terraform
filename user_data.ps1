<powershell>

mkdir "c:\cwagent"

Invoke-WebRequest "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/AmazonCloudWatchAgent.zip" -OutFile "C:\cwagent\cwagent.zip"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Unzip {
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\cwagent\cwagent.zip" "C:\cwagent"

Set-Location "C:\cwagent"

.\install.ps1

Set-Location “C:\Program Files\Amazon\AmazonCloudWatchAgent”

.\amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m ec2 -c ssm:${ssm_cloudwatch_config} -s

</powershell>
