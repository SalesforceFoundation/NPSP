from cumulusci.robotframework.pageobjects import DetailPage
from cumulusci.robotframework.pageobjects import pageobject
from locators_46 import npsp_lex_locators

@pageobject("Detail", "npe01__OppPayment__c")
class PaymentPage(DetailPage):
    object_name = "npe01__OppPayment__c"

    @property
    def npsp(self):
        return self.builtin.get_library_instance('NPSP')
    
    
    def verify_payment_allocations(self, **kwargs):
       """To verify allocations, header is related list
          key is value in td element, value is value in th element     
       """
       self.salesforce.load_related_list("Payment Allocations")
       for key, value in kwargs.items():
           locator = npsp_lex_locators['payments']['allocations'].format("Payment Allocations",key)
           ele = self.selenium.get_webelement(locator).text
           assert ele == value, "Expected {} allocation to be {} but found {}".format(key,value,ele)
        