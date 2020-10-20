//
//  ViewController.swift
//  JitsiSample
//
//  Created by Phaninder Kumar on 20/10/20.
//

import UIKit
import JitsiMeet
import AVFoundation
import CallKit

class ViewController: UIViewController {

    @IBOutlet weak var reportIncomingCallButton: UIButton!
    @IBOutlet weak var initiateOutgoingCallButton: UIButton!
    
    fileprivate var jitsiMeetView: JitsiMeetView?
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    var localCallUUID: UUID?
    @IBOutlet weak var callButtonsStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        JMCallKitProxy.configureProvider(localizedName: "Jitsi Sample",
                                         ringtoneSound: nil,
                                         iconTemplateImageData: nil)
    }

    @IBAction func reportIncomingCallButtonTapped(_ sender: UIButton) {
        localCallUUID = UUID()
        print("Incoming Call UUID: \(localCallUUID!.uuidString)")
        JMCallKitProxy.reportNewIncomingCall(UUID: localCallUUID!,
                                             handle: "Jitsi Meet",
                                             displayName: "Jitsi Meet",
                                             hasVideo: true) { (error) in
            guard error == nil else {
                print("Failed, error: \(String(describing: error))")
                self.callButtonsStackView.isHidden = false
                return
            }
            print("Successfully reported")
            self.callButtonsStackView.isHidden = true
        }
        JMCallKitProxy.addListener(self)
    }
    
    @IBAction func initiateOutgoingCallButtonTapped(_ sender: UIButton) {
        callButtonsStackView.isHidden = true
        localCallUUID = UUID()
        print("Outgoing Call UUID: \(localCallUUID!.uuidString)")
        joinMeet(callID: localCallUUID!)
    }
    
    func joinMeet(callID: UUID) {
        cleanUp()

        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        guard let serverURL = URL(string: "https://meet.jit.si") else { return  }
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.serverURL = serverURL
            builder.audioOnly = false
            builder.audioMuted = true
            builder.videoMuted = true
            builder.setFeatureFlag("chat.enabled", withBoolean: false)
            builder.setFeatureFlag("meeting-password.enabled", withBoolean: false)
            builder.setFeatureFlag("add-people.enabled", withBoolean: false)
            builder.setFeatureFlag("call-integration.enabled", withBoolean: true)
            builder.setFeatureFlag("invite.enabled", withBoolean: false)
            builder.room = callID.uuidString
            builder.subject = callID.uuidString
        }
        
        jitsiMeetView.join(options)
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: self.view)
        pipViewCoordinator?.initialPositionInSuperview = .upperRightCorner
        jitsiMeetView.alpha = 1
        pipViewCoordinator?.show()
    }
    
    func endCallManually() {
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.serverURL = nil
        }
        jitsiMeetView?.join(options)
        self.callButtonsStackView.isHidden = false
        localCallUUID = nil
        cleanUp()
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
    }
    
}

extension ViewController: JitsiMeetViewDelegate {
    
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.callButtonsStackView.isHidden = false
            self.pipViewCoordinator?.hide() { _ in
                self.cleanUp()
                self.localCallUUID = nil
            }
        }
    }
    
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        let isAvailable = JMCallKitProxy.hasActiveCallForUUID(localCallUUID!.uuidString)
        print("IsCall Available: \(isAvailable)")
    }

    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }

}


extension ViewController: JMCallKitListener {

    func providerDidReset() {
        print("providerDidReset")
    }

    func performAnswerCall(UUID: UUID) {
        print("performAnswerCall: \(UUID.uuidString)")
        self.callButtonsStackView.isHidden = true
        joinMeet(callID: UUID)
    }

    func performEndCall(UUID: UUID) {
        print("performEndCall: \(UUID.uuidString)")
        endCallManually()
    }

    func performSetMutedCall(UUID: UUID, isMuted: Bool) {
        print("performSetMutedCall: \(UUID.uuidString), muted \(isMuted)")
    }

    func performStartCall(UUID: UUID, isVideo: Bool) {
        print("performStartCall: \(UUID.uuidString), isVideo \(isVideo)")
    }

    func providerDidActivateAudioSession(session: AVAudioSession) {
        print("providerDidActivateAudioSession")
    }

    func providerDidDeactivateAudioSession(session: AVAudioSession) {
        print("providerDidDeactivateAudioSession")
    }

    func providerTimedOutPerformingAction(action: CXAction) {
        print("providerTimedOutPerformingAction: \(action)")
    }

}
