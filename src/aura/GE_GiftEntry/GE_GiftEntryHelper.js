({
    handleCloseModal: function(component) {
        component.get('v.modal').then(modal => {
            modal.close();
            component.set('v.isLoading', false);
        });
    }
})