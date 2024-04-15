//
//  ARPictionaryGame.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/2/23.
//

// MARK: - THIS FILE ACTS AS THE VIEW MODEL

import SwiftUI
import MultipeerConnectivity
import Combine

class ARPictionaryGame: ObservableObject, GameManagerTimerDelegate {
    private struct GameData: Codable {
        let gameManager: GameManager<String>
        let userSetTimeRemaining: Int?
    }
    
    struct WordCategory: Identifiable, Hashable, Codable {
        var id: String { name }
        
        let name: String
        let words: [String]
        let isCustom: Bool
        
        static let defaultCategories: [WordCategory] = [
            .init(name: "Shapes", words: ["Circle", "Square", "Triangle", "Heart", "Star", "Rectangle", "Diamond", "Pentagon", "Hexagon", "Crescent", "Sphere", "Cone", "Cylinder", "Trapezoid", "Semicircle"], isCustom: false),
            .init(name: "Objects", words: ["Book", "Cup", "Chair", "Car", "Key", "Candle", "Pillow", "Clock", "Balloons", "Phone", "Lamp", "Umbrella", "Flower", "Spoon", "Coin", "Table", "Bed", "Window", "Mirror", "Suitcase", "Tree", "Cloud"], isCustom: false),
            .init(name: "Fruits", words: ["Apple", "Orange", "Banana", "Grapes", "Strawberry", "Watermelon", "Lemon", "Cherry", "Peach", "Pear", "Mango", "Kiwi", "Pineapple", "Papaya", "Blueberry", "Raspberry", "Coconut", "Pomegranate", "Dragon fruit", "Avocado", "Pumpkin"], isCustom: false),
            .init(name: "Animals", words: ["Fish", "Cat", "Dog", "Bird", "Butterfly", "Elephant", "Duck", "Snake", "Turtle", "Ladybug", "Lion", "Zebra", "Panda", "Frog", "Shark", "Giraffe", "Monkey", "Koala", "Crocodile", "Penguin", "Seahorse", "Bear", "Horse"], isCustom: false),
            .init(name: "Instruments", words: ["Guitar", "Piano", "Drums", "Flute", "Trumpet", "Violin", "Saxophone", "Tambourine", "Harp", "Clarinet", "Cello", "Trombone", "Accordion", "Xylophone", "Triangle"], isCustom: false),
            .init(name: "Clothing", words: ["T Shirt", "Shoes", "Hat", "Socks", "Dress", "Pants", "Glasses", "Tie", "Scarf", "Gloves", "Jacket", "Skirt", "Hoodie", "Jeans", "Boots", "Belt", "Necklace", "Sunglasses"], isCustom: false),
            .init(name: "Sports", words: ["Soccer", "Basketball", "Baseball", "Tennis", "Golf", "Football", "Volleyball", "Bowling", "Hockey", "Surfing", "Cricket", "Skiing", "Skateboarding", "Badminton", "Boxing", "Frisbee", "Fencing", "Swimming"], isCustom: false),
        ]
    }
    
    @Published private var gameManager = GameManager(numberOfRounds: 5, answerBank: [""])
    @Published private(set) var multipeerSession: MultipeerSession?
    
    @Published private(set) var availablePeers: [MCPeerID] = []
    @Published private(set) var connectedPeers: [MCPeerID] = []
    
    @Published private(set) var prompts: [WordCategory] = WordCategory.defaultCategories + [.init(name: "New Custom", words: [""], isCustom: true)]
    
    @Published var selectedCategory: WordCategory = WordCategory.defaultCategories[0]

    @Published var isCurrentlyDrawing = true
    private var customCategories: [WordCategory] = []
    @Published var canAnalyzeDrawing = false
    
    var myPlayer: GameManager<String>.Player? {
        gameManager.players.first { player in
            player.name ==  displayName
        }
    }
    
    var currentState: GameManager<String>.GameState {
        gameManager.gameState
    }
    
    var correctGuesser: String? {
        gameManager.correctGuesser
    }
    
    var players: [GameManager<String>.Player] {
        gameManager.players
    }
    
    var sortedPlayers: [GameManager<String>.Player] {
        gameManager.players.sorted(by: { $0.points > $1.points })
    }
    
    var guesses: [GameManager<String>.Guess] {
        gameManager.guesses
    }
    
    var prevAnswer: String? {
        if case .transition(let prevAnswer, _) = currentState {
            return prevAnswer
        } else if case .gameOver(let prevAnswer) = currentState {
            return prevAnswer
        }
        return nil
    }
    
    var roundNumber: Int {
        if case .transition(_, let nextState) = currentState, case .playing(let round, _, _) = nextState {
            return round
        } else if case .playing(let round, _, _) = currentState {
            return round
        }
        
        return -1
    }
    
    var totalNumberOfRounds: Int {
        gameManager.numberOfRounds
    }
    
    var drawer: GameManager<String>.Player? {
        gameManager.currentDrawer
    }
    
    var myPlayerIsCurrentDrawer: Bool {
        drawer == myPlayer
    }
    
    var currentWord: String {
        guard case .playing(_, let answer, _) = currentState else { return "???" }
        
        return answer
    }
    
    var gameMode: GameManager<String>.GameMode {
        gameManager.gameMode
    }
    
    @Published var userSetTimeRemaining: Int = GameManager<String>.defaultMaxTimeRemaining
    @Published var timeRemaining: Int = GameManager<String>.defaultMaxTimeRemaining
    internal var timer: Timer?
    private var subscriptions = Set<AnyCancellable>()
    private(set) var displayName: String?
    
    var didReceiveDataHandler: ((Data, MCPeerID) -> Void)?
    var arSnapshotHandler: (() -> Void)?
    var undoHandler: (() -> Void)?
    var redoHandler: (() -> Void)?
    var clearHandler: (() -> Void)?
    var imageRecognitionHandler: (() -> Void)?
    
    @Published var numberOfRounds: Int = GameManager<String>.defaultNumberOfRounds
    @Published var userSetGameMode: GameManager<String>.GameMode = .pictionary
    
    var allowedNumberOfRoundsRange: ClosedRange<Int> {
        1...(selectedCategory.name == "New Custom" ? 10 : selectedCategory.words.count)
    }
    
    var allowedTimerRange: ClosedRange<Int> {
        10...90
    }
    
    init() {
        gameManager.timerDelegate = self
        gameManager.gameStateDidChangeHandler = self.gameStateDidChangeHandler
        if let savedCustomCategoriesData = UserDefaults.standard.data(forKey: "customCategories") {
            do {
                let decoder = JSONDecoder()
                let savedCustomCategories = try decoder.decode([WordCategory].self, from: savedCustomCategoriesData)
                customCategories = savedCustomCategories
                prompts = WordCategory.defaultCategories + [.init(name: "New Custom", words: [""], isCustom: true)] + savedCustomCategories
            } catch {
                print("Unable to Decode categories (\(error))")
            }
        }
    }
    
    // MARK: - Intents
    
    func disconnectFromSession() {
        multipeerSession?.session.disconnect()
    }
    
    func endSession() {
        multipeerSession?.endSession()
        connectedPeers.removeAll()
        availablePeers.removeAll()
    }
    
    func startSession(withName name: String, isHost: Bool = false) {
        self.displayName = name + (isHost ? MultipeerSession.hostSuffix : "")
        
        endSession()
        
        multipeerSession = MultipeerSession(displayName: name, isHost: isHost)
        multipeerSession?.gameDelegate = self
    }
    
    func requestToConnectWith(_ peer: MCPeerID) {
        guard let multipeerSession = multipeerSession else { return }
        
        multipeerSession.serviceBrowser.invitePeer(peer,
            to: multipeerSession.session,
            withContext: nil,
            timeout: 30
        )
    }
    
    func createGame() {
        guard let displayName = displayName else { return }
        
        
        if gameManager.gameState == .waitingToBegin {
            gameManager.addPlayer(.init(name: displayName, role: .spectator))
            
            connectedPeers.map { $0.displayName }.forEach {
                gameManager.addPlayer(withName: $0, role: .spectator)
            }
            
            gameManager.createGame(rounds: numberOfRounds, gameMode: userSetGameMode)
            
            sendGameManager(gameManager, userSetTimeRemaining: userSetTimeRemaining)
        } else if gameManager.gameState == .finished {
            gameManager.createGame(rounds: numberOfRounds, gameMode: userSetGameMode)
            
            sendGameManager(gameManager, userSetTimeRemaining: userSetTimeRemaining)
        } else {
            print("ARPictionaryGame: trying to begin game from gameState other than waitingToBegin or finished")
        }
    }
    
    func setAnswerBank(category: String) async {
        if let indexOfPrompt = prompts.firstIndex(where: { $0.name == category }) {
            DispatchQueue.main.async {
                self.gameManager.setAnswerBank(answerBank: self.prompts[indexOfPrompt].words)
            }
        } else {
            let categoryGenerator = CategoryGenerator(category: category)
            let response = await categoryGenerator.performOpenAISearch()
            gameManager.setAnswerBank(answerBank: response)
            let newCategory = WordCategory(name: category, words: response, isCustom: true)
            customCategories.append(newCategory)
            if customCategories.count > 3 {
                customCategories.removeFirst()
            }
            prompts = WordCategory.defaultCategories + [.init(name: "New Custom", words: [""], isCustom: true)] + customCategories
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(customCategories)
                UserDefaults.standard.set(data, forKey: "customCategories")
            } catch {
                print("Unable to Encode categories (\(error))")
            }
            print(response)
        }
        print("Called set Answer Bank")
    }
    
    func startRound() {
        clearAllAnchors()
        gameManager.beginRound()
        sendGameManager(gameManager)
    }
    
    func playersWithMostPoints() -> [String] {
        var highScore = 0
        var bestPlayers: [String] = []
        self.players.forEach { player in
            if player.points >= highScore {
                highScore = player.points
            }
        }
        self.players.forEach { player in
            if player.points == highScore {
                bestPlayers.append(player.name)
            }
        }
        return bestPlayers
    }
    
    func playerCanGiveUp() -> Bool {
        guard let myPlayer = myPlayer else { return false }
        
        return players.count > 2 && myPlayer.isGuesser
    }
    
    func skipRound() {
        guard let myPlayer = myPlayer else { return }
        
        gameManager.playerDidRequestToSkipRound(myPlayer)
        
        sendGameManager(gameManager)
    }
    
    func didGuessWord(_ guess: String) {
        guard let myPlayer = myPlayer else { return }
        gameManager.playerDidGuess(
            GameManager<String>.Guess(owner: myPlayer,
                                      value: guess)
        )
        
        sendGameManager(gameManager)
    }
    
    func leaveGame() {
        self.multipeerSession?.session.disconnect()
        
        self.gameManager.finishGame()
        sendGameManager(gameManager)
    }
    
    func shouldEndGame() -> Bool {
        currentState == .finished || players.count <= 1
    }
    
    func endGame() {
        gameManager.endGame()
        
        sendGameManager(gameManager)
    }
    
    func finishGame() {
        gameManager.finishGame()
        
        sendGameManager(gameManager)
    }
    
    func snapShot() {
        arSnapshotHandler?()
    }
    
    func undo() {
        undoHandler?()
    }
    
    func redo() {
        redoHandler?()
    }
  
    func clearAllAnchors() {
        clearHandler?()
    }
    
    func imageRecognition() {
        imageRecognitionHandler?()
    }
    
    // MARK: - GameManagerTimerDelegate Methods
    
    func timerDelegateRoundDidBegin() {
        resetAndStopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: handleTimer)
    }
    
    func timerDelegateRoundDidEnd() {
        resetAndStopTimer()
    }
    
    // MARK: - Private
    
    private func resetAndStopTimer() {
        timer?.invalidate()
        timeRemaining = userSetTimeRemaining
    }
    
    private func handleTimer(_ timer: Timer) {
        timeRemaining -= 1
        if timeRemaining <= 0 {
            clearAllAnchors()
            resetAndStopTimer()
            gameManager.timeEnds()
            
            sendGameManager(gameManager)
        }
    }
    
    private func gameStateDidChangeHandler(_ gameState: GameManager<String>.GameState) {
        guard myPlayer?.name.hasSuffix(MultipeerSession.hostSuffix) == true else { return }
        
        if gameState != .finished && gameState != .waitingToBegin {
            multipeerSession?.serviceAdvertiser.stopAdvertisingPeer()
        } else {
            multipeerSession?.serviceAdvertiser.startAdvertisingPeer()
        }
    }
    
}

// MARK: - Multiplayer
extension ARPictionaryGame: MultiplayerGameSessionDelegate {
    func peerDidChangeState(_ peer: MCPeerID, to newState: MCSessionState) {
        if newState == .connected {
            connectedPeers.append(peer)
            
            if currentState == .freeDraw {
                sendGameManager(gameManager)
            } else if currentState != .waitingToBegin {
                gameManager.addPlayer(withName: peer.displayName, role: .spectator)
                sendGameManager(gameManager)
            }
        } else if newState == .notConnected {
            if peer.displayName.hasSuffix(MultipeerSession.hostSuffix) {
                connectedPeers.removeAll()
                multipeerSession?.session.disconnect()
            } else {
                connectedPeers.removeAll {
                    peer == $0
                }

                gameManager.removePlayer(withID: peer.displayName)
                if gameManager.players.count <= 1 {
                    endGame()
                }
            }
        }
    }
    
    func didFindPeer(_ peer: MCPeerID) {
        self.availablePeers.append(peer)
    }
    
    func didLosePeer(_ peer: MCPeerID) {
        self.availablePeers.removeAll(where: {
            $0 == peer
        })
    }
    
    func didReceiveData(_ data: Data, from id: MCPeerID) {
        if let decodedGameData = try? JSONDecoder().decode(GameData.self, from: data) {
            gameManager.updateGameManager(using: decodedGameData.gameManager)
            
            if let userSetTimeRemaining = decodedGameData.userSetTimeRemaining {
                self.userSetTimeRemaining = userSetTimeRemaining
            }
        }
        
        didReceiveDataHandler?(data, id)
    }
    
    // Sends new state to other devices
    func sendGameManager(_ gameManager: GameManager<String>, userSetTimeRemaining: Int? = nil) {
        guard let multipeerSession = multipeerSession else { return }
        
        let gameData = GameData(gameManager: gameManager, userSetTimeRemaining: userSetTimeRemaining)
        
        if let encodedData = try? JSONEncoder().encode(gameData) {
            multipeerSession.sendToAllPeers(encodedData, reliably: true)
            
        } else {
            print("ARPictionaryGame.sendGameManager: Error encoding game data. Did not send.")
        }
    }
}
