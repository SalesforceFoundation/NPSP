class LoginPage
  include PageObject

  div(:app_switcher, id: 'tsidButton')
  a(:npsp_app_picker, text: 'Nonprofit Success Pack')

# LOGIN WITH ENV VARS IS NEVER TO BE USED IN A JENKINS BUILD
# BECAUSE IT LEAKS PASSWORDS IN THE SAUCELABS SELENIUM LOGS.
# PLEASE USE THE OAUTH LOGIN STEPS ABOVE INSTEAD

  page_url 'https://login.salesforce.com<%=params[:redirect_to]%>'

  text_field(:username, id: 'username')
  text_field(:password, id: 'password')
  button(:login_button, id: 'Login')

  def login_with_env_vars
    self.username_element.when_present.send_keys(ENV['SF_USERNAME'])
    self.password_element.when_present.send_keys(ENV['SF_PASSWORD'])
    login_button
  end
end
