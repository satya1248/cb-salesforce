import { LightningElement, api } from 'lwc';

export default class CbOnboardingFlowHost extends LightningElement {
    @api flowApiName;

    openFlowFullPage() {
        if (!this.flowApiName) {
            return;
        }
        // Direct Lightning flow URL works in all orgs (standard__flow page ref does not).
        window.location.assign(`/lightning/flow/${this.flowApiName}`);
    }
}
