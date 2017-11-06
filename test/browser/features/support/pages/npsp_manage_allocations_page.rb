class NPSPManageAllocationsPage
  include PageObject

  button(:add_row_button, name: /addRowBTN/)
  button(:delete_row_button, name: /delRowBTN/)
  div(:error_message, class: 'message errorM3')
  button(:save_and_close_button, value: 'Save')
  text_field(:first_gau_field, name: /theForm/, index: 0)
  text_field(:first_row_amount, class: /alloAmount amount0/)
  text_field(:first_row_percent, class: /alloPercent percent/)
  text_field(:second_gau_field, name: /theForm/, index: 3)
  text_field(:second_row_amount, class: /alloAmount amount1/)
  text_field(:second_row_percent, class: /alloPercent percent1/)
  text_field(:error_box, name: /theForm:messages/)
  span(:remainder_amount, id: 'totalAmount')
end
