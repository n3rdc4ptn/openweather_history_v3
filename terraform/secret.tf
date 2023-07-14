resource "google_secret_manager_secret" "openweathermap-apikey" {
  secret_id = "openweathermap-apikey"

  labels = {
    app = "openweathermaphistory"
  }

  replication {
    automatic = true
  }
}


resource "google_secret_manager_secret_version" "current-key" {
  secret = google_secret_manager_secret.openweathermap-apikey.id

  secret_data = var.openweathermap_apikey
}

resource "google_secret_manager_secret_iam_member" "member" {
  project   = google_secret_manager_secret.openweathermap-apikey.project
  secret_id = google_secret_manager_secret.openweathermap-apikey.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cf-collect-data.email}"
}
