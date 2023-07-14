# Generate an archive of the source code
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../function"
  output_path = "/tmp/function.zip"
  excludes    = ["node_modules/**"]
}

resource "google_storage_bucket" "bucket" {
  name     = "openweathermaphistory-sources"
  location = var.region

  uniform_bucket_level_access = true

  labels = {
    app = "openweathermaphistory"
  }
}

resource "google_storage_bucket_object" "bucket_object" {
  name   = "function-sources-${data.archive_file.source.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name

  source       = data.archive_file.source.output_path
  content_type = "application/zip"

  depends_on = [
    google_storage_bucket.bucket,
    data.archive_file.source
  ]
}
