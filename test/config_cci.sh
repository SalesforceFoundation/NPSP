#!/bin/bash

# Configures the cci CLI with credentials from env vars on Heroku CI
cci org config_connected_app --client_id "$CUMULUSCI_CONNECTED_APP_ID" --client_secret "$CUMULUSCI_CONNECTED_APP_SECRET"
cci service connect github --username "$GITHUB_USERNAME" --password "$GITHUB_PASSWORD" --email "$GITHUB_EMAIL"
cci service connect saucelabs --api_key "$SAUCELABS_API_KEY" --username "$SAUCELABS_USERNAME"
