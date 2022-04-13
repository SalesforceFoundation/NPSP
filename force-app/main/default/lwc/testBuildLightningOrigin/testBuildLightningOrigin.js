import { LightningElement } from 'lwc';

export default class TestBuildLightningOrigin extends LightningElement {

    pageURL;

    connectedCallback(){
        const href = window.location.href;
        const hostname = window.location.hostname;
        //const arr = hostname.split(".");
        //let domain = arr[0].replace('--npsp', '');
        //domain = domain.replace('--c', '');
        //this.pageURL= `https://${domain}.lightning.force.com`;
        console.log('href: ', href);
        console.log('hostname: ', hostname);
    }


}