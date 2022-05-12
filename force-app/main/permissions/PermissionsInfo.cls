public with sharing class PermissionsInfo {
    public Boolean hasRequiredRead;
    public Boolean hasRequiredEdit;
    public Boolean hasRequiredCreate;
    public Boolean hasRequiredDelete;

    public PermissionsInfo() {
        this.hasRequiredRead = true;
        this.hasRequiredEdit = true;
        this.hasRequiredCreate = true;
        this.hasRequiredDelete = true;
    }

    public Boolean hasAllPermissions() {
        return this.hasRequiredRead
        && this.hasRequiredEdit
        && this.hasRequiredCreate
        && this.hasRequiredDelete;
    }
}