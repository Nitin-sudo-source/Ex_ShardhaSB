public class Ex_AccountHandlerServices {

    // Insert the contact for Tenant Accounts
    public static void createPrimaryOwnerContact(List<Account> accounts){
        
        List<Contact__c> contactsToInsert = new List<Contact__c>();
        for (Account account : accounts) {
            
            Contact__c primaryOwnerContact = new Contact__c();
            primaryOwnerContact.Name = account.Name;
            primaryOwnerContact.Tenant__c = account.Id;
            primaryOwnerContact.Relation_with_Primary_Owner__c = 'Primary Owner';
            primaryOwnerContact.Aadhar_Number__c = account.Aadhar_Number__c;
            primaryOwnerContact.PAN_Number__c = account.PAN_Number__c;


            primaryOwnerContact.Mobile__c = account.PersonMobilePhone;
            primaryOwnerContact.Email__c = account.PersonEmail;

            contactsToInsert.add(primaryOwnerContact);
        }

        INSERT contactsToInsert;
    }
}