//
//  GameManager.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/2/23.
//

import Foundation
import Combine

protocol GameManagerTimerDelegate {
    var timeRemaining: Int { get set }
    var timer: Timer? { get set }
    func timerDelegateRoundDidBegin()
    func timerDelegateRoundDidEnd()
}

struct GameManager<GameValue: Equatable & Codable>: Codable {
    static var defaultNumberOfRounds: Int { 5 }
    static var defaultMaxTimeRemaining: Int { 45 } // in seconds
    
    enum GameMode: String, Codable, CaseIterable {
        case pictionary = "Pictionary"
        case freeDraw = "Free Draw"
    }
    
    struct Player: Codable, Identifiable, Equatable {
        enum Role: Int, Codable {
            case drawer = 0
            case guesser
            case spectator
        }
        
        let id: String
        let name: String
        var role: Role
        var points: Int
                
        init(name: String, role: Role) {
            self.id = name
            self.name = name
            self.role = role
            self.points = 0
        }
        
        var isDrawer: Bool { role == .drawer }
        var isGuesser: Bool { role == .guesser }
        
        static func == (lhs: Player, rhs: Player) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct Guess: Codable, Identifiable, Equatable {
        let id: UUID
        let owner: Player
        let value: GameValue
        
        init(owner: Player, value: GameValue) {
            self.id = UUID()
            self.owner = owner
            self.value = value
        }
    }
    
    indirect enum GameState: Codable, Equatable {
        case waitingToBegin
        case freeDraw
        case playing(round: Int, answer: GameValue, drawer: Player)
        case transition(prevAnswer: GameValue?, nextState: GameState)
        case gameOver(prevAnswer: GameValue?)
        case finished
    }
    
    private(set) var numberOfRounds: Int
    let pointsPerCorrectAnswer: Int
    private(set) var players: [Player]
    private(set) var guesses: [Guess] {
        didSet { showGuesses() }
    }
    private(set) var gameState: GameState {
        didSet {
            showGameState()
            gameStateDidChangeHandler?(gameState)
            if case .transition(_, let nextState) = gameState, case .playing(_, _, let drawer) = nextState {
                updatePlayerRoles(currentDrawer: drawer)
                if gameMode != .freeDraw {
                    timerDelegate?.timerDelegateRoundDidEnd()
                }
            } else if case .playing(_, _, _) = gameState {
                if gameMode != .freeDraw {
                    timerDelegate?.timerDelegateRoundDidBegin()
                }
            } else if case .finished = gameState {
                timerDelegate?.timerDelegateRoundDidEnd()
            } else if case .gameOver(_) = gameState {
                timerDelegate?.timerDelegateRoundDidEnd()
            }
        }
    }
    private(set) var gameMode: GameMode = .pictionary
    private var answerBank: [GameValue]
    private var usedAnswers: [GameValue] = []
    var prevAnswer: GameValue?
    
    @CodableIgnored
    var timerDelegate: GameManagerTimerDelegate?
    @CodableIgnored
    var gameStateDidChangeHandler: ((GameState) -> Void)?
    
    var currentDrawer: Player? {
        if case .transition(_, let nextState) = gameState, case .playing(_, _, let drawer) = nextState {
            return drawer
        } else if case .playing(_, _, let drawer) = gameState {
            return drawer
        }
        
        return nil
    }
    
    var correctGuesser : String?
    
    /// If the number of words in answerBank is less than numberOfRounds, numberOfRounds is capped at answerBank.count
    init(numberOfRounds: Int = Self.defaultNumberOfRounds, answerBank: [GameValue], pointsPerCorrectAnswer: Int = 5, gameMode: GameMode = .pictionary) {
        self.answerBank = answerBank
        self.numberOfRounds = min(numberOfRounds, answerBank.count)
        self.pointsPerCorrectAnswer = pointsPerCorrectAnswer
        self.players = []
        self.guesses = []
        self.gameState = .waitingToBegin
        self.gameMode = gameMode
    }
    
    // MARK: - Intents
    
    mutating func createGame(rounds: Int? = nil, gameMode: GameMode = .pictionary) {
        guard let answer = answerBank.randomElement(), let drawer = players.randomElement() else { return }
        
        self.gameMode = gameMode
        if gameMode == .freeDraw {
            gameState = .freeDraw
            players.indices.forEach { players[$0].role = .spectator }
            return
        }
        
        if let rounds = rounds {
            self.numberOfRounds = min(rounds, answerBank.count)
        }
        
        let nextState = GameState.playing(round: 1, answer: answer, drawer: drawer)
        gameState = .transition(prevAnswer: nil, nextState: nextState)
    }
    
    mutating func beginRound() {
        if case .transition(_, let nextState) = gameState {
            gameState = nextState
        } else {
            print("GameManager: Trying to begin round from non-transition state \(gameState)")
        }
    }
    
    mutating func addPlayer(withName name: String, role: Player.Role) {
        if !players.contains(where: { $0.name == name }) {
            players.append(Player(name: name, role: role))
        } else {
            print("GameManager: Trying to add existing Player with name \(name)")
        }
    }
    
    mutating func addPlayer(_ player: Player) {
        if !players.contains(where: { $0.name == player.name }) {
            players.append(player)
        } else {
            print("GameManager: Trying to add existing Player with id \(player.id)")
        }
    }
    
    mutating func removePlayer(withID id: Player.ID) {
        if let player = players.first(where: { $0.id == id }) {
            players.removeAll(where: { $0 == player })

            if player == currentDrawer  {
                drawerDidQuit()
            }
        } else {
            print("GameManager: Trying to remove non-existent Player with id \(id)")
        }
    }
    
    mutating func playerDidRequestToSkipRound(_ player: Player) {
        if case .playing(let round, _, _) = gameState {
            if player == currentDrawer {
                if round < numberOfRounds {
                    moveToNextRound()
                } else {
                    endGame()
                }
            } else {
                if players.count > 2 {
                    if let indexOfPlayer = players.firstIndex(of: player) {
                        players[indexOfPlayer].role = .spectator
                    } else {
                        print("GameManager: Cannot find player that wants to give up??")
                    }
                } else {
                    // TODO: We might want to change this behavior.
                    print("GameManager: The only guesser in the game cannot give up.")
                }
            }
        } else {
            print("GameManager: Trying to skip round from gameState other than .playing ... gameState = \(gameState)")
        }
    }
    
    mutating func playerDidGuess(_ guess: Guess) {
        if case .playing(let round, let answer, _) = gameState {
            //correctGuesser = nil
            self.guesses.insert(guess, at: 0)
            if let guessString = guess.value as? String, let answerString = answer as? String {
                if guessString.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(answerString) == .orderedSame {
                    playerDidGuessCorrectly(guess, round)
                }
            } else {
                if (guess.value == answer) {
                    playerDidGuessCorrectly(guess, round)
                }
            }
            
        } else {
            print("GameManager: Trying to guess from gameState other than .playing ... gameState = \(gameState)")
        }
    }
        
    mutating func drawerDidQuit() {
        if case .transition(_, _) = gameState {
            createGame()
        } else if case .playing(let round, _, _) = gameState {
            if round < numberOfRounds {
                moveToNextRound(restartExistingRound: true)
            } else {
                endGame()
            }
        } else {
            print("GameManager: Drawer quit from gameState other than .playing ... gameState = \(gameState)")
        }
    }
    
    mutating func setAnswerBank(answerBank: [GameValue]) {
        self.answerBank = answerBank
        self.numberOfRounds = min(Self.defaultNumberOfRounds, answerBank.count)
    }
    
    mutating func endGame() {
        if case .playing(_, let answer, _) = gameState {
            gameState = .gameOver(prevAnswer: answer)
            guesses.removeAll()
        } else if case .freeDraw = gameState {
            gameState = .finished
        }
    }
    
    mutating func finishGame() {
        gameState = .finished
        guesses.removeAll()
        for i in 0..<self.players.count {
            self.players[i].points = 0
        }
        prevAnswer = nil

    }
    
    mutating func updateGameManager(using other: GameManager<GameValue>) {
        correctGuesser = nil
        let playersToAdd = other.players.filter { !self.players.contains($0) }
        print("playersToAdd: \(playersToAdd)")
        
        self.players.append(contentsOf: playersToAdd)
        updateExistingPlayers(using: other.players)
        
        self.guesses = other.guesses
        
        if self.gameState != other.gameState {
            self.gameState = other.gameState
        }
        
        self.answerBank = other.answerBank
        self.numberOfRounds = other.numberOfRounds
        self.gameMode = other.gameMode
    }
    
    // MARK: - Private
    
    mutating func moveToNextRound(restartExistingRound: Bool = false) {
        if case .playing(let round, let answer, let currentDrawer) = gameState {
            answerBank.removeAll(where: { $0 == answer })
            
            if let newDrawer = players.randomElement(not: currentDrawer), let newAnswer = answerBank.randomElement() {
                prevAnswer = newAnswer
                let newRound = restartExistingRound ? round : round + 1
                let newGameState = GameState.playing(round: newRound, answer: newAnswer, drawer: newDrawer)
                gameState = .transition(prevAnswer: answer, nextState: newGameState)
                guesses.removeAll()
            }
        } else {
            print("GameManager: Trying to move to next round from gameState other than .playing ... gameState = \(gameState)")
        }
    }
    
    mutating private func updatePoints(for player: Player) {
        if let index = players.firstIndex(of: player) {
            players[index].points += pointsPerCorrectAnswer
        }
    }
            
    mutating private func updateExistingPlayers(using otherPlayers: [Player]) {
        players.indices.forEach { index in
            if let otherIndex = otherPlayers.firstIndex(of: players[index]) {
                players[index].points = otherPlayers[otherIndex].points
            }
        }
    }
    
    mutating private func updatePlayerRoles(currentDrawer drawer: Player) {
        players.indices.forEach { index in
            if players[index] != drawer {
                players[index].role = .guesser
            } else {
                players[index].role = .drawer
            }
        }
    }
    
    mutating private func playerDidGuessCorrectly(_ guess: Guess, _ round: Int) {
        updatePoints(for: guess.owner)
        //orderPlayers()
        correctGuesser = guess.owner.name
        if round < numberOfRounds {
            moveToNextRound()
        } else {
            endGame()
        }
    }
    
    mutating func timeEnds() {
        guard case .playing(let round, _, _) = gameState else {
            print("Timer ending from gameState other than .playing...")
            return
        }

        if round < numberOfRounds {
            moveToNextRound()
        } else {
            endGame()
        }
    }

    // MARK: - Debug
    
    private func showGuesses() {
        guesses.forEach { guess in
            print("Guess \(guess.value) made by \(guess.owner.name)")
        }
    }
    
    private func showGameState() {
        switch gameState {
        case .waitingToBegin:
            print("gameState: now waitingToBegin")
        case .playing(let round, let answer, let drawer):
            print("gameState: now playing(\(round), \(answer), \(drawer)")
        case .transition(_, let nextState):
            print("gameState: now transition(\(nextState)")
        case .gameOver:
            print("gameState: now gameOver")
        case .finished:
            print("gameState: now finished")
        case .freeDraw:
            print("gameState: now freeDraw")
        }
    }
}

