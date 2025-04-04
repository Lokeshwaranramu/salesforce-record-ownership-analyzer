import { LightningElement, track, wire } from 'lwc';
import getObjectList from '@salesforce/apex/RecordOwnershipController.getObjectList';
import getOwnershipData from '@salesforce/apex/RecordOwnershipController.getOwnershipData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RecordOwnershipAnalyzer extends LightningElement {
  @track selectedObject = 'Account'; // Default object
  @track objectOptions = [];
  @track ownershipData = [];
  @track error;

  @wire(getObjectList)
  wiredObjects({ data, error }) {
    if (data) {
      this.objectOptions = data.map(obj => ({
        label: obj,
        value: obj
      }));
      this.fetchOwnershipData();
    } else if (error) {
      this.error = 'Error fetching objects: ' + (error.body?.message || error.message);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: this.error,
          variant: 'error'
        })
      );
    }
  }

  handleObjectChange(event) {
    this.selectedObject = event.detail.value;
    this.fetchOwnershipData();
  }

  handleRefresh() {
    this.fetchOwnershipData();
  }

  async fetchOwnershipData() {
    try {
      this.error = null;
      this.ownershipData = [];
      const data = await getOwnershipData({ objectName: this.selectedObject });
      
      // Calculate max count for bar chart scaling
      const maxCount = Math.max(...data.map(entry => entry.recordCount), 1);
      
      this.ownershipData = data.map(entry => ({
        userId: entry.userId,
        userName: entry.userName,
        recordCount: entry.recordCount,
        barStyle: `width: ${(entry.recordCount / maxCount) * 100}%; background-color: #0070d2;`
      }));
    } catch (error) {
      this.error = 'Error fetching ownership data: ' + (error.body?.message || error.message);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: this.error,
          variant: 'error'
        })
      );
    }
  }
}