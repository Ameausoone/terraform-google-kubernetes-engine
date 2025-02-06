resource "google_gke_backup_backup_plan" "backup" {
  count = (var.backup_cron_schedule != null || var.backup_rpo_target_in_minutes != null) && var.gke_backup_agent_config ? 1 : 0

  # Plan name and cluster identification
  name    = "${google_container_cluster.primary.name}-backup-plan"
  cluster = google_container_cluster.primary.id

  # Location (fallback to region or derived from zones)
  location = try(var.region, substr(var.zones[0], 0, length(var.zones[0]) - 2))

  backup_config {
    include_volume_data = try(var.backup_config.include_volume_data, true)
    include_secrets     = try(var.backup_config.include_secrets, true)
    all_namespaces      = true
  }

  dynamic "backup_schedule" {
    for_each = var.backup_cron_schedule != null ? [var.backup_cron_schedule] : []
    content {
      cron_schedule = backup_schedule.value
    }
  }

  dynamic "backup_schedule" {
    # If both backup_schedule and rpo_config are specified, backup_schedule have the precedence
    for_each = var.backup_rpo_target_in_minutes != null && var.backup_cron_schedule == null ? [var.backup_rpo_target_in_minutes] : []
    content {
      rpo_config {
        target_rpo_minutes = backup_schedule.value
      }
    }
  }

  retention_policy {
    backup_retain_days = var.backup_retain_days
  }
}