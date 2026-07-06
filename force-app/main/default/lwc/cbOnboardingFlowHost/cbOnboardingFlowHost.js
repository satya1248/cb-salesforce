import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CbOnboardingFlowHost extends NavigationMixin(LightningElement) {
    @api flowApiName;

    connectedCallback() {
        // Open the flow in the standard Lightning runtime (footer buttons render correctly).
        window.setTimeout(() => this.openFlow(), 0);
    }

    openFlow() {
        if (!this.flowApiName) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__flow',
            attributes: {
                flowApiName: this.flowApiName
            }
        });
    }
}
