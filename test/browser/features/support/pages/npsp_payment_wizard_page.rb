class PaymentWizardPage
  include PageObject

  button(:calculate_payments, value: 'Calculate Payments')
  button(:create_payments_button, value: 'Create Payments')
  div(:current_opportunity_title, class: 'slds-section-title--divider', index: 0)
  div(:create_payment_schedule, class: 'slds-section-title--divider', index: 1)
  table(:header_line, class: 'slds-table')
  a(:ninth_payment_link, text: /PMT/, index: 8)
  select_list(:number_of_payments, name: /paymentCount/)
  div(:payment_page_amount, id: /_ileinner/, index: 2)
  h1(:payment_page_header, class: 'pageType')
  div(:payments_to_be_created, class: 'slds-section-title--divider', index: 2)
  h1(:title_text, class: 'slds-text-heading--medium slds-p-top-medium')
  text_field(:twelfth_amount_textfield, class: 'slds-input slds-input--small')
end
