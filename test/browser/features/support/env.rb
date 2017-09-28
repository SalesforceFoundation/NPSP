require 'rspec'
require 'page-object'
require 'watir'
require 'restforce'
require 'SFDO/API'
# need to require_relative below
require_relative 'modules/sfdo_api_npsp'
include Sfdo_api_npsp

World(PageObject::PageFactory)

def test_name(scenario)
  if scenario.respond_to? :feature
    "#{scenario.feature.name}: #{scenario.name}"
  elsif scenario.respond_to? :scenario_outline
    "#{scenario.scenario_outline.feature.name}: #{scenario.scenario_outline.name}: #{scenario.name}"
  end
end

Before do |scenario|
  if ENV['RUN_LOCAL']
    if ENV['GOOGLE_CHROME_BIN']
      # Handle alternate Google Chrome binary location on Heroku CI
      Selenium::WebDriver::Chrome.driver_path = ENV['GOOGLE_CHROME_BIN']
    end
    if ENV['SELENIUM_BROWSER']
      @browser = Watir::Browser.new :"#{ENV['SELENIUM_BROWSER']}", detach: true
    else
      @browser = Watir::Browser.new :firefox, marionette: true
    end
  end

  sauce_test_name = test_name(scenario)

  if ENV['RUN_ON_SAUCE']
    caps = Selenium::WebDriver::Remote::Capabilities.send(ENV['SELENIUM_BROWSER'])

      case ENV['SELENIUM_BROWSER']
        when 'internet_explorer'
          caps.platform = 'Windows 10'
          caps.version = '11.103'
        when 'chrome'
          caps.platform = 'Windows 10'
          caps.version = '58.0'
        when 'firefox'
          caps.platform = 'Windows 10'
          caps.version = '53.0'
        else
          puts 'Environment variable SELENIUM_BROWSER is not valid'
      end

    caps[:name] = sauce_test_name

    @browser = Watir::Browser.new(
        :remote,
        :url => "http://#{ENV['SAUCE_NAME']}:#{ENV['SAUCE_KEY']}@ondemand.saucelabs.com:80/wd/hub",
        :desired_capabilities => caps)

    @session_id = @browser.driver.capabilities["webdriver.remote.sessionid"]
    STDOUT.write "SauceOnDemandSessionID=" + @session_id
  end
  @random_string = Random.new.rand(100000000000000000000).to_s
  login_with_oauth
end

After do |scenario|
  if ENV['RUN_ON_SAUCE']
    %x{curl -X PUT -s -d '{"passed": #{scenario.passed?}}' -u #{ENV['SAUCE_NAME']}:#{ENV['SAUCE_KEY']} @saucelabs.com/rest/v1/#{ENV['SAUCE_NAME']}/jobs/#{@session_id}}
  end

  @browser.close unless ENV['KEEP_BROWSER_OPEN']
end
