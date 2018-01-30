({
    doInit: function(cmp, event, helper){
        var labels = cmp.get("v.labels");
        var templateList = [{label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit,
            summaryObject: 'Account', detailObject: 'Opportunity'}
            , {label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.softCredit
                , summaryObject: 'Account', detailObject: 'npe01__OppPayment__c'}
            , {label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                , summaryObject: 'Account', detailObject: 'Partial_Soft_Credit__c'}
            , {label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.softCredit
                , summaryObject: 'Contact', detailObject: 'Opportunity'}
            , {label: labels.paymentLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit
                , summaryObject: 'Contact', detailObject: 'Partial_Soft_Credit__c'}
            , {label: labels.paymentLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit
                , summaryObject: 'Contact', detailObject: 'npe01__OppPayment__c'}
            , {label: labels.allocationLabel + ' -> ' + labels.gauLabel
                , summaryObject: 'General_Accounting_Unit__c', detailObject: 'Allocation__c'}
        ];
        var columns = [{label: labels.rollupType, fieldName: 'label', type: 'text'},
            {label: labels.summaryObject, fieldName: 'summaryObject', type: 'text'},
            {label: labels.detailObject, fieldName: 'detailObject', type: 'text'}
        ];

        cmp.set("v.templates", templateList);
        cmp.set("v.columns", columns);
    },
    setTemplate: function(cmp, event, helper){
        var index = cmp.find("templateSelect").get("v.value");
        var templateItem;

        if(index != 'null'){
            templateItem = cmp.get("v.templates")[index];
            cmp.set("v.selectedTemplate", templateItem);
            console.log("template set");
            console.log("v.selectedTemplate");
        } else {
            console.log("template not null");
        }
    }
})