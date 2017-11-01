class LoginPage
  include PageObject

  div(:app_switcher, id: 'tsidButton')
  a(:npsp_app_picker, text: 'Nonprofit Success Pack')

end
