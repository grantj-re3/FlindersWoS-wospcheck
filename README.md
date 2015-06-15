FlindersWoS-wospcheck
=====================


## Description

An overview of Web of Science Profiles is given at http://about.incites.thomsonreuters.com/profiles/

This is a tool to assist with validating Thomson Reuters Web of Science
(WoS) Profile initial spreadsheets.  It performs basic validation (mostly
relating to IDs) of Web of Science Profile worksheets (i.e. organizations, persons and
persons_organizations). E.g. by verifying organization IDs are
decendants of the root organization ID and persons have at least
one role in the organization.

- Convert each of the 3 worksheets into a CSV file using Microsoft Excel "Save as CSV"
- Copy each CSV file into the etc folder
- Remove the header line from each CSV file
- Either update bin/wosp_check.rb to reference your 3 CSV files or add symlinks from
  your 3 CSV files to:
  * org.csv
  * person.csv
  * person_org.csv
- run bin/wosp_check.rb which will show various validation warnings and errors

## Environment
- ruby 1.8.7 (2013-06-27 patchlevel 374) [x86_64-linux]
- Red Hat Enterprise Linux Server release 6.6 (Santiago)
- 2.6.32-504.16.2.el6.x86_64 #1 SMP Tue Mar 10 17:01:00 EDT 2015 x86_64 x86_64 x86_64 GNU/Linux

