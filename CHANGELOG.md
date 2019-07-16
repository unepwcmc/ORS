### 0.4.2 (2019-07-16)

**Buf fixes**

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
