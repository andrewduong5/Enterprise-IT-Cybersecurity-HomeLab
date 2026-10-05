<#
.SYNOPSIS
    Provisions enterprise SMB network shares and enforces Role-Based Access Control (RBAC).
.DESCRIPTION
    Creates the directory hierarchy at C:\CompanyData, publishes the SMB share, disables
    NTFS inheritance on department shares, and applies explicit Access Control Entries (ACEs).
#>

$RootPath = "C:\CompanyData"
$Depts = @("Finance", "HR", "IT")

# 1. Create Root Directory & Department Subfolders
if (-not (Test-Path -Path $RootPath)) {
    New-Item -ItemType Directory -Path $RootPath | Out-Null
}

$Depts + "General" | ForEach-Object {
    $SubPath = Join-Path -Path $RootPath -ChildPath $_
    if (-not (Test-Path -Path $SubPath)) {
        New-Item -ItemType Directory -Path $SubPath | Out-Null
    }
}

# 2. Configure SMB Share
if (-not (Get-SmbShare -Name "CompanyData" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "CompanyData" -Path $RootPath -FullAccess "corp\Domain Admins" -ChangeAccess "corp\Staff" | Out-Null
}

# 3. Secure Department Folders (Break Inheritance & Set RBAC)
foreach ($Dept in $Depts) {
    $TargetFolder = Join-Path -Path $RootPath -ChildPath $Dept
    $GroupName = "corp\Dept-$Dept"
    
    $Acl = Get-Acl -Path $TargetFolder
    $Acl.SetAccessRuleProtection($true, $false)
    
    $AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "corp\Domain Admins", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $DeptRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $GroupName, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    
    $Acl.AddAccessRule($AdminRule)
    $Acl.AddAccessRule($SystemRule)
    $Acl.AddAccessRule($DeptRule)
    
    Set-Acl -Path $TargetFolder -AclObject $Acl
}

# 4. Configure General Share Permissions
$GeneralFolder = Join-Path -Path $RootPath -ChildPath "General"
$GeneralAcl = Get-Acl -Path $GeneralFolder
$GeneralAcl.SetAccessRuleProtection($true, $false)

$StaffRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "corp\Staff", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$GeneralAcl.AddAccessRule($AdminRule)
$GeneralAcl.AddAccessRule($SystemRule)
$GeneralAcl.AddAccessRule($StaffRule)
Set-Acl -Path $GeneralFolder -AclObject $GeneralAcl

Write-Host "Storage hierarchy and RBAC permissions successfully configured." -ForegroundColor Green