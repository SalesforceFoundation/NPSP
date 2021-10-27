import { createElement } from 'lwc';
import Rd2ChangeEntryItem from 'c/rd2ChangeEntryItem';

const selectOldValue = (component) => {
   return component.shadowRoot.querySelector('[data-id="oldValue"] c-rd2-change-entry-value');
};

const selectNewValue = (component) => {
   return component.shadowRoot.querySelector('[data-id="newValue"] c-rd2-change-entry-value');
}

describe('c-rd2-change-entry-item', () => {

   afterEach(() => {
      clearDOM();
   });

   it('renders a value change', () => {
      const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeEntryItem });

      component.newValue = 'New Value';
      component.oldValue = 'Old Value';
      component.displayType = 'TEXT';
      component.label = 'A Label';

      document.body.appendChild(component);

      const oldValueNode = selectOldValue(component);
      const newValueNode = selectNewValue(component);

      expect(oldValueNode.value).toBe('Old Value');
      expect(newValueNode.value).toBe('New Value');

   });

   it('renders a given label', () => {
      const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeEntryItem });

      component.newValue = 'New Value';
      component.oldValue = 'Old Value';
      component.displayType = 'TEXT';
      component.label = 'A Label';
      document.body.appendChild(component);

      const labelNode = component.shadowRoot.querySelector('lightning-layout-item[data-id="label"]');
      expect(labelNode.textContent).toBe('A Label');
   });

   it('when value unchanged renders old value only', () => {
      const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeEntryItem });

      component.oldValue = 'Old Value';
      component.displayType = 'TEXT';
      component.label = 'A Label';

      document.body.appendChild(component);

      const oldValueNode = selectOldValue(component);
      const newValueNode = selectNewValue(component);

      expect(newValueNode).toBeNull();
      expect(oldValueNode.value).toBe('Old Value');
   });

   it('handles currency changes', () => {
      const component = createElement('c-rd2-change-entry-item', { is: Rd2ChangeEntryItem });

      component.oldValue = 5;
      component.newValue = 10;
      component.displayType = 'MONEY';
      component.label = 'Amount';

      document.body.appendChild(component);

      const oldValueNode = selectOldValue(component);
      const newValueNode = selectNewValue(component);

      expect(newValueNode).toBeTruthy();
      expect(oldValueNode.value).toBe(5);
      expect(newValueNode.value).toBe(10);

   });
});




