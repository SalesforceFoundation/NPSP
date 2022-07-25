 export const ShowToastEventName = 'lightning__showtoast';

 export class ShowToastEvent extends CustomEvent {
     constructor(toast) {
         super(ShowToastEventName, {
             composed: true,
             cancelable: true,
             bubbles: true,
             detail: toast
         });
     }
 }