const locations = require('../locations.json');

// function which returns the unix timestamp of today at 00:00:00
function getTodayUnix() {
    const today = new Date();
    return Math.floor(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()) / 1000);
}

function getDaysAgoUnix(days, dt_unix) {
    return dt_unix - (days * 86400);
}

async function requestData(days_ago, latitude, longitude, language, units) {
    const params = new URLSearchParams()

    params.append('dt', getDaysAgoUnix(days_ago, getTodayUnix()));
    params.append('lat', latitude)
    params.append('lon', longitude)
    params.append('exclude', 'current,minutely,daily,alerts')
    params.append('appid', process.env.OPENWEATHER_API_KEY)
    params.append('lang', language ?? 'en')
    params.append('units', units ?? 'standard')

    // fetch openweather api onecall request
    const response = await fetch(`http://api.openweathermap.org/data/2.5/onecall/timemachine?${params.toString()}`)
    const data = await response.json()

    return data
}


module.exports = {
    fetchData: async function () {
        return await Promise.all(locations.map(async ({ name, longitude, latitude, language, units }) => {
            const today = await requestData(0, latitude, longitude, language, units)

            // merge today, yesterday, twoDaysAgo, and three days ago hourly data
            const hourly = today.hourly

            return {
                name,
                longitude,
                latitude,
                language,
                units,
                timezone: today.timezone,
                timezone_offset: today.timezone_offset,
                hourly: hourly.map(val => {
                    return {
                        dt: val.dt,
                        rain_1h: val.rain ? Object.values(val.rain)[0] : 0,
                    }
                })
            }
        }))
    }
}
