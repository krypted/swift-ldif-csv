# swift-ldif-csv
Migrate LDIF files to CSV using Swift
https://github.com/krypted/swift-ldif-csv/blob/master/ldif_to_csv

Usage:
ldif_to_csv <LDIF path> [-csv <CSV path>] [-a <attributes>]

$1 - <LDIF path> - path to the source LDIF file.
-csv <CSV path> - path to the output CSV file. By default output file will be created in the LDIF's source directory.
-a <attributes> - comma separated list of attributes. By default all attributes will be exported.