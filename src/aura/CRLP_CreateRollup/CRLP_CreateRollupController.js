({
    doInit: function(cmp, event, helper){
        var labels = cmp.get("v.labels");
        var templateList = [{label: labels.noRollupType, summaryObject: labels.na, detailObject: labels.na}
            , {label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit,
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
        //intended for use with radio buttons, otherwise first selected row will be selected
        var selected = event.getParam('selectedRows');
        var selectedRow = selected[0];
        if(selectedRow === cmp.get("v.templates")[0]){
            selectedRow = null;
        }
        cmp.set("v.selectedTemplate", selectedRow);
    }
})