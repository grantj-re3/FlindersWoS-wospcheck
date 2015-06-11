FlindersWoS-wospcheck
=====================


## Description

An overview of Web of Science Profiles is given at http://about.incites.thomsonreuters.com/profiles/

This is a tool to assist with validating Thomson Reuters Web of Science
(WoS) Profile initial spreadsheets.  It performs basic validation (mostly
relating to IDs) of Web of Science Profile Organization, Person and
Person_Organization spreadsheet. E.g. by verifying organization IDs are
decendants of the root organization ID.

- Convert each of the 3 worksheets into a CSV file using Microsoft Excel "Save as CSV"
- Copy each CSV file into the wospcheck/etc folder
- Either update bin/wosp_check.rb to reference your 3 CSV files or add symlinks from
  your 3 CSV file to:
  * org.csv
  * person.csv
  * person_org.csv
- run bin/wosp_check.rb which will show various validation warnings and errors

