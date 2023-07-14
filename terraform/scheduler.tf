resource "google_service_account" "cf-caller-scheduler" {
  account_id   = "cf-caller-scheduler"
  display_name = "A service account for invoking the OpenWeatherMap History API cloud functions"

}

# Cloud scheduler for fetching data hourly
resource "google_cloud_scheduler_job" "job" {
  name             = "collect-data-job"
  description      = "Collect data hourly"
  schedule         = "0 * * * *"
  time_zone        = "Europe/Berlin"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.func-collect-data.service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.cf-caller-scheduler.email
    }
  }
}
