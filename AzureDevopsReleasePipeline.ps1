install-Module Az -Scope CurrentUser -Force -AllowClobber
$aSecret="$(Secret)"
$aApplicationID="$(ApplicationID)"
$aTennantId="$(DirectoryID)"
$Pass = ConvertTo-SecureString -String $aSecret -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $aApplicationID,$Pass
$workdir="$(System.DefaultWorkingDirectory)/repomonitoring"
$currentUTCtime = (Get-Date).ToUniversalTime()
git config --global user.email "mf@fast-sms.net"
git config --global user.name "Automat - Devops"
Write-Host $workdir
# Get the current universal time in the default string format.
Write-Host "Logging to Azure...."
Connect-AzAccount -Credential $Credential -TenantId $aTennantId -ServicePrincipal
$Subscriptions = Get-AzSubscription
ForEach ($Subscription in $Subscriptions) {
     $SubscriptionId = $Subscription.Id
     New-Item -Path $workdir -Name $SubscriptionId -ItemType "directory" -Force
     Set-AzContext -Subscription $SubscriptionId 
     $RGs = Get-AzResourceGroup
     foreach ($RG in $RGs) {
         New-Item -Path ($workdir+"\"+$SubscriptionId) -Name $RG.ResourceGroupName -ItemType "directory" -Force
           $DPMTs=get-azresourcegroupdeployment -ResourceGroupName $RG.ResourceGroupName
           foreach ($DPMT in $DPMTs) {
               Save-AzResourceGroupDeploymentTemplate -ResourceGroupName $RG.ResourceGroupName -DeploymentName $DPMT.DeploymentName -Path ($workdir+"\"+$SubscriptionId+"\"+$RG.ResourceGroupName+"\") -Force
           }
         get-azresourcegroupdeployment -ResourceGroupName $RG.ResourceGroupName|Out-File -FilePath ($workdir+"\"+$SubscriptionId+"\"+$RG.ResourceGroupName+".deployments.txt") -Force
         get-azresourcegroupdeployment -ResourceGroupName $RG.ResourceGroupName|ft|Out-File -FilePath ($workdir+"\"+$SubscriptionId+"\"+$RG.ResourceGroupName+".deployments-table.txt") -Force
         Export-AzResourceGroup -ResourceGroupName $RG.ResourceGroupName -IncludeParameterDefaultValue -IncludeComments -Force -Path ($workdir+"\"+$SubscriptionId+"\"+$RG.ResourceGroupName+".json")        
     }
 }
write-host "ECHO GIT CHECKOUT MAIN"
git checkout main
write-host "ECHO GIT STATUS"
git status
write-host "ECHO GIT ADD"
git add .
write-host "ECHO GIT COMMIT"
git commit -m $currentUTCtime
write-host "ECHO GIT STATUS"
git status
write-host "ECHO GIT PUSH"
git push origin
write-host "ECHO GIT STATUS"
git status
