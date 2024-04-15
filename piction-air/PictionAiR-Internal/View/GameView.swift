//
//  GameView.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/5/23.
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var showingTransitionView = false
    @State private var text = ""
    @State var penColor = Color.blue
    @State var thickness : CGFloat = 0.005
    @EnvironmentObject var arPictionaryGame: ARPictionaryGame
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .topLeading) {
                DrawingView(penColor: $penColor, thickness: $thickness, arPictionaryGame: arPictionaryGame)

                if arPictionaryGame.myPlayer?.isGuesser == true && arPictionaryGame.currentState != .freeDraw {
                    guessOverlay
                }
                
                VStack(alignment: .leading) {
                    topBarView
                    
                    if arPictionaryGame.currentState != .freeDraw {
                        GuessesList(guesses: arPictionaryGame.guesses)
                    }
                }
                .padding()
            }
            
            if arPictionaryGame.myPlayer?.isDrawer == true || arPictionaryGame.currentState == .freeDraw {
                DrawingToolsPanel(penColor: $penColor, thickness: $thickness)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if arPictionaryGame.timeRemaining < 6 {
                otherTimer
            }
            switch arPictionaryGame.currentState {
            case .transition(_, _):
                transitionView
            case .gameOver:
                transitionView
            default:
                EmptyView()
            }
        }
        .onChange(of: arPictionaryGame.currentState) { newState in
            if arPictionaryGame.shouldEndGame() {
                dismiss()
            }
        }
    }
    
    private var topBarView: some View {
        HStack(spacing: 16) {
            if arPictionaryGame.gameMode == .pictionary {
                timerCountDown
                    .padding( .leading, UIScreen.main.bounds.width > 500 ? 27.5 : 0)
                
                Spacer()
                
                Text(arPictionaryGame.myPlayer?.isDrawer == true ? arPictionaryGame.currentWord : arPictionaryGame.currentWord.toUnderscore())
                    .fontWeight(.thin)
                    .monospaced()
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(8.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
            }
            
            Spacer()
            
            endGameButton
                .padding( .trailing, UIScreen.main.bounds.width > 500 ? 27.5 : 0)
        }
    }
    
    private var otherTimer: some View {
        ZStack {
            Circle()
                .opacity(0.5)
                .foregroundColor(.red)
            VStack{
                Text(" ")
                    .font(.system(size: 8))
                VStack(spacing: 6){
                    Image(systemName: "alarm.fill").opacity(0.5)
                        .scaleEffect(2)
                    Text("\(arPictionaryGame.timeRemaining)")
                        .fontWeight(.heavy)
                        .font(.system(size: 35))
                }
            }
            
        }
        .frame(width: 80, height: 80)
        .font(.caption)
    }
    
    private var timerCountDown: some View {
        ZStack {
            Circle()
                .opacity(0.5)
                .foregroundColor(.red)
                .shadow(radius: 10)
            VStack(spacing: 3){
                Image(systemName: "alarm.fill").opacity(0.5)
                Text("\(arPictionaryGame.timeRemaining)")
                    .bold()
            }
        }
        .frame(width: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50, height: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50)
        .font(.caption)
    }
    
    private var endGameButton: some View {
        Menu {
            if let myPlayer = arPictionaryGame.myPlayer {
                Section {
                    if arPictionaryGame.playerCanGiveUp() || myPlayer.isDrawer {
                        Button { arPictionaryGame.skipRound() } label: {
                            Label((myPlayer.isDrawer ? "Skip Round" : "Become Spectator"), systemImage: myPlayer.isDrawer ? "forward.fill" : "eye")
                        }
                    }
                }
                
                Section {
                    if !myPlayer.name.hasSuffix(MultipeerSession.hostSuffix) {
                        Button(role: .destructive) { arPictionaryGame.leaveGame() } label: {
                            Label("Leave Game", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    
                    Button(role: .destructive) {
                        if arPictionaryGame.currentState != .freeDraw {
                            arPictionaryGame.endGame()
                        } else {
                            arPictionaryGame.finishGame()
                        }
                    } label: {
                        Label("End Game", systemImage: "xmark.seal.fill")
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .frame(width: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50, height: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50)
                    .foregroundStyle(.ultraThickMaterial)
                    .shadow(radius: 10)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 2)
                            .frame(width: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50, height: (UIScreen.main.bounds.width / 9) < 50 ? UIScreen.main.bounds.width / 9 : 50)
                    )

                Image(systemName: "rectangle.portrait.and.arrow.forward.fill")
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    private var guessOverlay: some View {
        VStack {
            Spacer()
            
            TextField("Guess", text: $text)
                .onSubmit {
                    arPictionaryGame.didGuessWord(text)
                    text = ""
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(8.0)
        }
        .padding()
    }
    
    private var transitionView: some View {
        ZStack {
            TransitionView()
                //.frame(width: 300, height: 500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
    }
}

fileprivate struct GuessesList: View {
    var guesses: [GameManager<String>.Guess]
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(guesses) { guess in
                    VStack(alignment: .leading) {
                        Text(guess.value)
                            .fontWeight(.semibold)
                            .font(.subheadline)
                        Text(guess.owner.name.removeHostSuffix())
                            .fontWeight(.thin)
                            .font(.caption)
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8.0)
                    .frame(minWidth: 125, alignment: .leading)
                }
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .scrollIndicators(.hidden)
        .animation(.spring(), value: guesses)
        .padding(.top)
        .frame(height: 300)
        .mask(
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .center, endPoint: .bottom)
        )
    }
}

#Preview {
    GameView()
        .environmentObject(ARPictionaryGame())
}

#Preview("Guesses") {
    GuessesList(guesses: [
        .init(owner: .init(name: "Player 1", role: .guesser),
              value: "Guessssss 1"),
        .init(owner: .init(name: "Player 2", role: .guesser),
              value: "Guess 2"),
        .init(owner: .init(name: "Player 3", role: .guesser),
              value: "Guess 3"),
        .init(owner: .init(name: "Player 4", role: .guesser),
              value: "Guess 4"),
        .init(owner: .init(name: "Player 5", role: .guesser),
              value: "Guess 5"),
        .init(owner: .init(name: "Player 6", role: .guesser),
              value: "Guess 6"),
    ])
}
