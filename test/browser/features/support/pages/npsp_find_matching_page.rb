class FindMatchingGiftsPage
  include PageObject

  button(:cancel_button, text: 'Cancel')
  div(:content, class: 'slds-modal__content')
  table(:error_message, class: 'messageTable')
  text_field(:fifth_text_field, index: 4)
  a(:find_more_gifts, text: 'Find More Gifts')
  checkbox(:match_checkbox, id: /cbGift/)
  table(:matching_gift_headers, class: 'slds-table slds-table--bordered')
  h2(:opp_page_header, class: 'pageDescription')
  div(:opportunity_info, class: 'slds-grid slds-page-header__detail-row')
  button(:save_match_gift, text: 'Save')
  #button(:search_button, text: 'Search')
  button(:search_button, class: 'btn slds-button slds-button--neutral slds-button--brand')
end
