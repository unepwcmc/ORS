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
