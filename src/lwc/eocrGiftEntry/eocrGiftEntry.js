import { LightningElement, api, wire, track } from 'lwc';

export default class EocrGiftEntry extends LightningElement {

    @api readyToEnter = false;
    checkBase64 = '';
    deviceBase64 = '';
    otherBase64 = '';

    enterGifts() {
        this.readyToEnter = true;
    }

    done() {
        this.uploadFiles();
        this.readyToEnter = false;
    }

    doneAndNew() {
        alert('done and new');
    }

    handleUploadFinished(event) {
        const files = event.detail.files;
        alert(JSON.stringify(files));
    }

    uploadCheck() {
        const file = this.template.querySelector('[data-id="check-upload"]').files[0];
        console.log(file);

        const reader = new FileReader();
        reader.addEventListener("load", function () {
            alert('in event listener');
            // convert image file to base64 string
            let r = reader.result;
            let base64 = btoa(String.fromCharCode(...new Uint8Array(r)));
            console.log(base64);

          }, false);

          if (file) {
            //reader.readAsDataURL(file);
            reader.readAsArrayBuffer(file);
          }
    }

    uploadFiles() {
        alert('uploading files');

        // get the check
        //const file = document.querySelector('input[type=file]').files[0];
        //const file = document.querySelector('#check-upload').files[0];
        alert(file);
        //const reader = new FileReader();
        //let r = reader.result;

        //alert(r);
              
       
    }

}