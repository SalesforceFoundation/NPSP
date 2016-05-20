({
    standardIcons: {
        'account': 'account',
        'approval': 'approval',
        'campaign': 'campaign',
        'campaignmember': 'campaign_members',
        'case': 'case',
        'casecomment': 'case_comment',
        'contact': 'contact',
        'dashboard': 'dashboard',
        'document': 'document',
        'emailmessage': 'email',
        'event': 'event',
        'folder': 'folder',
        'goal': 'goals',
        'group': 'groups',
        'lead': 'lead',
        'metric': 'metrics',
        'note': 'note',
        'opportunity': 'opportunity',
        'order': 'orders',
        'pricebook2': 'pricebook',
        'processdefinition': 'process',
        'processinstance': 'process',
        'product2': 'product',
        'question': 'question_feed',
        'quote': 'quotes',
        'recentlyviewed': 'recent',
        'report': 'report',
        'solution': 'solution',
        'task': 'task',
        'user': 'user',
        'workorder': 'work_order',
        'workorderlineitem': 'work_order_item'
    },

	setStandardIconAndSprite: function(component, sobject) {
        var sobjectKey = sobject.toLowerCase();
        if (this.standardIcons.hasOwnProperty(sobjectKey)) {
            component.set('v.iconSprite', 'standard');
            component.set('v.iconName', this.standardIcons[sobjectKey]);
        }
	},
})