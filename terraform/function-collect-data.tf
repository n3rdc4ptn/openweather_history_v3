resource "google_service_account" "cf-collect-data" {
  account_id   = "cf-collect-data"
  display_name = "Cloud Function Collect Data"
}


resource "google_cloudfunctions2_function" "func-collect-data" {
  name        = "collect-data-1"
  description = "Collect data from Openweathermap and save it to BigQuery"

  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "collect-data"

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.bucket_object.name
      }
    }
  }

  service_config {
    available_memory   = "256Mi"
    min_instance_count = 0
    max_instance_count = 1

    timeout_seconds = 60

    service_account_email = google_service_account.cf-collect-data.email

    environment_variables = {
      BIGQUERY_DATASET_ID = google_bigquery_dataset.dataset.dataset_id
      BIGQUERY_TABLE_ID   = google_bigquery_table.default.table_id
    }

    secret_environment_variables {
      key        = "OPENWEATHER_API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.openweathermap-apikey.secret_id
      version    = google_secret_manager_secret_version.current-key.version
    }
  }

  labels = {
    app = "openweathermaphistory"
  }
}

resource "google_cloudfunctions2_function_iam_member" "fetch-invoker" {
  project        = google_cloudfunctions2_function.func-collect-data.project
  location       = google_cloudfunctions2_function.func-collect-data.location
  cloud_function = google_cloudfunctions2_function.func-collect-data.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.cf-caller-scheduler.email}"
}

resource "google_cloud_run_service_iam_member" "cloud_run_invoker" {
  project  = google_cloudfunctions2_function.func-collect-data.project
  location = google_cloudfunctions2_function.func-collect-data.location
  service  = google_cloudfunctions2_function.func-collect-data.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.cf-caller-scheduler.email}"
}
