┌─────────────────────────────────────────────────────────────────┐
│                    KITTEN SPACE MISSIONS API                     │
│                         ARCHITECTURE                             │
└─────────────────────────────────────────────────────────────────┘

    INTERNET (HTTPS Only)
         │
         │ Port 443
         ▼
┌─────────────────────────┐
│  Azure App Service (B1) │ ◄─── Managed Identity
│  ┌───────────────────┐  │
│  │ Kitten Space API  │  │      ┌──────────────┐
│  │ .NET 8, Linux     │  │──────┤ App Insights │
│  │ Auto-scale: 1-3   │  │      │ + Logs       │
│  └───────────────────┘  │      └──────────────┘
└────────────┬────────────┘
             │
             │ Private Endpoint
             │ (10.0.1.x)
             ▼
┌──────────────────────────┐
│  Virtual Network         │
│  (10.0.0.0/16)          │
│  ┌────────────────────┐ │      ┌──────────────┐
│  │ SQL Private EP     │─┼──────┤  Key Vault   │
│  │ Subnet: 10.0.1.0/24│ │      │  (Secrets)   │
│  └────────┬───────────┘ │      └──────────────┘
│           │              │
│           ▼              │
│  ┌────────────────────┐ │
│  │ Azure SQL Database │ │
│  │ Basic (5 DTU)      │ │
│  │ TDE Enabled        │ │
│  └────────────────────┘ │
└──────────────────────────┘

SECURITY CONTROLS:
✓ Managed Identity (No passwords)
✓ Private Endpoint (SQL isolated)
✓ HTTPS Only (TLS 1.2+)
✓ NSG Rules (Network filtering)
✓ Key Vault (Centralized secrets)
✓ RBAC (Least privilege)

ESTIMATED COST: ~$75-80/month (Dev)