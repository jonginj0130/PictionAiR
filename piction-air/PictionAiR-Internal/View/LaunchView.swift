//
//  LaunchView.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/5/23.
//

import SwiftUI

struct LaunchView: View {
    enum ViewState {
        case connectingPlayers
        case gameOptions
    }
    
    @StateObject var arPictionaryGame: ARPictionaryGame = ARPictionaryGame()
    @State private var showGameView = false
    @State private var wordsLoading = false
    @State private var name = ""
    @State private var sessionRole: ConnectedDevicesList.ListItem?
    @FocusState private var isFocused: Bool
    @State private var customCategoryName = ""
    @State private var currentViewState: ViewState = .connectingPlayers

        
    var body: some View {
        ZStack {
            FloatingClouds()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                headerView
                
                if sessionRole != nil {
                    VStack(alignment: .center, spacing: 16) {
                        if sessionRole == .connectedPeers {
                            gameModePicker
                                .padding(8)
                                .background(.thinMaterial)
                                .cornerRadius(8.0)
                        }
                        
                        connectedDevicesList
                        
                        if sessionRole == .connectedPeers {
                            if arPictionaryGame.userSetGameMode != .freeDraw {
                                gameOptionsPanel
                                    .padding(8)
                                    .background(.thinMaterial)
                                    .cornerRadius(8.0)
                            }
                            
                            Spacer()

                            startGameButton
                        }
                    }
                    .frame(width: 325)
                    .frame(maxHeight: 400)
                } else {
                    nameField
                    gameSessionButtons
                }
            }
            .padding()
        }
        .overlay(alignment: .topLeading) {
            if sessionRole != nil {
                backButton
                    .padding(16)
            }
        }
        .onChange(of: arPictionaryGame.currentState) { state in
            if case .transition(_) = state {
                showGameView = true
            } else if let myPlayer = arPictionaryGame.myPlayer, case .playing(_, _, _) = state, myPlayer.role == .spectator {
                showGameView = true
            } else if case .gameOver = state {
                showGameView = true
            } else if case .freeDraw = state {
                showGameView = true
            }
        }
        .animation(.easeInOut, value: arPictionaryGame.players)
        .animation(.easeInOut, value: currentViewState)
        .fullScreenCover(isPresented: $showGameView) {
            GameView()
                .onAppear { arPictionaryGame.createGame() }
        }
        .environmentObject(arPictionaryGame)
        .animation(.spring(), value: name.isEmpty)
        .animation(.spring(), value: sessionRole)
        .animation(.easeInOut, value: arPictionaryGame.userSetGameMode)
    }
    
    private var backButton: some View {
        Button {
            sessionRole = nil
            arPictionaryGame.endSession()
        } label: {
            Label("Back", systemImage: "arrowshape.backward.circle.fill")
        }
        .foregroundStyle(.ultraThickMaterial)
        .tint(.red)
        .font(.title2)
    }
    
    private var gameOptionsPanel: some View {
        
        let isButtonDisabled = (arPictionaryGame.connectedPeers.isEmpty || wordsLoading) && (arPictionaryGame.userSetGameMode != .freeDraw)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Game Options")
                    .font(.title2)
                    .bold()
                
                Spacer()
            }
            .contentShape(Rectangle())
            .foregroundStyle(!isButtonDisabled ? .primary : .secondary)
            .onTapGesture {
                currentViewState = (currentViewState == .connectingPlayers) ? .gameOptions : .connectingPlayers
            }
            .disabled(isButtonDisabled)
            
            
            if currentViewState == .gameOptions {
                roundsPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                timerPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                categoryPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .font(.title3)
        .frame(maxWidth: .infinity)
    }
    
    private var gameModePicker: some View {
        VStack(spacing: 8) {
            Text("Mode")
                .font(.title2)
                .bold()
                        
            Picker("Select a mode", selection: $arPictionaryGame.userSetGameMode) {
                ForEach(GameManager<String>.GameMode.allCases, id: \.self) { gameMode in
                    Text(gameMode.rawValue)
                        .tag(gameMode)
                }
            }
            .pickerStyle(.segmented)
            .accentColor(.primary)
            .background(Color.secondary.opacity(0.15))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var roundsPicker: some View {
        HStack(spacing: 8) {
            Text("Rounds")
                .bold()
            
            Spacer()
                            
            Stepper(value: $arPictionaryGame.numberOfRounds, in: arPictionaryGame.allowedNumberOfRoundsRange) {
                Text("\(arPictionaryGame.numberOfRounds)")
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut, value: arPictionaryGame.numberOfRounds)
                    .bold()
            }
            .frame(width: 125)
        }
    }
    
    private var timerPicker: some View {
        HStack(spacing: 8) {
            Text("Time")
                .bold()
            
            Spacer()
                            
            Stepper(value: $arPictionaryGame.userSetTimeRemaining, in: arPictionaryGame.allowedTimerRange, step: 5) {
                Text("\(arPictionaryGame.userSetTimeRemaining) secs")
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut, value: arPictionaryGame.userSetTimeRemaining)
                    .bold()
            }
            .frame(width: 175)
        }
    }
    
    @ViewBuilder
    private var categoryPicker: some View {
        HStack(spacing: 8) {
            Text("Category")
                .bold()
            
            Spacer()
            
            Picker("Select a category", selection: $arPictionaryGame.selectedCategory) {
                Section(header:Text("Preset")) {
                    ForEach(arPictionaryGame.prompts.filter {!$0.isCustom}) { prompt in
                        Text(prompt.name)
                            .tag(prompt)
                    }
                }
                Section(header:Text("Custom")) {
                    ForEach(arPictionaryGame.prompts.filter {$0.isCustom}) { prompt in
                        Text(prompt.name)
                            .tag(prompt)
                    }
                }
            }
            .pickerStyle(.menu)
            .accentColor(.primary)
        }
        
        if arPictionaryGame.selectedCategory.name == "New Custom" {
            TextField("Custom category...", text: $customCategoryName)
                .padding(6)
                .background(.thinMaterial)
                .cornerRadius(8)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("PictionAiR")
                .fontWeight(.heavy)
                .font(.system(size: 69))
                .foregroundStyle(.thickMaterial)
                .fontDesign(.rounded)
                .transition(.defaultLaunchViewTransition)
        }
    }
    
    private var nameField: some View {
        HStack {
            TextField("Name", text: $name)
                .font(.system(size: 21))
                .fontDesign(.monospaced)
                .frame(width: 280, height: 35)
                .padding(6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .submitLabel(.done)
                .focused($isFocused)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
        }
        .transition(.defaultLaunchViewTransition)
        .opacity(name.isEmpty ? 0.9 : 1)
    }
    
    private var connectedDevicesList: some View {
        Group {
            if let sessionRole = sessionRole {
                ConnectedDevicesList(listItem: sessionRole)
                    .background(.thinMaterial)
                    .cornerRadius(8.0)
                    .mask(
                        LinearGradient(gradient: Gradient(colors: currentViewState == .gameOptions && arPictionaryGame.userSetGameMode != .freeDraw ? [Color.black, Color.black.opacity(0)] : [Color.black.opacity(1)]), startPoint: .center, endPoint: .bottom)
                    )
                    .onTapGesture {
                        currentViewState = (currentViewState == .gameOptions) ? .connectingPlayers : .connectingPlayers
                    }
            }
        }
        .transition(.defaultLaunchViewTransition)
        .frame(minHeight: 75)
    }
    
    private var startGameButton: some View {
        let isButtonDisabled = (arPictionaryGame.connectedPeers.isEmpty || wordsLoading) && (arPictionaryGame.userSetGameMode != .freeDraw)
        
        return Button(currentViewState == .connectingPlayers && arPictionaryGame.userSetGameMode != .freeDraw ? "Continue" : "Start Game") {
            if currentViewState == .connectingPlayers && arPictionaryGame.userSetGameMode != .freeDraw {
                currentViewState = .gameOptions
            } else {
                Task {
                    let categoryName = arPictionaryGame.selectedCategory.isCustom ? customCategoryName : arPictionaryGame.selectedCategory.name
                    
                    wordsLoading = true
                    if arPictionaryGame.gameMode == .pictionary {
                        await arPictionaryGame.setAnswerBank(category: categoryName)
                    }
                    wordsLoading = false
                    
                    showGameView = true
                }
            }
        }
        .buttonStyle(GlassButton())
        .disabled(isButtonDisabled)
        .foregroundStyle(isButtonDisabled ? .ultraThinMaterial : .thick)
        .font(.title2)
        .opacity(isButtonDisabled ? 0.4 : 1)
        .animation(.spring(), value: isButtonDisabled)
        .overlay(alignment: .trailing) {
            ProgressView()
                .opacity(wordsLoading ? 1 : 0)
                .offset(x: 32)
        }
    }
    
    private var gameSessionButtons: some View {
        VStack(spacing: 16) {
            Button("Begin a game") {
                if isFocused {
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.sessionRole = .connectedPeers
                        self.arPictionaryGame.startSession(withName: name, isHost: true)
                    }
                } else {
                    self.sessionRole = .connectedPeers
                    self.arPictionaryGame.startSession(withName: name, isHost: true)
                }
            }
            
            Button("Join a game") {
                if isFocused {
                    isFocused = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.sessionRole = .availablePeers
                        self.arPictionaryGame.startSession(withName: name)
                    }
                } else {
                    self.sessionRole = .availablePeers
                    self.arPictionaryGame.startSession(withName: name)
                }
            }
        }
        .buttonStyle(GlassButton())
        .transition(.defaultLaunchViewTransition)
        .font(.title2)
        .opacity(name.isEmpty ? 0.4 : 1)
        .disabled(name.isEmpty)
    }
}

fileprivate extension AnyTransition {
    static var defaultLaunchViewTransition: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading).combined(with: .opacity))
    }
}

#Preview {
    LaunchView()
}
