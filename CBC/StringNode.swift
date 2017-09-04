//
//  StringNode.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

class StringNode {
    var string:String?
    
    init(_ string:String?)
    {
        self.string = string
    }
    
    var wordEnding = false
    
    var stringNodes:[StringNode]?
    
    var isLeaf:Bool {
        get {
            return stringNodes == nil
        }
    }
    
    func depthBelow(_ cumulative:Int) -> Int
    {
        if isLeaf {
            return cumulative
        } else {
            var depthsBelow = [Int]()
            
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                depthsBelow.append(stringNode.depthBelow(cumulative + 1))
            }
            
            if let last = depthsBelow.sorted().last {
                //                print(depthsBelow)
                //                print(depthsBelow.sorted())
                //                print("\n")
                return last
            } else {
                return 0
            }
        }
    }
    
    func printWords(_ cumulativeString:String?)
    {
        //        guard string != nil else {
        //            return
        //        }
        
        if wordEnding {
            if cumulativeString != nil {
                if string != nil {
                    print(cumulativeString!+string!)
                } else {
                    print(cumulativeString!)
                }
            } else {
                if string != nil {
                    print(string!)
                }
            }
            
            //            print("\n")
        }
        
        guard stringNodes != nil else {
            return
        }
        
        for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
            //            print(string!+"-")
            if cumulativeString != nil {
                if string != nil {
                    stringNode.printWords(cumulativeString!+string!+"-")
                } else {
                    stringNode.printWords(cumulativeString!+"-")
                }
            } else {
                if string != nil {
                    stringNode.printWords(string!+"-")
                } else {
                    stringNode.printWords(nil)
                }
            }
        }
    }
    
    func htmlWords(_ cumulativeString:String?) -> [String]?
    {
        //        guard string != nil else {
        //            return
        //        }
        
        var html = [String]()
        
        if wordEnding {
            if cumulativeString != nil {
                if string != nil {
                    let word = cumulativeString! + string! + "</td>"
                    html.append(word)
                    //                    print(word)
                } else {
                    let word = cumulativeString! + "</td>"
                    html.append(word)
                    //                    print(word)
                }
            } else {
                if string != nil {
                    let word = "<td>" + string! + "</td>"
                    html.append(word)
                    //                    print(word)
                }
            }
            
            //            print("\n")
        }
        
        guard let stringNodes = stringNodes else {
            return html.count > 0 ? html : nil
        }
        
        for stringNode in stringNodes.sorted(by: { $0.string < $1.string }) {
            //            print(string!+"-")
            if cumulativeString != nil {
                if string != nil {
                    if let words = stringNode.htmlWords(cumulativeString!+string!+"</td><td>") {
                        html.append(contentsOf: words)
                    }
                } else {
                    if let words = stringNode.htmlWords(cumulativeString!+"</td><td>") {
                        html.append(contentsOf: words)
                    }
                }
            } else {
                if string != nil {
                    if let words = stringNode.htmlWords("<td>" + string! + "</td><td>") {
                        html.append(contentsOf: words)
                    }
                } else {
                    if let words = stringNode.htmlWords(nil) {
                        html.append(contentsOf: words)
                    }
                }
            }
        }
        
        return html.count > 0 ? html : nil
    }
    
    func addStringNode(_ newString:String?)
    {
        guard (newString != nil) else {
            return
        }
        
        guard (stringNodes != nil) else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            stringNodes = [newNode]
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            return
        }
        
        var fragment = newString
        
        var foundNode:StringNode?
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            for stringNode in stringNodes!.sorted(by: { $0.string < $1.string }) {
                if stringNode.string?.endIndex >= fragment!.endIndex, stringNode.string?.substring(to: fragment!.endIndex) == fragment {
                    foundNode = stringNode
                    break
                }
            }
            
            if foundNode != nil {
                break
            }
            
            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))
            
            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if foundNode != nil {
            foundNode?.addString(newString)
        } else {
            let newNode = StringNode(newString)
            newNode.wordEnding = true
            newNode.stringNodes = [StringNode(Constants.WORD_ENDING)]
            stringNodes?.append(newNode)
        }
    }
    
    func addString(_ newString:String?)
    {
        guard let stringEmpty = newString?.isEmpty, !stringEmpty else {
            return
        }
        
        guard (string != nil) else {
            addStringNode(newString)
            return
        }
        
        guard (string != newString) else {
            wordEnding = true
            
            var found = false
            
            if var stringNodes = stringNodes {
                for stringNode in stringNodes {
                    if stringNode.string == Constants.WORD_ENDING {
                        found = true
                        break
                    }
                }
                
                if !found {
                    stringNodes.append(StringNode(Constants.WORD_ENDING))
                }
            } else {
                stringNodes = [StringNode(Constants.WORD_ENDING)]
            }
            
            return
        }
        
        var fragment = newString
        
        var isEmpty = fragment!.isEmpty
        
        while !isEmpty {
            if string?.endIndex >= fragment!.endIndex, string?.substring(to: fragment!.endIndex) == fragment {
                break
            }
            
            fragment = fragment!.substring(to: fragment!.index(before: fragment!.endIndex))
            
            if fragment != nil {
                isEmpty = fragment!.isEmpty
            } else {
                isEmpty = true
            }
        }
        
        if !isEmpty {
            let stringRemainder = string?.substring(from: fragment!.endIndex)
            
            let newStringRemainder = newString?.substring(from: fragment!.endIndex)
            
            if let isEmpty = stringRemainder?.isEmpty, !isEmpty {
                var newNode = StringNode(stringRemainder)
                newNode.stringNodes = stringNodes
                
                newNode.wordEnding = wordEnding
                
                if !wordEnding, let index = stringNodes?.index(where: { (stringNode:StringNode) -> Bool in
                    return stringNode.string == Constants.WORD_ENDING
                }) {
                    stringNodes?.remove(at: index)
                }
                
                wordEnding = false
                
                string = fragment
                stringNodes = [newNode]
            }
            
            if let isEmpty = newStringRemainder?.isEmpty, !isEmpty {
                addStringNode(newStringRemainder)
            } else {
                wordEnding = true
            }
        } else {
            // No match!?!?!
        }
    }
    
    func addStrings(_ strings:[String]?)
    {
        guard strings != nil else {
            return
        }
        
        for string in strings! {
            addString(string)
        }
    }
}

