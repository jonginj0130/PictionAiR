//
//  MultiplayerSession.swift
//  PictionAiR
//
//  Created by Rahul Narayanan on 10/17/23.
//

import MultipeerConnectivity

protocol MultiplayerGameSessionDelegate {
    func didReceiveData(_ data: Data, from id: MCPeerID) -> Void
    func peerDidChangeState(_ peer: MCPeerID, to newState: MCSessionState) -> Void
    func didFindPeer(_ peer: MCPeerID) -> Void
    func didLosePeer(_ peer: MCPeerID) -> Void
}

class MultipeerSession: NSObject, ObservableObject {
    static let hostSuffix = "#host"
    
    private static let serviceType = "pictionair"
    
    private let myPeerID: MCPeerID!
    private(set) var session: MCSession!
    private(set) var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private(set) var serviceBrowser: MCNearbyServiceBrowser!
    private let isHost: Bool
    
    var gameDelegate: MultiplayerGameSessionDelegate?
    
    /// - Tag: MultipeerSetup
    init(displayName: String, isHost: Bool = false, receivedDataHandler: @escaping (Data, MCPeerID) -> Void = { _, _ in }) {
        self.myPeerID = MCPeerID(displayName: displayName + (isHost ? MultipeerSession.hostSuffix : ""))
        self.isHost = isHost
        super.init()
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
                    
        if isHost {
            beginAdvertising()
        } else {
            beginBrowsing()
        }
        
        
    }
    
    func endSession() {
        session.disconnect()
        if isHost {
            serviceAdvertiser.stopAdvertisingPeer()
        } else {
            serviceBrowser.stopBrowsingForPeers()
        }
    }
    
    func beginAdvertising() {
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    func beginBrowsing() {
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
    
    func sendToAllPeers(_ data: Data, reliably: Bool) {
        sendToPeers(data, reliably: reliably, peers: session.connectedPeers)
    }
    
    /// - Tag: SendToPeers
    func sendToPeers(_ data: Data, reliably: Bool, peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        do {
            try session.send(data, toPeers: peers, with: reliably ? .reliable : .unreliable)
        } catch {
            print("error sending data to peers \(peers): \(error.localizedDescription)")
        }
    }
}

extension MultipeerSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { self.gameDelegate?.peerDidChangeState(peerID, to: state) }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.gameDelegate?.didReceiveData(data, from: peerID) }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }

}

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    
    /// - Tag: FoundPeer
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { self.gameDelegate?.didFindPeer(peerID) }
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.gameDelegate?.didLosePeer(peerID) }
    }
    
}

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    
    /// - Tag: AcceptInvite
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Call the handler to accept the peer's invitation to join.
        invitationHandler(true, self.session)
    }
}

