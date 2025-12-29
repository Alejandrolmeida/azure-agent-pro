# Email Template: Microsoft Support - Zombie Transactions Issue

## Subject Line Options

**Option 1 (Concise):**
```
Azure SQL Database - Orphaned Transactions Blocking 1.2TB Space Reclamation
```

**Option 2 (Technical):**
```
Case: Azure SQL DB - 8 Zombie Transactions (47 days) - Failover Assistance Needed
```

**Option 3 (Urgent):**
```
URGENT: Azure SQL Database Growth Issue - Orphaned Transactions Blocking Storage
```

---

## Email Body (English)

```
Dear Microsoft Azure Support Team,

I am reaching out regarding an Azure SQL Database experiencing abnormal storage growth 
and require guidance on the best remediation approach.

## ENVIRONMENT DETAILS

- **Server**: [your-server].database.windows.net
- **Database**: [your-database-name]
- **Service Tier**: General Purpose GP_Gen5_14 (or your tier)
- **Region**: [West Europe / your region]
- **Subscription ID**: [your-subscription-id]
- **Resource Group**: [your-resource-group]

## PROBLEM SUMMARY

Our database has been experiencing abnormal growth at approximately 150 GB per day 
for the past 7 days. After extensive diagnostics, we have identified the root cause:

**8 orphaned transactions (session_id = NULL) active since November 12, 2025 (47 days ago)**

## DIAGNOSTIC RESULTS

We executed comprehensive T-SQL diagnostics (attached script: zombie-diagnosis-interactive.sql) 
with the following findings:

**Zombie Transactions Detected:**
- Total zombie transactions: 8
- All transactions show session_id = NULL (orphaned)
- Oldest transaction: 47 days old (since 2025-11-12 22:34:31 UTC)
- Transaction IDs: 1294, 1297, 1299, 1301, 1304, 1306, 9330, 13751

**Storage Impact:**
- Total allocated space: 2,556 GB
- Used space: 1,316 GB (51.5%)
- **Unallocated space blocked by zombies: 1,240 GB (48.5%)**
- Growth rate: ~150 GB/day (cannot be reclaimed)

**Transaction Types:**
- 6 transactions: worktable (type 2)
- 1 transaction: LobStorageProviderSession
- 1 transaction: SELECT query

**Validation Performed:**
- ✅ ADR (Accelerated Database Recovery): PVS = 0 KB (not the issue)
- ✅ User tables: Largest table only 1.15 GB (not the issue)
- ✅ Log file: 1.1% usage, 36 GB total (healthy)
- ✅ Confirmed: Issue is orphaned transactions blocking space reclamation

## ATTEMPTED SOLUTIONS

We understand that orphaned transactions (session_id = NULL) cannot be terminated 
using KILL commands as there is no active session to target.

## REQUESTED ASSISTANCE

We have identified that a **manual database failover** is the appropriate solution 
to clear these zombie transactions. However, before proceeding, we would like 
Microsoft's guidance on:

1. **Should we perform the failover ourselves via Azure CLI/Portal?**
   - Command: `az sql db failover --resource-group <rg> --server <server> --name <db>`
   - Expected downtime: 30-60 seconds
   - We have a maintenance window available: [suggest date/time in UTC]

2. **Or would Microsoft prefer to handle this failover through Support?**
   - To ensure proper monitoring and validation
   - To capture any additional diagnostics during the process

3. **Post-failover expectations:**
   - How long should space reclamation take? (we estimate 24-48 hours)
   - Should we expect any performance impacts during recovery?
   - Are there any additional DMV queries you recommend for validation?

4. **Root cause investigation:**
   - What typically causes orphaned transactions to persist for 47+ days?
   - Are there preventive measures we should implement?
   - Should we enable additional monitoring/alerts?

## BUSINESS IMPACT

- **Current impact**: Storage costs increasing ($150-200/day estimated)
- **Risk**: Database may reach storage limit if left unresolved
- **SLA**: Production database, but can schedule maintenance window
- **Users**: Can tolerate 30-60 second downtime during low-traffic period

## ATTACHMENTS

1. **zombie-diagnosis-interactive.sql** - Complete diagnostic script
2. **Full diagnostic results** - Output from SQL Server Management Studio
3. **Query Store data** (if needed) - Available upon request

## PREFERRED ACTION

We are ready to execute the failover during our next maintenance window 
([date/time in UTC]), but wanted Microsoft's validation that this is the 
correct approach given the specific circumstances (47-day-old orphaned transactions).

Please advise on the best path forward and whether you would like us to proceed 
independently or if Microsoft Support should handle the failover operation.

Thank you for your assistance.

Best regards,
[Your Name]
[Your Title]
[Company Name]
[Contact Email]
[Phone Number]
[Azure Subscription ID]
```

---

## Quick Copy Version (Shorter)

```
Subject: Azure SQL DB - Orphaned Transactions Blocking 1.2TB Space - Failover Guidance Needed

Dear Microsoft Support,

We have an Azure SQL Database with 8 orphaned transactions (session_id = NULL) 
active for 47 days, blocking 1,240 GB of space reclamation and causing 150 GB/day 
abnormal growth.

Environment:
- Server: [your-server].database.windows.net
- Database: [your-database]
- Tier: General Purpose GP_Gen5_14
- Subscription: [your-sub-id]

Diagnostic Summary:
- 8 zombie transactions since Nov 12, 2025 (transaction IDs: 1294, 1297, 1299, 
  1301, 1304, 1306, 9330, 13751)
- All show session_id = NULL (cannot use KILL command)
- 1,240 GB unallocated space blocked
- ADR PVS = 0 KB (ruled out)
- User tables normal (max 1.15 GB)

Question:
Should we execute manual failover ourselves (`az sql db failover`) or would 
Microsoft prefer to handle it through Support? We have a maintenance window 
available and can tolerate 30-60 seconds downtime.

We have complete diagnostic scripts and results available upon request.

Thank you,
[Your Name]
[Contact Info]
```

---

## IMPORTANT NOTES

1. **Replace placeholders** with your actual values:
   - [your-server] → Your Azure SQL server name
   - [your-database-name] → Your database name
   - [your-subscription-id] → Your Azure subscription ID
   - [your-resource-group] → Your resource group name
   - [date/time in UTC] → Your preferred maintenance window
   - [Your Name/Title/Company] → Your contact information

2. **Attach the diagnostic script**:
   - File: `docs/queries/zombie-diagnosis-interactive.sql`
   - Or export the results as .txt from SSMS

3. **Open a support case**:
   - Azure Portal → Help + Support → New Support Request
   - Issue Type: Technical
   - Service: SQL Database
   - Problem Type: Connectivity
   - Problem Subtype: Other connectivity issues

4. **Severity Level**:
   - Recommend: **Severity B** (Moderate business impact)
   - Or **Severity C** if you have a scheduled maintenance window

5. **Expected Response Time**:
   - Severity B: < 4 hours (business hours)
   - Severity C: < 8 hours (business hours)
