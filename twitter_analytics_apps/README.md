# Twitter Αnalytics shiny apps

Twitter Analytics, are shiny apps that utilize Twitter API v2 endpoints, to offer analytics to users, using global, real-time and historical data that are provided by Twitter, for academic research.

[More info about Twitter Academic Research API] ( https://developer.twitter.com/en/products/twitter-api/academic-research )

The following steps are required in order to be able to deploy the Twitter Analytics app:

1. Create a config.yaml file containing the TWITTER_BEARER token and cacheFolder (see example file)
2. Please note that for this project,access to the historical data Twitter APIv2 endpoint is needed. You will have to obtain a licence for the Twitter Academic Research Product Track on the Twitter Developer platform <https://developer.twitter.com/en/products/twitter-api/academic-research>.
3. Please refer to this link: https://cran.r-project.org/web/packages/academictwitteR/vignettes/academictwitteR-auth.html for detailed instructions on how to obtain your own bearer token.
