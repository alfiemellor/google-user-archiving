# google-user-archiving
A script to perform various tasks that are required when an employee leaves a Google Workplace / G Suite environment.

This script requires https://github.com/taers232c/GAMADV-XTD3.

You may need to update a few things to fit it to your company but it should be fairly portable. The script performs the following functions:
- Verifies inputted user email
- Creates a log file of all executed actions
- Finds the users manager
- Moves them to a different OU for past employees
- Resets their password
- Asks if you wish to transfer their Google Drive files to their manager
- Performs some deprovisoning tasks such as deleting application specific passwords, 2SV backup verification codes, access tokens, disabling POP and IMAP access, forces the user to sign out and lastly disables 2-Step verifications.
- Wipes any user data from mobile devices in which the user is logged into
- Removes them from all groups they are a part of
- Hides them from the directory
- Lastly it archives the user and updates the licence attached appriopriately
