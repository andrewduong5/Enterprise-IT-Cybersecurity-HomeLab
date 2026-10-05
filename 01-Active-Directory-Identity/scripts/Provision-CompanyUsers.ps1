<#
.SYNOPSIS
    Automated bulk provisioning script for Active Directory users and departmental security groups.
.DESCRIPTION
    Creates organizational groups (Staff + Department Groups) and provisions 12 user accounts
    across 6 business units with standardized sAMAccountNames, UPNs, initial passwords,
    and automatic group memberships.
.NOTES
    Domain: corp.homelab.local
    Environment: Windows Server 2022 Active Directory Domain Services (AD DS)
#>

# Import Active Directory Module
Import-Module ActiveDirectory

# Define Organizational Units and Domain Base
$DomainDN   = "DC=corp,DC=homelab,DC=local"
$UsersOU    = "OU=Users,OU=Company,$DomainDN"
$GroupsOU   = "OU=Groups,OU=Company,$DomainDN"

# Standard Default Password for Onboarding
$DefaultPassword = ConvertTo-SecureString "P@ssword123!" -AsPlainText -Force

# 1. Define and Create Baseline Universal Group (Staff)
if (-not (Get-ADGroup -Filter "Name -eq 'Staff'" -SearchBase $GroupsOU -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name "Staff" -GroupScope Global -GroupCategory Security -Path $GroupsOU -Description "All active company employees"
    Write-Host "[+] Created baseline group: Staff" -ForegroundColor Green
}

# 2. Define User Data (12 Users Across 6 Departments)
$Employees = @(
    # IT Department
    @{ FirstName = "John";    LastName = "Doe";      Department = "IT";        Title = "Helpdesk Technician" },
    @{ FirstName = "Jane";    LastName = "Smith";    Department = "IT";        Title = "Systems Administrator" },

    # Security Department
    @{ FirstName = "Alice";   LastName = "Johnson";  Department = "Security";  Title = "SOC Analyst" },
    @{ FirstName = "Bob";     LastName = "Williams"; Department = "Security";  Title = "Security Engineer" },

    # Human Resources
    @{ FirstName = "Mary";    LastName = "Brown";    Department = "HR";        Title = "HR Coordinator" },
    @{ FirstName = "Emily";   LastName = "Davis";    Department = "HR";        Title = "HR Manager" },

    # Finance Department
    @{ FirstName = "Michael"; LastName = "Miller";   Department = "Finance";   Title = "Staff Accountant" },
    @{ FirstName = "Sarah";   LastName = "Wilson";   Department = "Finance";   Title = "Financial Analyst" },

    # Marketing Department
    @{ FirstName = "David";   LastName = "Moore";    Department = "Marketing"; Title = "Marketing Specialist" },
    @{ FirstName = "Laura";   LastName = "Taylor";   Department = "Marketing"; Title = "Content Strategist" },

    # Sales Department
    @{ FirstName = "James";   LastName = "Anderson"; Department = "Sales";     Title = "Account Executive" },
    @{ FirstName = "Rachel";  LastName = "Thomas";   Department = "Sales";     Title = "Sales Representative" }
)

# 3. Process Departments and Create Departmental Security Groups
$Departments = $Employees | Select-Object -ExpandProperty Department -Unique

foreach ($Dept in $Departments) {
    $GroupName = "Dept-$Dept"
    if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -SearchBase $GroupsOU -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $GroupName -GroupScope Global -GroupCategory Security -Path $GroupsOU -Description "Members of $Dept Department"
        Write-Host "[+] Created security group: $GroupName" -ForegroundColor Green
    }
}

# 4. Provision Users and Assign Memberships
foreach ($User in $Employees) {
    # Generate standard naming conventions
    $SAMAccount = ($User.FirstName.Substring(0,1) + $User.LastName).ToLower() # e.g., jdoe
    $UPN        = "$SAMAccount@corp.homelab.local"
    $DisplayName = "$($User.FirstName) $($User.LastName)"
    $DeptGroup  = "Dept-$($User.Department)"

    # Check if user already exists
    if (-not (Get-ADUser -Filter "sAMAccountName -eq '$SAMAccount'" -SearchBase $UsersOU -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name $DisplayName `
            -GivenName $User.FirstName `
            -Surname $User.LastName `
            -DisplayName $DisplayName `
            -SamAccountName $SAMAccount `
            -UserPrincipalName $UPN `
            -Path $UsersOU `
            -AccountPassword $DefaultPassword `
            -Enabled $true `
            -Department $User.Department `
            -Title $User.Title `
            -ChangePasswordAtLogon $false

        # Add user to standard 'Staff' group and departmental group
        Add-ADGroupMember -Identity "Staff" -Members $SAMAccount
        Add-ADGroupMember -Identity $DeptGroup -Members $SAMAccount

        Write-Host "[+] Provisioned user: $DisplayName ($SAMAccount) -> Added to Staff & $DeptGroup" -ForegroundColor Cyan
    } else {
        Write-Host "[-] User $SAMAccount already exists, skipping." -ForegroundColor Yellow
    }
}

Write-Host "`nBulk user provisioning and group mapping complete." -ForegroundColor Green