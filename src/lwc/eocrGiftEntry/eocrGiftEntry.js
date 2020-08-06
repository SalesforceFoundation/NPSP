import { LightningElement, api, wire, track } from 'lwc';

export default class EocrGiftEntry extends LightningElement {

    @api readyToEnter = false;
    checkBase64;
    deviceBase64;
    otherBase64;

    checkDocumentId;
    deviceDocumentId;
    otherDocumentId;

    enterGifts() {
        this.readyToEnter = true;
        this.checkBase64 = '';
        this.deviceBase64 = '';
        this.otherBase64 = '';
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
        const files = event.detail.files;
        //alert(JSON.stringify(files));
        let file = files[0];
        alert(JSON.stringify(file));
        this.checkDocumentId = file.documentId;
    }

    // handler for lightning-upload
    // handleUploadFinished(event) {
    //     const files = event.detail.files;
    //     alert(JSON.stringify(files));
    // }

    clearFileUpload() {
        this.value = null;
    }

    uploadCheck() {
        alert('in uploadCheck');
        const componentThis = this;
        const file = this.template.querySelector('[data-id="check-upload"]').files[0];

        const reader = new FileReader();
        reader.addEventListener("load", function () {
            alert('in event listener');
            // convert image file to base64 string
            let r = reader.result;
            componentThis.checkBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
            //console.log(componentThis.checkBase64);
            alert(componentThis.checkBase64.substring(1, 10));

          }, false);

          if (file) {
            reader.readAsArrayBuffer(file);
          }
    }

    uploadDevice() {
        const componentThis = this;
        const file = this.template.querySelector('[data-id="device-upload"]').files[0];

        const reader = new FileReader();
        reader.addEventListener("load", function () {
            // convert image file to base64 string
            let r = reader.result;
            componentThis.deviceBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
            //console.log(componentThis.checkBase64);

          }, false);

          if (file) {
            reader.readAsArrayBuffer(file);
          }
    }

    uploadOther() {
        const componentThis = this;
        const file = this.template.querySelector('[data-id="other-upload"]').files[0];

        const reader = new FileReader();
        reader.addEventListener("load", function () {
            // convert image file to base64 string
            let r = reader.result;
            componentThis.otherBase64 = btoa(String.fromCharCode(...new Uint8Array(r)));
            //console.log(componentThis.checkBase64);

          }, false);

          if (file) {
            reader.readAsArrayBuffer(file);
          }
    }

    submitFiles() {
        alert('submitting files');
        alert(this.checkDocumentId);
        //console.log('in submit = ' + this.checkBase64);
        // if (0 < this.checkBase64.length) {
        //     alert('check');
        // }

        // if (0 < this.deviceBase64.length) {
        //     alert('device');
        // }

        // if (0 < this.otherBase64.length) {
        //     alert('other');
        // }
        // alert(this.checkBase64.substring(1,5));
        // alert(this.deviceBase64.substring(1, 5));
        // alert(this.otherBase64.substring(1, 5));
       
    }

}