# Morpheus Windows Agent Installation using a local MSI file.

## Installation Steps

### 1. Download the MSI File
```powershell
Invoke-WebRequest -UseBasicParsing -Uri "https://morpheus.mihailab.cloud/public-archives/link?s=5381123097154a17&fn=MorpheusAgentSetup-4_5.msi" -OutFile "C:\Users\Administrator\Downloads\MorpheusAgentSetup-4_5.msi"
```

### 2. Download the Installation Script:
Download the installation script to your Windows VM
`morpheus_agent_install.ps1`

### 3. Edit Configuration
Modify lines 64-65 in the script to update:
- API Key (`apiKey=`)
- Host URL (`host=`)

### 4. Run the Script
```powershell
.\morpheus_agent_install.ps1
```
