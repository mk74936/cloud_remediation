
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "remediation_rg" {
  name     = "cloudguard-autoheal-rg"
  location = "East US"
}

resource "azurerm_automation_account" "autoheal" {
  name                = "cloudguardAutohealAutomation"
  location            = azurerm_resource_group.remediation_rg.location
  resource_group_name = azurerm_resource_group.remediation_rg.name
  sku_name            = "Basic"
}

resource "azurerm_policy_definition" "block_rdp_policy" {
  name         = "cloudguard-block-rdp"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Block RDP Access on NSG"

  policy_rule = jsonencode({
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Network/networkSecurityGroups"
        },
        {
          "field": "Microsoft.Network/networkSecurityGroups/securityRules[*].destinationPortRange",
          "equals": "3389"
        }
      ]
    },
    "then": {
      "effect": "audit"
    }
  })

  metadata = jsonencode({
    "category" : "Security"
  })
}

resource "azurerm_policy_assignment" "assign_block_rdp" {
  name                 = "assign-cloudguard-block-rdp"
  policy_definition_id = azurerm_policy_definition.block_rdp_policy.id
  scope                = azurerm_resource_group.remediation_rg.id
}

resource "azurerm_policy_remediation" "remediate_rdp" {
  name                   = "cloudguard-remediate-rdp"
  policy_assignment_id   = azurerm_policy_assignment.assign_block_rdp.id
  resource_discovery_mode = "ReEvaluateCompliance"

  depends_on = [azurerm_policy_assignment.assign_block_rdp]
}

resource "azurerm_automation_runbook" "disable_rdp_runbook" {
  name                    = "DisableRDPAccess"
  location                = azurerm_resource_group.remediation_rg.location
  resource_group_name     = azurerm_resource_group.remediation_rg.name
  automation_account_name = azurerm_automation_account.autoheal.name
  log_verbose             = true
  log_progress            = true
  description             = "Auto-remediates RDP exposure"
  runbook_type            = "PowerShellWorkflow"
  publish_content_link {
    uri = "https://raw.githubusercontent.com/example-cloudguard/scripts/main/disable_rdp.ps1"
    version = "1.0.0.0"
  }
}

resource "azurerm_automation_runbook" "tag_vms_runbook" {
  name                    = "TagNonCompliantVMs"
  location                = azurerm_resource_group.remediation_rg.location
  resource_group_name     = azurerm_resource_group.remediation_rg.name
  automation_account_name = azurerm_automation_account.autoheal.name
  log_verbose             = true
  log_progress            = true
  description             = "Tags non-compliant VMs"
  runbook_type            = "PowerShellWorkflow"
  publish_content_link {
    uri = "https://raw.githubusercontent.com/<your-user>/<repo>/main/tag_noncompliant_vms.ps1"
    version = "1.0.0.0"
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "cloudguard-law"
  location            = azurerm_resource_group.remediation_rg.location
  resource_group_name = azurerm_resource_group.remediation_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "autoheal_ag" {
  name                = "cloudguard-autoheal-ag"
  resource_group_name = azurerm_resource_group.remediation_rg.name
  short_name          = "cgaheal"

  automation_runbook_receiver {
    name                    = "DisableRDPRunbookReceiver"
    automation_account_id   = azurerm_automation_account.autoheal.id
    runbook_name            = azurerm_automation_runbook.disable_rdp_runbook.name
    webhook_resource_id     = azurerm_automation_runbook.disable_rdp_runbook.id
    is_global_runbook       = false
    service_uri             = "https://management.azure.com/"  # Placeholder
  }
}
