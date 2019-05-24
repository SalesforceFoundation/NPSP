from cumulusci.tasks.salesforce import BaseSalesforceApiTask

class ConfigureCAD(BaseSalesforceApiTask):

    def _run_task(self):
        self.sf.CurrencyType.create({
            'IsoCode': 'CAD',
            'IsCorporate': False,
            'IsActive': True,
            'DecimalPlaces': 2,
            'ConversionRate': 1.3,
        })
