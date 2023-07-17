# Openweathermap History API v3

This project started as a small helper for a friends homeassistant as he wanted to activate his sprinklers only if it hasn't rained a lot in the last few days.
To to do that I built a small script which fetched the [Openweathermap](https://openweathermap.org/) APIs and saved the rain data to a database.
This data was then used by a small cloud function which outputs the sum for a specific range of days from now to the past.

As I am a big fan of Cloud Native development, the whole application then quickly became two cloud functions, one for fetching and one for outputting the sum.
In the last iteration I now use Bigquery as a database and two Cloud Functions in combination with Cloud Scheduler to repeatly fetch the data from openweathermap
and provide the endpoint for getting the rain sum. An API Gateway is then used to provide an URL for the caller to get the rain data and to provide rate limiting
as well as API tokens using Google Clouds API and Service keys.


You can use that project as an inspiration or to also deploy that API into your [Google Cloud](https://cloud.google.com/).
I used terraform to spin up the whole infrastructure.

## How to
To spin up the project yourself, you first need to check it out to your local machine. You also need to have [Terraform](https://www.terraform.io/) installed.
Also you need to install the Google Cloud CLI to authenticate against the Google Cloud. In the Google Cloud Provider Terraform Documentation you can find a guide
on how to authenticate against the Google Cloud: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started.

You then need to get an API token from Openweathermap. This token will be put into a Secret into the Google Cloud [Secret Manager](https://cloud.google.com/secret-manager) via terraform.

As I am using Github Actions to automatically deploy the project to my Google Cloud I neeed a shared terraform state. For that I am used Google Cloud Storage.
You can find a detailed explanation on how to configure that here https://cloud.google.com/docs/terraform/resource-management/store-state.
Otherwise you can also delete the `backend.tf` file in the `terraform` directory.

You also need to configure locations to fetch. The fetch function will look for a `locations.json` file inside the function directory.
It should look like this:
```json
[
  {
    "name": "Berlin",
    "latitude": "52.52",
    "longitude": "13.41",
    "units": "metric"
  }
]
```
The names of the locations are then used when getting the rain sum.


To deploy the project you need to go into the terraform directory and have google cloud au
```bash
# ./terraform

# Initialize the terraform providers
terraform init

# Apply the terraform configuration. Terraform will show everything it will to in the terminal. You then need to apply the configuration.
terraform apply
```

As the project uses Cloud Native Tools like Cloud Functions, Bigquery, Cloud Scheduler, API Gateway, Cloud Storage and Secret Manager it will be really cheap to use.
But keep in mind that it will not be free and if you just want to try the project out, you should afterwards destroy the whole infrastructure.
That can easily be done using the following command:
```bash
# ./terraform

terraform destroy
```

The function code can be found in the `function` directory beside the terraform directory.

## API
The API is specified using openapi specification. You can find the document in the `terraform` directory called `openapi-functions.yml.tpl`.
You will see that it is not a valid openapi document, as it is used as a template for the terraform scripts to configure the Google API Gateway.
To simply get your sum the URL looks like this:
```
GET https://{API_GATEWAY_URL}/rain?range=1d&location={LOCATION_NAME}&key{YOUR_API_KEY}
```
You can specify a range of days with `1d`. Currently only days are supported.

## Contribution
I am open for contributions. Just open a Issue or PR and we can discuss what can be improved or fixed :)
