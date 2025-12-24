//
//  NotificationParser.swift
//  AmityUIKit4
//
//  Created by Nishan Niraula on 10/4/25.
//

class NotificationTemplateData {
    var text: String = ""// displayed text
    var range: NSRange = NSRange.init() // range of text
    var type: String = "" // user | community | text | event
    var id: String = "" // userId | communityId | eventId
    
    var description: String {
        return """
               \nId: \(id), Type: \(type), Text: \(text), Range: \(range)
               """
    }
}

class NotificationParser {
    
    // Regex to parse {{ userId:... }} OR {{ communityId: ... }}
    let regex = try? NSRegularExpression(pattern: "(\\{\\{\\s*.+?\\s*\\}\\})", options: [])
    
    func parse(text: String, template: String) -> [NotificationTemplateData] {
        guard let regex else { return [] }
        
        let userTemplateFormat = "<user-template>"
        let commTemplateFormat = "<comm-template>"
        let textTemplateFormat = "<text-template>"
        let eventTemplateFormat = "<event-template>"
        
        let compatibleTemplate = template as NSString
        let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: compatibleTemplate.length))
        
        // #1, First we extract all placeholders used in template text including parenthesis {{ ... }} using regex
        let templatePlaceholders = matches.map { match in
            let range = match.range
            return compatibleTemplate.substring(with: range)
        }
        
        // #2. We replace the placeholders with something we can use later and we also extract information related to placeholder.
        var placeholders = [NotificationTemplateData]()
        var processedTemplateText = template
        
        for item in templatePlaceholders {
            
            // Break down template placeholder contents by ":" sign, remove parenthesis & trim whitespaces
            var contents = item.components(separatedBy: ":")
            contents = contents.map { value in
                var final = value.replacingOccurrences(of: "{{", with: "")
                final = final.replacingOccurrences(of: "}}", with: "")
                final = final.trimmingCharacters(in: .whitespacesAndNewlines)
                return final
            }
                        
            // Clean templates
            let info = NotificationTemplateData()
            if item.contains("userId") {
                processedTemplateText = processedTemplateText.replacingOccurrences(of: item, with: userTemplateFormat)
                
                info.id = contents[1]
                info.type = "user"
            } else if item.contains("communityId") {
                processedTemplateText = processedTemplateText.replacingOccurrences(of: item, with: commTemplateFormat)
                
                info.id = contents[1]
                info.type = "community"
            } else if item.contains("text") {
                processedTemplateText = processedTemplateText.replacingOccurrences(of: item, with: textTemplateFormat)
                
                info.id = contents[1]
                info.type = "text"
            } else if item.contains("eventId") {
                processedTemplateText = processedTemplateText.replacingOccurrences(of: item, with: eventTemplateFormat)
                info.id = contents[1]
                info.type = "event"
            }
            
            placeholders.append(info)
        }
        
        // #3. We loop through text & templates to determine the range of texts for each placeholder
        // Text: abcd posted in cdef
        // Template: <user-template> posted in <comm-template>
        let textWords = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let templateWords = processedTemplateText.components(separatedBy: .whitespacesAndNewlines)
                
        // Note: textWordsCount & templateWordsCount might not be of equal length.
        let textWordsCount = textWords.count
        let templateWordsCount = templateWords.count
        
        var textIndex = 0
        var templateIndex = 0
        var placeholderIndex = 0
        
        while textIndex < textWordsCount && templateIndex < templateWordsCount {
            if textWords[textIndex] == templateWords[templateIndex] {
                textIndex += 1
                templateIndex += 1
            } else {
                // Words doesn't match. It means it encountered our template format
                var startIndex = textIndex
                var stopWord = ""
                                
                // When it encounter this stop word, it should stop highlighting
                if templateIndex < templateWordsCount - 1 {
                    // Word immediately after <...> format.
                    stopWord = templateWords[templateIndex + 1]
                }
                                
                var highlightWords = [String]()
                while startIndex < textWordsCount {
                    
                    if textWords[startIndex] == stopWord {
                        break
                    } else {
                        highlightWords.append(textWords[startIndex])
                    }
                    
                    startIndex += 1
                }
                                
                // Now we have words to highlight, we keep track of the range & everything
                let highlightText = highlightWords.joined(separator: " ")
                if let range = text.range(of: highlightText) {
                    let nsRange = NSRange(range, in: text)
                    
                    // Now that we have all the information, we update our placeholder info
                    if placeholderIndex < placeholders.count {
                        placeholders[placeholderIndex].range = nsRange
                        placeholders[placeholderIndex].text = highlightText
                        
                        placeholderIndex += 1
                    }
                }
                
                textIndex = startIndex
                templateIndex += 1
            }
        }
        return placeholders
    }
}
