### 0.5.2 (2020-11-25)

**Hotfix**

* Fix create/update questions related to missing checks on sorted params

### 0.5.1 (2020-09-29)

**Bug fixes**

* Fix MEA title and logo not working in PDF generation

### 0.5.0 (2020-09-18)

**Ammendments**

* Update questionnaire PDF download with MEA logo and name and other minor fixes
* Add password reset link to some automated emails related to delegations

**Bug fixes**

* Fix matrix answers options and queries ordering (when creating and submitting questionnaire).


### 0.4.6 (2020-09-09)

**Bug fixes**

* Make users editable even without questionnaire associated (spurious db data)
* Add download PDF text next to the relative icon
* Fix redirect of admin failed submissions on behalf of respondent

### 0.4.5 (2020-06-09)

**Bug fixes**

* Fix documents upload modal not opening up in looping questions

### 0.4.4 (2020-05-12)

**Bug fixes**

* Fix save answers js script failing because of carriage returns in section title

### 0.4.3 (2020-03-23)

**Bug fixes**

* Remove html tags from sections titles so that are not showing on the interface

### 0.4.2 (2019-07-16)

**Bug fixes**

* Fix bug related to matrix answers API view which was fetching some answers multiple times

### 0.4.1 (2019-06-13)

**Updates**

* Add API access flag to users
  - This is to better control API access
  - Default to true

### 0.4.0 (2019-06-12)

**New features**

* Add matrix answers in API related views
  - This allows the ORS-API to fetch matrix answers as well

### 0.3.6 (2019-05-07)

**Updates**

* Increase attachments size limit to 10 MB
* More precise error message when related to file uploaded too large

**Bug fixes**

* Fix Paperclip bug on translating file size error message

### 0.3.5 (2019-04-26)

**Bug fixes**

* Disable marked as answered questions only after save
  - Allows answers to be saved before disabling them
* Fix 'Other' option not enabling/disabling correctly
* Fix multiple answers bug fetching existing answer correctly
* Fix add documents and links feature
  - Allows to immediately see if a document/link has been attached successfully regardless of looping identifier being "0" or empty

### 0.3.4 (2019-04-17)

**Updates**

* Update deploy script to compile assets locally

### 0.3.3 (2019-04-17)

**Bug fixes**

* Fix answers not saving in some cases
  - System failed to find previously destroyed answers
* In submission view, fetch original document if copied one is not found

### 0.3.2 (2019-02-21)

* Disable duplicate questionnaire functionality for questionnaires which are already a result of a duplication.

### 0.3.0 (2018-12-12)

* Bugfixing
  - Fix bug preventing to delete question from admin interface
  - Fix wrong filtering fields path
  - Add loop item name to PDF
  - In the exported pdf, retrieve original document if copied one is not found

* Add Google reCAPTCHA in sign up form to prevent spam emails

### 0.2.1 (2018-03-19)
* Bugfixing
  - Fix for a major bug for radio button answers with details text; multiple answers were submitted.
  - Fix for nested looping sources answers not exported correctly to CSV.

### 0.2.0 (2018-02-28)

* Add pivot table download for questionnaires
* Fix bug related to documents attached to answers
* Fix and improve questionnaires CSV export
* Update api views with more details for respondents

### 0.1.1 (2018-01-15)

* New roles: Super Delegate, Respondent Admin
  - A Super Delegate acts as a delegate but can also override respondent's text answers
  - Super Delegate functionality can be switched off at questionnaire's level
  - A Respondent Admin can overwrite every respondent's answer

* New way of managing Delegates and delegations
  - A Delegate can be assigned and created by Admins
  - A Delegate cannot be created if not first assigned to at least one respondent
  - A Delegate can belong to many respondents
  - Role management table in new user page

* New Admin capabilities
  - An Admin can answer underway questionnaires on behalf of a respondent
  - An Admin can submit a questionnaire on behalf of a respondent
