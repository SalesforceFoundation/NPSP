({
    doInit: function(cmp, event, helper){
        var labels = cmp.get("v.labels");
        var templateList = [{label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit, name: 'Opportunity to Account Hard Credit'}
            , {label: labels.opportunityLabel + ' -> ' + labels.accountLabel + ' ' + labels.softCredit , name: 'Opportunity to Account Soft Credit'}
            , {label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit, name: 'Opportunity to Contact Hard Credit'}
            , {label: labels.opportunityLabel + ' -> ' + labels.contactLabel + ' ' + labels.softCredit, name: 'Opportunity to Contact Soft Credit'}
            , {label: labels.paymentLabel + ' -> ' + labels.accountLabel + ' ' + labels.hardCredit, name: 'Payment to Account Hard Credit'}
            , {label: labels.paymentLabel + ' -> ' + labels.contactLabel + ' ' + labels.hardCredit, name: 'Payment to Contact Hard Credit'}
            , {label: labels.allocationLabel + ' -> ' + labels.gauLabel, name: 'Allocation to GAU'}
        ];
        cmp.set("v.templates", templateList);
    },
})