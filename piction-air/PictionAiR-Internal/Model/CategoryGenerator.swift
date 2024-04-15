//
//  CategoryGenerator.swift
//  PictionAiR
//
//  Created by Sankaet Cheemalamarri on 11/9/23.
//

import Foundation
import OpenAIKit

struct CategoryGenerator {
    var category: String
    let openAI = OpenAIKit(apiToken: "<YOUR OPEN AI API KEY>")
    
    func processString(input: String) -> [String] {
        let lines = input.components(separatedBy: "\n")[2...]
        let processedLines = lines.map { line in
            if line.count >= 3 {
                let startIndex = line.index(line.startIndex, offsetBy: 3)
                return String(line[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return line
            }
        }
        return processedLines
    }
    
    func performOpenAISearch() async -> [String] {
        let result = await openAI.sendCompletion(prompt: "Provide a list of 10 prompts for a pictionary game with this category: \(category) in list format", model: .gptV3_5(.davinciText003), maxTokens: 200)
        
        switch result {
        case .success(let aiResult):
            if let text = aiResult.choices.first?.text {
                print("response text: \(text)")
                return processString(input: text)
            }
        case .failure(let error):
            print(error.localizedDescription)
        }
        
        return []
    }
    
    
}

