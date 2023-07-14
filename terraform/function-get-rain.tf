resource "google_service_account" "cf-get-rain" {
  account_id   = "cf-get-rain"
  display_name = "Cloud Function Get Rain"
}


resource "google_cloudfunctions2_function" "func-get-rain" {
  name        = "get-rain-1"
  description = "Get rain data from BigQuery"

  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "get-rain"

    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.bucket_object.name
      }
    }
  }

  service_config {
    available_memory   = "265Mi"
    min_instance_count = 0
    max_instance_count = 5

    timeout_seconds = 60

    service_account_email = google_service_account.cf-get-rain.email

    environment_variables = {
      BIGQUERY_DATASET_ID = google_bigquery_dataset.dataset.dataset_id
      BIGQUERY_TABLE_ID   = google_bigquery_table.default.table_id
    }
  }

  labels = {
    app = "openweathermaphistory"
  }
}

resource "google_cloudfunctions2_function_iam_member" "get_rain_invoker" {
  project        = google_cloudfunctions2_function.func-get-rain.project
  location       = google_cloudfunctions2_function.func-get-rain.location
  cloud_function = google_cloudfunctions2_function.func-get-rain.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.apigateway.email}"
}

resource "google_cloud_run_service_iam_member" "get_rain_invoker" {
  project  = google_cloudfunctions2_function.func-get-rain.project
  location = google_cloudfunctions2_function.func-get-rain.location
  service  = google_cloudfunctions2_function.func-get-rain.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.apigateway.email}"
}
