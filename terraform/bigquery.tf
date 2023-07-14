resource "google_bigquery_dataset" "dataset" {
  dataset_id    = "openweathermap"
  friendly_name = "Open Weather Map"
  description   = "This dataset contains all data for the openweathermap history project."
  location      = "EU"

  labels = {
    env = "default"
    app = "openweathermaphistory"
  }

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "roles/bigquery.dataViewer"
    user_by_email = google_service_account.cf-get-rain.email
  }

  access {
    role          = "roles/bigquery.dataEditor"
    user_by_email = google_service_account.cf-collect-data.email
  }
}

resource "google_project_iam_member" "project" {
  project = google_bigquery_dataset.dataset.project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.cf-get-rain.email}"
}

resource "google_bigquery_table" "default" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "weather_data"

  deletion_protection = false

  time_partitioning {
    type          = "DAY"
    field         = "timestamp"
    expiration_ms = 31536000000
  }

  labels = {
    env = "default"
    app = "openweathermaphistory"
  }

  schema = <<EOF
[
  {
    "name": "timestamp",
    "type": "timestamp",
    "mode": "REQUIRED",
    "description": "The timestamp of the data point"
  },
  {
    "name": "position",
    "type": "GEOGRAPHY",
    "mode": "REQUIRED",
    "description": "The location of the data point"
  },
  {
    "name": "location_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "The name of the location"
  },
  {
    "name": "rain",
    "type": "FLOAT",
    "mode": "REQUIRED",
    "description": "The amount of rain in mm"
  },
  {
    "name": "timestamp_added",
    "type": "timestamp",
    "mode": "REQUIRED",
    "description": "The timestamp when the data point was added to the database"
  }
]
EOF

}
