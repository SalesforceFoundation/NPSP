import { LightningElement, api, wire, track } from 'lwc';

export default class EocrGiftEntry extends LightningElement {

    @api readyToEnter = false;
    // checkBase64;
    // deviceBase64;
    // otherBase64;

    checkDocumentId;
    deviceDocumentId;
    otherDocumentId;

    enterGifts() {
        this.readyToEnter = true;
        // this.checkBase64 = '';
        // this.deviceBase64 = '';
        // this.otherBase64 = '';
        this.checkDocumentId = '';
        this.deviceDocumentId = '';
        this.otherDocumentId = '';
    }

    done() {
        this.submitFiles();
        this.readyToEnter = false;
    }

    doneAndNew() {
        alert('done and new');
    }

    get acceptedFormats() {
        return ['.png', '.jpeg', '.jpg'];
    }

    handleCheckUploadFinished(event) {
        const file = event.detail.files[0];
        this.checkDocumentId = file.documentId;
    }

    handleDeviceUploadFinished(event) {
        const file = event.detail.files[0];
        this.deviceDocumentId = file.documentId;
    }

    handleOtherUploadFinished(event) {
        const file = event.detail.files[0];
        this.otherDocumentId = file.documentId;
    }

    // handler for lightning-upload
    // handleUploadFinished(event) {
    //     const files = event.detail.files;
    //     alert(JSON.stringify(files));
    // }


    // uploadCheck() {
    //     alert('in uploadCheck');
    //     const componentThis = this;
    //     const file = this.template.querySelector('[data-id="check-upload"]').files[0];

    //     const reader = new FileReader();
    //     reader.addEventListener("load", function () {
    //         alert('in event listener');
    //         // convert image file to base64 string
    //         let r = reader.result;
    //         componentThis.checkBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
    //         //console.log(componentThis.checkBase64);
    //         alert(componentThis.checkBase64.substring(1, 10));

    //       }, false);

    //       if (file) {
    //         reader.readAsArrayBuffer(file);
    //       }
    // }

    // uploadDevice() {
    //     const componentThis = this;
    //     const file = this.template.querySelector('[data-id="device-upload"]').files[0];

    //     const reader = new FileReader();
    //     reader.addEventListener("load", function () {
    //         // convert image file to base64 string
    //         let r = reader.result;
    //         componentThis.deviceBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
    //         //console.log(componentThis.checkBase64);

    //       }, false);

    //       if (file) {
    //         reader.readAsArrayBuffer(file);
    //       }
    // }

    // uploadOther() {
    //     const componentThis = this;
    //     const file = this.template.querySelector('[data-id="other-upload"]').files[0];

    //     const reader = new FileReader();
    //     reader.addEventListener("load", function () {
    //         // convert image file to base64 string
    //         let r = reader.result;
    //         componentThis.otherBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
    //         //console.log(componentThis.checkBase64);

    //       }, false);

    //       if (file) {
    //         reader.readAsArrayBuffer(file);
    //       }
    // }

    submitFiles() {
        alert('submitting files');
        alert(this.checkDocumentId);
        alert(this.deviceDocumentId);
        alert(this.otherDocumentId);
       
    }

}