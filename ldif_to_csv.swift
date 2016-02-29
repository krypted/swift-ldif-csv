//
//  main.swift
//  ldif_to_csv
//
//

import Foundation

extension String
{
    func trim() -> String
    {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}

func usage() {
    print("Usage:")
    print("\tldif_to_csv <LDIF path> [-csv <CSV path>] [-a <attributes>]")
    print("Where:")
    print("\t<LDIF path> - path to the source LDIF file.")
    print("\t-csv <CSV path> - path to the output CSV file. By default output file will be created in the LDIF's source directory.")
    print("\t-a <attributes> - comma separated list of attributes. By default all attributes will be exported.")
}



var numberOfArguments = Process.arguments.count

if numberOfArguments >= 2 {
    // read arguments
    var ldifFilePath = Process.arguments[1]
    var csvFilePath = ""
    var attributesFilter = [String]()
    var argumentError = false
    
    for var i = 2; i < numberOfArguments; ++i {
        if i + 1 < numberOfArguments {
            switch Process.arguments[i] {
            case "-csv":
                csvFilePath = Process.arguments[++i]
            case "-a":
                attributesFilter = Process.arguments[++i].characters.split{$0 == ","}.map(String.init)
            default:
                print("Error: unknown argument '\(Process.arguments[i])'")
                argumentError = true
            }
        }
        else {
            print("Error: missing value for argument '\(Process.arguments[i])'")
            argumentError = true
        }
    }
    
    // process LDIF
    if !argumentError {
        if csvFilePath.isEmpty {
            // defaulf output CSV filename
            csvFilePath = ldifFilePath + ".csv"
        }
        
        var filemgr = NSFileManager.defaultManager()
        
        if filemgr.fileExistsAtPath(ldifFilePath) {
            do {
                var ldifLines:[String] = try String(contentsOfFile: ldifFilePath).componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                var records = [[String:String]]()
                var record = [String:String]()
                var attributes = Set<String>()
                
                // process LDIF line by line
                for var i = 0; i < ldifLines.count; ++i {
                    // save curent line index
                    let lineIndex = i
                    
                    ldifLines[lineIndex] = ldifLines[lineIndex].trim()
                    
                    // skip version
                    if i == 0 && ldifLines[lineIndex].hasPrefix("version") {
                        continue
                    }
                    
                    if !ldifLines[lineIndex].isEmpty {
                        // fold lines
                        while i + 1 < ldifLines.count && ldifLines[i+1].hasPrefix(" ") {
                            ldifLines[lineIndex] += ldifLines[++i].trim()
                        }
                    }
                    else {
                        // end of record
                        records.append(record)
                        record = [String:String]()
                    }
                    
                    // skip comment
                    if ldifLines[lineIndex].hasPrefix("#") {
                        continue
                    }
                    
                    // parse attribute
                    var attribute = ldifLines[lineIndex].characters.split(":", maxSplit: 1, allowEmptySlices: true).map(String.init)
                    if attribute.count == 2 {
                        var attributeName = attribute[0].trim()
                        if let index = attributeName.characters.indexOf(";") {
                            attributeName = attributeName.substringToIndex(index)
                        }
                        
                        attributes.insert(attributeName)
                        
                        var attributeValue = attribute[1].trim()
                        
                        if attributeValue.hasPrefix("<") {
                            // url
                            attributeValue = attributeValue.substringFromIndex(attributeValue.startIndex.successor()).trim()
                        }
                        else if attributeValue.hasPrefix(":") {
                            // base64
                            let decodedData = NSData(base64EncodedString: attributeValue.substringFromIndex(attributeValue.startIndex.successor()).trim(), options: NSDataBase64DecodingOptions.init(rawValue: 0))
                            attributeValue = String(data: decodedData!, encoding: NSUTF8StringEncoding)!
                        }
                        
                        // escape double quote
                        attributeValue = attributeValue.stringByReplacingOccurrencesOfString("\"", withString: "\"\"")
                        
                        // save attribute value or append it to the existing
                        if let val = record[attributeName] {
                            record[attributeName] = "\"" + val.substringWithRange(Range<String.Index>(start: val.startIndex.successor(), end: val.endIndex.predecessor())) + ";" + attributeValue + "\""
                        }
                        else {
                            record[attributeName] = "\"" + attributeValue + "\""
                        }
                    }
                }
                
                // save last record
                if record.count > 0 {
                    records.append(record)
                }
                
                // export all attributes if filter is empty
                if attributesFilter.count == 0 {
                    attributesFilter = Array(attributes)
                }
                
                // save CSV
                var csvLines = [String]()
                csvLines.append(attributesFilter.joinWithSeparator(","))
                
                for record in records {
                    var csvLine = ""
                    
                    for attribute in attributesFilter {
                        if let val = record[attribute] {
                            csvLine += val + ","
                        }
                        else{
                            csvLine += ","
                        }
                    }
                    
                    csvLine = csvLine.substringToIndex(csvLine.endIndex.predecessor())
                    csvLines.append(csvLine)
                }
                
                try csvLines.joinWithSeparator("\n").writeToFile(csvFilePath, atomically: true, encoding: NSUTF8StringEncoding)
            }
            catch let error as NSError {
                print("Error: \(error)")
            }
        }
        else {
            print("Error: LDIF file '\(ldifFilePath)' doesn't exist")
        }
    }
}
else {
    usage()
}


