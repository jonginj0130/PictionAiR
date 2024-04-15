//
//  ChatDebugView.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/5/23.
//

import SwiftUI

struct ChatDebugView: View {
    @ObservedObject var arPictionaryGame = ARPictionaryGame()
    @State var text = ""
    
    var body: some View {
        VStack {
            List {
                Section("Players") {
                    ForEach(arPictionaryGame.players) { player in
                        Text(player.name)
                    }
                }
                
                Section("Guesses") {
                    ForEach(arPictionaryGame.guesses) { guess in
                        VStack {
                            Text(guess.value)
                            Text(guess.owner.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            TextField("Guess", text: $text)
                .onSubmit {
                    arPictionaryGame.didGuessWord(text)
                }
        }
    }
}

#Preview {
    ChatDebugView()
}
