// Assign CB Platform Admin permission set group to the default scratch org user.
PermissionSetGroup psg = [
    SELECT Id, DeveloperName
    FROM PermissionSetGroup
    WHERE DeveloperName = 'CB_Platform_Admin'
    LIMIT 1
];
User u = [SELECT Id FROM User WHERE Username = :UserInfo.getUserName() LIMIT 1];

List<PermissionSetAssignment> existing = [
    SELECT Id
    FROM PermissionSetAssignment
    WHERE AssigneeId = :u.Id AND PermissionSetGroupId = :psg.Id
];
if (existing.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetGroupId = psg.Id);
    System.debug('Assigned CB_Platform_Admin to ' + u.Id);
} else {
    System.debug('CB_Platform_Admin already assigned');
}
