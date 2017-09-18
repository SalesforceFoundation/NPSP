class NPSPGettingStartedPage
  include PageObject

  div(:page_contents, class: 'bootstrap')
  a(:salesforce_fundamentals_link, href: 'https://powerofus.force.com/articles/Resource/Salesforce-Fundamentals')
  a(:beginner_admin_trail_link, href: 'https://developer.salesforce.com/trailhead/trail/force_com_admin_beginner')
  a(:this_interactive_learning_path_link, href: 'https://developer.salesforce.com/trailhead/trail/nonprofit_fundraising')
  a(:guide_link, href: /NPSP_Import_Data/)
  a(:power_of_us_login_link, href: 'https://powerofus.force.com')
  a(:salesforce_success_learn_more_link, href: 'https://powerofus.force.com/articles/Resource/Get-Help-NPSP')
  a(:foundation_office_hours_learn_more_link, href: 'https://powerofus.force.com/HUB_Foundation_Office_Hours')
end