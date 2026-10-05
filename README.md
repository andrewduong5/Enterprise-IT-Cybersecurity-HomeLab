# Enterprise IT & Cybersecurity Home Lab

[![Environment](https://img.shields.io/badge/Environment-VirtualBox%20%7C%20Windows%20Server%202022-blue)](#)
[![Identity](https://img.shields.io/badge/Directory%20Services-Active%20Directory%20Domain%20Services-green)](#)
[![Automation](https://img.shields.io/badge/Scripting-PowerShell-blueviolet)](#)
[![Status](https://img.shields.io/badge/Project%20Status-Active%20Development-success)](#)

## Overview
This repository documents the design, deployment, and security hardening of a modular enterprise homelab environment. Designed to validate and build upon core competencies from **CompTIA A+**, **AWS Certified Cloud Practitioner**, and real-world systems administration practices, this project simulates production enterprise workflows across identity governance, network service management, access control, and containerized services.

---

## Lab Architecture & Milestones

| Phase | Technical Focus | Core Deliverables | Status |
| :--- | :--- | :--- | :--- |
| **Phase 1** | **Identity & Access Management (AD DS)** | OU hierarchy, PowerShell bulk onboarding, GPO Account Lockout | **Completed** |
| **Phase 2** | **File Storage & Layered Access Control** | SMB network shares, NTFS inheritance removal, RBAC validation | In Progress |
| **Phase 3** | **Core Network Services** | DNS Forward/Reverse zones, static IP addressing, DHCP planning | Queued |
| **Phase 4** | **Secure Remote Administration & Segmentation** | RDP hardening, SSH key-based access, virtual network routing | Queued |
| **Phase 5** | **Containerized Infrastructure (Docker)** | Linux microservices, network bridge configurations, Portainer | Queued |

---

## Phase 1: Active Directory Identity Architecture & Automation

### 1. Enterprise Organizational Unit (OU) Design
Implemented a tiered parent-child OU structure under `corp.homelab.local` to cleanly separate human accounts, endpoints, and privileged administrators:
* `OU=Company` (Parent Root)
  * `OU=Users`: Standard business identities
  * `OU=Groups`: Security and functional access groups
  * `OU=Admins`: Dedicated administrative accounts segregated to prevent privilege escalation
  * `OU=Computers`: Domain workstation endpoints

### 2. Automated User & Group Provisioning (PowerShell)
Developed and executed a PowerShell automation script (`01-Active-Directory-Identity/scripts/Provision-CompanyUsers.ps1`) to:
* Bulk-provision 12 departmental user accounts across 6 business units (IT, Security, HR, Finance, Marketing, Sales).
* Dynamically generate standard `sAMAccountName` and `UserPrincipalName` attributes.
* Automatically generate departmental security groups (`Dept-*`) and assign accounts to both their functional department group and a universal `Staff` group.
* Enforce baseline initial credential standards.

### 3. Domain Hardening via Group Policy (GPO)
Mitigated brute-force and credential stuffing threats across the domain by enforcing an enterprise **Account Lockout Policy** in the Default Domain Policy:
* **Account lockout threshold:** 5 invalid logon attempts
* **Account lockout duration:** 30 minutes
* **Reset account lockout counter after:** 30 minutes

---

## Phase 1 Verification & Proof of Work

### Active Directory Hierarchy & User Population
![AD Hierarchy](01-Active-Directory-Identity/screenshots/01_AD_OU_Hierarchy.png)

### Departmental Security Groups
![Department Groups](01-Active-Directory-Identity/screenshots/02_Department_Groups.png)

### Group Policy Account Lockout Enforcement
![Lockout GPO](01-Active-Directory-Identity/screenshots/03_Account_Lockout_GPO.png)

### Domain Controller DNS Name Resolution
![DNS Resolution](01-Active-Directory-Identity/screenshots/04_DNS_Verification.png)

---

## Next Steps
- Deploy multi-tier network file shares (`CompanyData`) with granular NTFS permissions.
- Validate Role-Based Access Control (RBAC) using the Active Directory Effective Access engine.