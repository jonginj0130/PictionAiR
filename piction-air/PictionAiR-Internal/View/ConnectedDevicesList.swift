//
//  ConnectedDevicesList.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 11/5/23.
//

import SwiftUI
import MultipeerConnectivity

struct ConnectedDevicesList: View {
    @State private var connecting = false
    @Environment(\.colorScheme) var colorScheme
    @State private var connectingPlayer : MCPeerID?
    @State private var showPlayer = false
    enum ListItem {
        case players
        case availablePeers
        case connectedPeers
    }
    
    @EnvironmentObject var arPictionaryGame: ARPictionaryGame
    var listItem: ListItem = .availablePeers
    
    var count: Int {
        switch listItem {
        case .players:
            arPictionaryGame.players.count
        case .availablePeers:
            arPictionaryGame.availablePeers.count
        case .connectedPeers:
            arPictionaryGame.connectedPeers.count
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                if case .transition(_, _) = arPictionaryGame.currentState {
                    
                } else if case .gameOver(_) = arPictionaryGame.currentState{
                    
                } else {
                    HStack {
                        Text(listItem == .availablePeers ? "Available Devices" : "Connected Players")
                            .bold()
                            .font(.title2)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .bold()
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                            .foregroundStyle(colorScheme == .dark ? .yellow : .blue)
                    }
                }
                if listItem == .availablePeers {
                    meRow
                    availablePeers
                } else if listItem == .connectedPeers {
                    meRow
                    connectedPeers
                } else {
                    players
                }
                
                Spacer()
            }
        }
        .padding(8)
        .animation(.spring(), value: arPictionaryGame.availablePeers)
        .animation(.spring(), value: arPictionaryGame.connectedPeers)
        .animation(.spring(), value: arPictionaryGame.players)
    }
    
    var meRow: some View {
        playerRow("\(arPictionaryGame.displayName?.removeHostSuffix() ?? "???") (You)",
                  isHighlighted: true,
                  showsBackground: true) { EmptyView() }
    }
    
    var availablePeers: some View {
        ForEach(arPictionaryGame.availablePeers, id: \.self) { player in
            HStack {
                if arPictionaryGame.connectedPeers.contains(player) {
                    Button(action: {
                        arPictionaryGame.disconnectFromSession()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .onAppear {
                        connecting = false
                        connectingPlayer = nil
                    }
                    .disabled(arPictionaryGame.connectedPeers.isEmpty)
                    .tint(.red)
                }
                
                playerRow(player.displayName.removeHostSuffix(),
                          isHighlighted: arPictionaryGame.connectedPeers.contains(player),
                          showsBackground: false
                ) {
                    Group {
                        if player == connectingPlayer {
                            ProgressView()
                        } else if !arPictionaryGame.connectedPeers.contains(player) && !connecting {
                            Button("Connect") {
                                connecting = true
                                connectingPlayer = player
                                arPictionaryGame.requestToConnectWith(player)
                            }
                            .disabled(!arPictionaryGame.connectedPeers.isEmpty || connecting)
                        } else if arPictionaryGame.connectedPeers.contains(player) && !connecting {
                            Text("Connected")
                        } else {
                            Button("Connect") {
                                connecting = true
                                connectingPlayer = player
                                arPictionaryGame.requestToConnectWith(player)
                            }
                            .disabled(true)
                        }
                    }
                }
                .background(arPictionaryGame.connectedPeers.contains(player) ? Color.green.opacity(0.4) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
            }
        }
    }
    
    var connectedPeers: some View {
        ForEach(arPictionaryGame.connectedPeers, id: \.self) { player in
            playerRow(player.displayName.removeHostSuffix(), 
                      isHighlighted: false,
                      showsBackground: false
            ) {
                Text("Connected")
            }
            .background(Color.green.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
        }
    }
    
    var players: some View {
        ForEach(arPictionaryGame.sortedPlayers) { player in
            playerRow(player.name.removeHostSuffix(),
                      isHighlighted: player.name == arPictionaryGame.displayName,
                      showsBackground: player == arPictionaryGame.myPlayer && showPlayer)
            {
                Group {
                    if player.name == arPictionaryGame.displayName {
                        Text("\(player.points)")
                            .fontWeight(.heavy)
                            .foregroundStyle(colorScheme == .dark ? .yellow : .blue)
                    } else {
                        Text("\(player.points)")
                            .fontWeight(.medium)
                    }
                }
                .font(.system(size: 18))
                .contentTransition(.numericText())
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation() {
                    showPlayer = true
                }
            }
        }
    }
    
    func playerRow(_ name: String, isHighlighted: Bool, showsBackground: Bool, rightContent: () -> some View) -> some View {
        HStack {
            Text(name)
               .font(.system(size: 18))
            
            Spacer()
            
            rightContent()
        }
        .fontWeight(isHighlighted ? .heavy : .medium)
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .background(showsBackground ? Color.secondary.opacity(0.15) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}

#Preview {
    ConnectedDevicesList()
        .environmentObject(ARPictionaryGame())
}
