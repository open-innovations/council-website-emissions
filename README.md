# council-website-emissions
Looking at the CO2 emissions of local council websites

This uses a port (and update) of [WholeGrain Digital's WebsiteCarbon API 2.0 php code](https://gitlab.com/wholegrain/carbon-api-2-0/-/blob/master/includes/carbonapi.php) with figures updated to [version 3](https://sustainablewebdesign.org/calculating-digital-emissions/).

The `update.pl` script needs the environment variable `CC_GPSAPI_KEY` set to your API key for [Google's Pagespeed](https://www.googleapis.com/pagespeedonline/) as that is what it uses to assess each URL.

The script reads `data/index.json` and for each `org` processes any `urls` that it contains. Each `org` looks like e.g.:

```json
"E06000001": {
	"active": true,
	"name": "Hartlepool Borough Council",
	"urls": {
		"https://www.hartlepool.gov.uk/": {
			"values": {
				"2021-03-10": { "CO2": 0.22, "ref": "https://www.websitecarbon.com/website/hartlepool-gov-uk/" },
				"2021-05-27": { "CO2": 0.21, "bytes": 349031, "green": 0, "imagebytes": 116453 },
				"2021-06-30": { "CO2": 0.21, "bytes": 350015, "green": 0, "imagebytes": 116454 },
				"2021-07-29": { "CO2": 0.21, "bytes": 356419, "green": 0, "imagebytes": 116454 },
				"2021-08-31": { "CO2": 0.21, "bytes": 356493, "green": 0, "imagebytes": 116452 },
				"2021-10-06": { "CO2": 0.22, "bytes": 361724, "green": 0, "imagebytes": 116454 },
				"2021-11-02": { "CO2": 0.21, "bytes": 353640, "green": 0, "imagebytes": 116455 },
				"2021-12-08": { "CO2": 0.22, "bytes": 361341, "green": 0, "imagebytes": 116454 },
				"2022-01-04": { "CO2": 0.21, "bytes": 353466, "green": 0, "imagebytes": 116453 },
				"2022-02-01": { "CO2": 0.22, "bytes": 361772, "green": 0, "imagebytes": 116454 }
			}
		}
	}
}
```

The `update.pl` calls `process.pl` which will add a new dated entry for each org+url. Each entry contains the estimated CO2 (g), the bytes, if it is marked as a green web server (this relies on having an extract of the Green Web Foundation's data in e.g. `data/raw/green_urls_2022-09-09.db`), and the total bytes for images.
