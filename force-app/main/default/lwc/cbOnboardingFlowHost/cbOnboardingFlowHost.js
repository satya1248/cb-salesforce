import { LightningElement, api } from 'lwc';

export default class CbOnboardingFlowHost extends LightningElement {
    @api flowApiName;
    @api guideType = 'Retail';

    openFlowFullPage() {
        if (!this.flowApiName) {
            return;
        }
        window.location.assign(`/lightning/flow/${this.flowApiName}`);
    }
}
