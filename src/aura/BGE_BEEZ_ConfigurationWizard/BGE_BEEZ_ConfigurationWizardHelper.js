({
    /******************************** Init Functions *****************************/
    init: function(component) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.getRecordDetails');
        action.setParams({
            'recordId': recordId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            var model = JSON.parse(response.getReturnValue());
            if (state === 'SUCCESS') {
                this.loadModel(component, model);
            } else if (state === 'ERROR') {
                console.log(response.getError());
                //todo: wire up error handling
                //this.handleApexErrors(component, response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    loadModel: function(component, response) {

        let batchInfo = {};

        //generic batch info
        batchInfo.name = response.name;
        batchInfo.id = response.id;
        batchInfo.description = response.description;
        batchInfo.expectedCount = (response.expectedCount === null || response.expectedCount === '') ? 0 : response.expectedCount;
        batchInfo.expectedTotal = (response.expectedTotal === null || response.expectedTotal === '') ? 0 : response.expectedTotal;
        batchInfo.recordCount = response.recordCount;

        // batch processing settings
        batchInfo.requireTotalMatch = response.requireTotalMatch;
        batchInfo.batchProcessSize = response.batchProcessSize;
        batchInfo.runOpportunityRollupsWhileProcessing = response.runOpportunityRollupsWhileProcessing;
        batchInfo.donationMatchingBehavior = response.donationMatchingBehavior;
        batchInfo.donationMatchingClass = response.donationMatchingClass;
        batchInfo.donationMatchingOptions = response.donationMatchingOptions;
        batchInfo.donationMatchingRule = response.donationMatchingRule;
        batchInfo.donationDateRange = response.donationDateRange;
        //todo: @Patrick will fix this - PR: #3973
        //batchInfo.noMatchOnDate = response.donationMatchingRule.indexOf("donation_date__c") < 0;
        batchInfo.postProcessClass = response.postProcessClass;

        component.set('v.batchInfo', batchInfo);

        //batch metadata
        let batchMetadata = {};
        batchMetadata.labels = response.labels;
        //todo: Randi will remove readOnly + mode
        //isReadOnly (View) is passed from record home with lightning app builder
        if (component.get('v.isReadOnly')) {
            //this.setMode(component,'view');
            batchMetadata.mode = 'view';
        } else {
            if (component.get('v.recordId') !== null) {
                //this.setMode(component, 'edit');
                batchMetadata.mode = 'edit';
            } else {
                //this.setMode(component, 'create');
                batchMetadata.mode = 'create';
            }
        }
        batchMetadata.progressIndicatorStep = '0';
        batchMetadata.headers = [
            response.labels.recordInfoLabel,
            $A.get('$Label.c.bgeBatchSelectFields'),
            $A.get('$Label.c.bgeBatchSetFieldOptions'),
            $A.get('$Label.c.bgeBatchSetBatchOptions')
        ];
        this.setPageHeader(component, response);
        component.set('v.batchMetadata', batchMetadata);
        debugger;

        //available fields


        //batchFieldOptions


        /*
        component.set('v.availableFields', batchFieldsView);
        component.set('v.batchFieldOptions', batchFieldOptionsView);
        * */
    },

    /*setMode: function(component, mode) {
        let batchMetadata = component.get('v.batchMetadata');
        batchMetadata.mode = mode;
        batchMetadata.progressIndicatorStep = '0';
        component.set('v.batchMetadata', batchMetadata);
    },*/

    setPageHeader: function(component, response) {
        /*let batchMetadata = component.get('v.batchMetadata');
        var progressIndicatorStep = parseInt(this.progressIndicatorStep);
        this.pageHeader = headers[progressIndicatorStep];
        component.set('v.batchMetadata', batchMetadata);*/
        //todo: send alert to footer
    },

    sendMessage: function(component, channel, message) {
        var sendMessage = $A.get('e.ltng:sendMessage');
        sendMessage.setParams({
            'channel': channel,
            'message': message
        });
        sendMessage.fire();
    }
    
})