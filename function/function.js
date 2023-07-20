const functions = require('@google-cloud/functions-framework');
const { BigQuery } = require('@google-cloud/bigquery');
const { fetchData } = require('./lib/openweathermap');

const DATASET_ID = process.env.BIGQUERY_DATASET_ID;
const TABLE_ID = process.env.BIGQUERY_TABLE_ID;

const bigquery = new BigQuery();

functions.http('get-rain', async (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
        // Send response to OPTIONS requests
        res.set('Access-Control-Allow-Methods', 'GET');
        res.set('Access-Control-Allow-Headers', 'Content-Type');
        res.set('Access-Control-Max-Age', '3600');
        res.status(204).send('');
        return;
    }

    const location = req.query.location;
    const range = (req.query.range || '3d').replace('d', '');

    if (location === undefined || location === '') {
        res.status(400).send('Missing location parameter.');
        return;
    }

    if (range === undefined || range === '') {
        res.status(400).send('Missing range parameter.');
        return;
    }

    if (isNaN(range)) {
        res.status(400).send('Range parameter must look like \'3d\' or \'1d\'.');
        return;
    }

    const query = `
        SELECT
            location_name,
            SUM(rain) as rain_sum
        FROM \`openweathermap-history.openweathermap.weather_data_cleaned_by_last_added_rain_value\`
        WHERE
        TIMESTAMP_TRUNC(
            TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL ${range} DAY),
          DAY, "UTC") < TIMESTAMP_TRUNC(timestamp, DAY, "UTC")
            AND location_name = "${location}"
        GROUP BY location_name
    `;

    const options = {
        query,
    };

    const [job] = await bigquery.createQueryJob(options);
    console.log(`Query Job ${job.id} started.`);

    const [rows] = await job.getQueryResults();
    console.log(`Query Job ${job.id} completed.`);

    if (rows.length === 0) {
        res.status(404).send('No data found.');
        return;
    }

    console.debug({
        type: 'sum',
        value: Math.round(rows[0].rain_sum * 100) / 100,
        unit: 'mm'
    });

    res.json({
        type: 'sum',
        value: Math.round(rows[0].rain_sum * 100) / 100,
        unit: 'mm'
    })
});


functions.http('collect-data', async (req, res) => {
    const data = await fetchData();
    const timestamp_added = new Date().toISOString()

    for (location_data of data) {
        const rows = location_data.hourly.map((hourly) => {
            const dt = new Date(hourly.dt * 1000);

            return {
                timestamp: dt.toISOString(),
                position: bigquery.geography("POINT(" + location_data.longitude + " " + location_data.latitude + ")"),
                location_name: location_data.name,
                rain: hourly.rain_1h,
                timestamp_added
            }
        });

        await bigquery
            .dataset(DATASET_ID)
            .table(TABLE_ID)
            .insert(rows);
    }

    res.send("Done saving data to bigquery.");
})
