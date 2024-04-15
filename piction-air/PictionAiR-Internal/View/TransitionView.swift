//
//  TransitionView.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/5/23.
//

import SwiftUI

struct TransitionView: View {
    @EnvironmentObject var arPictionaryGame: ARPictionaryGame
    @Environment(\.colorScheme) var colorScheme
    @State private var showLeaderboard = false
    @State private var showLeaderboardEarly = false
    @State private var animate = false
    
    var body: some View {
        ZStack {
            VStack{
                if arPictionaryGame.roundNumber == 1 {
                    EmptyView()
                    
                } else if case .gameOver(_) = arPictionaryGame.currentState {
                    if animate {
                        if arPictionaryGame.playersWithMostPoints().contains(where: { $0 == arPictionaryGame.myPlayer?.name }) {
                            if arPictionaryGame.myPlayer?.points == 0 {
                                Text("Game Over!")
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .font(.system(size: 60))
                                    .fontDesign(.rounded)
                            } else {
                                Text("You Win!")
                                    .foregroundColor(.primary)
                                    .fontWeight(.heavy)
                                    .font(.system(size: 60))
                                    .fontDesign(.rounded)
                            }
                        } else {
                            Text("Game Over!")
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                                .font(.system(size: 60))
                                .fontDesign(.rounded)
                        }
                        if arPictionaryGame.myPlayer?.name != arPictionaryGame.correctGuesser {
                            if !showLeaderboard && !showLeaderboardEarly {
                                if arPictionaryGame.prevAnswer != nil {
                                    HStack {
                                        Text ("The word was")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                            .font(.system(size: 25))
                                            .fontDesign(.rounded)
                                        Text("\(arPictionaryGame.prevAnswer!)")
                                            .foregroundColor(colorScheme == .dark ? .yellow : .blue)
                                            .fontWeight(.heavy)
                                            .font(.system(size: 30))
                                            .fontDesign(.rounded)
                                    }
                                    .animation(.easeOut(duration: 0.5), value: showLeaderboard)
                                }
                            }
                        }
                    }
                } else {
                    if animate {
                        if arPictionaryGame.myPlayer?.name == arPictionaryGame.correctGuesser {
                            Text("Congratulations!")
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                                .font(.system(size: 45))
                                .fontDesign(.rounded)
                        } else {
                            Text("Round Over!")
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                                .font(.system(size: 60))
                                .fontDesign(.rounded)
                            if !showLeaderboard && !showLeaderboardEarly {
                                if arPictionaryGame.prevAnswer != nil {
                                    HStack {
                                        Text ("The word was")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                            .font(.system(size: 25))
                                            .fontDesign(.rounded)
                                        Text("\(arPictionaryGame.prevAnswer!)")
                                            .foregroundColor(colorScheme == .dark ? .yellow : .blue)
                                            .fontWeight(.heavy)
                                            .font(.system(size: 30))
                                            .fontDesign(.rounded)
                                    }
                                    .animation(.easeOut(duration: 0.5))
                                }
                            }
                        }
                    }
                }
                if showLeaderboard || showLeaderboardEarly {
                    LeaderboardView
                        //.frame(width: 300, height: 500)
                        .padding()
                        .background(.ultraThickMaterial)
                        .cornerRadius(10.0)
                        .animation(.easeOut(duration: 0.5))
                        .transition(.scale(scale: 0.8).combined(with: .opacity).animation(.spring()))
                        .fixedSize()
                }
            }
        }
        .animation(.spring())
        .onAppear {
            animate = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !showLeaderboardEarly {
                    showLeaderboard = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if arPictionaryGame.roundNumber == 1 {
                    showLeaderboardEarly = true
                }
            }
        }
    }
    
    private var LeaderboardView: some View {
        VStack() {
            Text("Leaderboard")
                .foregroundColor(.primary)
                .fontWeight(.heavy)
                .font(.system(size: 30))
                .fontDesign(.rounded)
            Text("")
                .font(.system(size: 10))
            if case .gameOver(_) = arPictionaryGame.currentState {
                
            } else {
                HStack {
                    HStack(spacing: 4) {
                        Text("\(arPictionaryGame.roundNumber)")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundStyle(colorScheme == .dark ? .yellow : .blue)
                            .contentTransition(.numericText())
                        Text("/ \(arPictionaryGame.totalNumberOfRounds)")
                            .font(.title2)
                            .fontWeight(.medium)
                            .contentTransition(.numericText())
                    }
                    
                    Spacer()
                    
                    Label(arPictionaryGame.drawer?.name.removeHostSuffix() ?? "???", systemImage: "paintbrush.pointed.fill")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                }
            }


//            Text("Drawer: \(arPictionaryGame.myPlayerIsCurrentDrawer ? "You" : arPictionaryGame.drawer?.name.removeHostSuffix() ?? "???")")
            
            ConnectedDevicesList(listItem: .players)
                
            
            Spacer()
            
            if case .gameOver(_) = arPictionaryGame.currentState {
                Button {
                    arPictionaryGame.finishGame()
                } label: {
                    Label("End Game", systemImage: "xmark.circle.fill")
                        .foregroundColor(.primary)
                }
                .buttonStyle(GlassButton())
                .background(Color.secondary)
                .cornerRadius(8.0)
                .font(.title2)
            } else {
                if arPictionaryGame.myPlayer?.name == arPictionaryGame.drawer?.name {
                    Button {
                        arPictionaryGame.startRound()
                    } label: {
                        Label("Begin Round", systemImage: "play.circle.fill")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(GlassButton())
                    .background(Color.secondary)
                    .cornerRadius(8.0)
                    .font(.title2)
                }
            }
        }
        .frame(width: 300)
    }
}
    



#Preview {
    let game = ARPictionaryGame()
    game.createGame()
    
    return TransitionView()
        .environmentObject(game)
}
