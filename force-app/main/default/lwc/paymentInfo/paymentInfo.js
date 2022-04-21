import { LightningElement, track, wire } from 'lwc';
import getPaymentInfo from "@salesforce/apex/PaymentInfo.getPaymentInfo";
import getElevateSDKURL from "@salesforce/apex/PaymentInfo.getElevateSDKURL";
import getClientId from "@salesforce/apex/PaymentInfo.getClientId";
import getMerchantId from "@salesforce/apex/PaymentInfo.getMerchantId";
import getGatewayId from "@salesforce/apex/PaymentInfo.getGatewayId";
import getJwtToken from "@salesforce/apex/PaymentInfo.getJwtToken";

const columns = [
    { label: "Id", fieldName: "Id" },
    { label: "Service Key", fieldName: "Service_Key__c" },
    { label: "Key", fieldName: "Key__c" },
    { label: "Value", fieldName: "Value__c" },
];

export default class PaymentInfo extends LightningElement {

    @track data = [];
    @track columns = columns;
    @track tableLoadingState = "true";
    @track elevateSDKURL = "";
    @track clientId = "";
    @track merchantId = "";
    @track gatewayId = "";
    @track jwtToken = "";


    connectedCallback() {
        getPaymentInfo()
            .then((response) => {
                this.data = response;
                this.tableLoadingState = false;
            })
        getElevateSDKURL()
            .then((response) => {
                this.elevateSDKURL = response
            })
        getClientId()
            .then((response) => {
                this.clientId = response
            })
        getMerchantId()
            .then((response) => {
                this.merchantId = response
            })
        getGatewayId()
            .then((response) => {
                this.gatewayId = response
            })
        getJwtToken()
            .then((response) => {
                this.jwtToken = response
            })
    }
    
}