# NPSP-Browser-Tests
Cross-browser UI tests for NPSP features

How to run browser tests locally (non-Windows OS)
Use this on a salesforce DE org or a Sandbox or a scratch org with NPSP installed!!

* Install Firefox if it’s not already installed. Download geckodriver from https://github.com/mozilla/geckodriver/releases

* If you want to use Chrome also, download the Chrome driver at https://sites.google.com/a/chromium.org/chromedriver/

Put geckodriver/chromedriver in your $PATH

`mv ~/Downloads/chromedriver /usr/local/bin/`

`mv ~/Downloads/geckodriver /usr/local/bin/`

`export SELENIUM_BROWSER=chrome` to use the Google Chrome browser

`unset SELENIUM_BROWSER` to use Firefox


* If you're new to ruby:
* Install RVM and Ruby 2.x (for details see https://rvm.io/)
````
\curl -sSL https://get.rvm.io | bash -s stable
rvm install ruby 2.2
````
* check your install:

````	
which ruby
````
You should see something like */Users/[your user]/.rvm/rubies/ruby-2.2.1/bin/ruby*

if you see something like /usr/bin/ruby instead of .rvm/rubies, read the RVM docs and fix your path

Once you have Ruby in place, install the bundler gem:

`gem install bundler`

* clone or download the browser test source code

`git clone https://github.com/SalesforceFoundation/NPSP-Browser-Tests.git`

`cd NPSP-Browser-Tests`

`bundle install`

Make sure you're using a local browser:

`export RUN_LOCAL=true`

If you want to use SauceLabs instead of running locally: 

`export SAUCE_NAME=[your Sauce user name]`

`export SAUCE_KEY=[your Sauce identification key]`

`export RUN_ON_SAUCE=true`

If you want the browser to stay open when a Scenario finishes: `export KEEP_BROWSER_OPEN=true` 

Do `unset KEEP_BROWSER_OPEN` to return to having the browser instance close automatically when tests finish.

To run the tests:

`bundle exec cucumber features/` to run all tests

`bundle exec cucumber features/my_test.feature` to run one test

`bundle exec cucumber features/*settings*` to run all tests containing "settings" in the name

`bundle exec cucumber features/my_test.feature:42` to run a single Scenario within a Feature at line 42


If you are using CumulusCI version 2, that is all you need in place, because CumulusCI handles your authentication
with your target org. If you want to run browser tests without CumulusCI, you need different authentication details:
 

* Follow the directions at https://cumulusci-oauth-tool.herokuapp.com/ 
to get refresh token, consumer key, and consumer secret for your target org. 
* set these environment variables: 
````
export SF_SERVERURL=https://login.salesforce.com/

export SF_REFRESH_TOKEN=[your refresh token]

export SF_CLIENT_KEY=[your consumer key]

export SF_CLIENT_SECRET=[your consumer secret]
````


This test framework depends heavily on Jeff Morgan's page_object Ruby gem. 
Please find many details documented at https://github.com/cheezy/page-object/
