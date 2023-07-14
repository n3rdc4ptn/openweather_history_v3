resource "google_service_account" "apigateway" {
  account_id   = "apigateway"
  display_name = "API Gateway"
}

resource "google_api_gateway_api" "openweathermap_api" {
  provider = google-beta
  api_id   = "openweathermaphistory-api"
}

resource "random_id" "server" {
  byte_length = 8
  keepers = {
    first = "${filemd5("${path.module}/openapi-functions.yml.tpl")}"
  }
}

resource "google_api_gateway_api_config" "api_cfg" {
  provider      = google-beta
  api           = google_api_gateway_api.openweathermap_api.api_id
  api_config_id = "openweathermaphistory-api-cfg-${random_id.server.hex}-2"

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = base64encode(templatefile("${path.module}/openapi-functions.yml.tpl", {
        get_rain_forecast_url = google_cloudfunctions2_function.func-get-rain.service_config[0].uri
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.apigateway.email
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "api_gw" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_cfg.id
  gateway_id = "openweathermaphistory-api-gw"
}
