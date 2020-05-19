//
//  ViewController.swift
//  VideoChat
//
//  Created by admin on 04/04/2020.
//  Copyright © 2020 DenysPashkov. All rights reserved.
//

import UIKit
import AgoraRtcKit

class ViewController: UIViewController {
	
//	MARK: Room Name
	
	@IBOutlet weak var roomName: UILabel!
	
//	MARK: Random Room
	
	@IBAction func exitAndRandom(_ sender: Any) {
		agoraKit!.leaveChannel { (_) in }
		
		let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

		let nextViewController = storyBoard.instantiateViewController(withIdentifier: "nextView") as! ViewController
		self.present(nextViewController, animated:false, completion:nil)
	}
	
//	MARK: Background checking
	
	let chennelsName = [ "Room 1", "Room 5"]
	var currentRoom = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		currentRoom = chennelsName[Int.random(in: 0...chennelsName.count-1)]
		
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
	}
	

	@objc func appMovedToBackground() {
		getAgoraEngine().leaveChannel { (_) in
		}
		performSegue(withIdentifier: "Disconnect", sender: nil)
	}
	
//	MARK: Exit and disconnect
	
	@IBAction func disconnectButton(_ sender: Any) {
		getAgoraEngine().leaveChannel { (_) in
		}
		performSegue(withIdentifier: "Disconnect", sender: sender)
	}
	
//	MARK: Switch camera
	
	@IBAction func switchCamera(_ sender: Any) {
		getAgoraEngine().switchCamera()
	}
	
//	MARK: Camera Hide
	
	@IBOutlet weak var hideCamera: UIButton!
	var camera = false{
		didSet{
			if !camera {
				hideCamera.setImage(UIImage(named: "ActivedVideo"), for: .normal)
			} else {
				hideCamera.setImage(UIImage(named: "ClosedCamera"), for: .normal)
			}
		}
	}
	@IBAction func didTogleCamera(_ sender: Any) {
		if camera{
			getAgoraEngine().muteLocalVideoStream(false)
		} else {
			getAgoraEngine().muteLocalVideoStream(true)
		}
		camera = !camera
	}
	
//	MARK: Microphone Mute
	@IBOutlet weak var muteButton: UIButton!
	var mute = false {
		didSet{
			if mute {
				muteButton.setImage(UIImage(named: "Mute"), for: .normal)
			} else {
				muteButton.setImage(UIImage(named: "MicrophoneActive"), for: .normal)
			}
		}
	}
	
	@IBAction func didTogleMute(_ sender: Any) {
		if mute{
			getAgoraEngine().muteLocalAudioStream(false)
		} else {
			getAgoraEngine().muteLocalAudioStream(true)
		}
		mute = !mute
	}
	
//	MARK: Programming Part
/// Some Setup for go ahed
	
	var temp = CGPoint()
	var channelName = "default"
	var agoraKit: AgoraRtcEngineKit?
	let tempToken: String? = nil
	var userID: UInt = 0
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	var remoteUserIDs: [UInt] = [0]
	
	private func getAgoraEngine() -> AgoraRtcEngineKit {
		if agoraKit == nil {
			
			agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "a191fc940fdc4ca2af9af14552e2d3fb", delegate: self)
			
		}
		return agoraKit!
	}
	
//	MARK: Setup your video
///	It is called in collection view Extension
	
	func setUpVideo(videoCell : VideoCollectionViewCell) {
		
		getAgoraEngine().enableVideo()

		let videoCanvas = AgoraRtcVideoCanvas()
		videoCanvas.uid = userID
		videoCanvas.view = videoCell.videoView
		videoCanvas.renderMode = .hidden
		getAgoraEngine().setupLocalVideo(videoCanvas)
			
		joinChannel()
	}
	
//	MARK: Enter channel
///	Called in setUpVideo

	func joinChannel() {
		roomName.text = currentRoom
		getAgoraEngine().joinChannel(byToken: tempToken, channelId: currentRoom, info: nil, uid: userID) { [weak self] (sid, uid, elapsed) in
			
			self?.userID = uid
		}
	
	}
	
}

//MARK: Agora Manager

extension ViewController : AgoraRtcEngineDelegate {
	func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        remoteUserIDs.append(uid)
        collectionView.reloadData()
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if let index = remoteUserIDs.firstIndex(where: { $0 == uid }) {
            remoteUserIDs.remove(at: index)
            collectionView.reloadData()
        }
    }
}

//MARK: CollectionViewManager

extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return remoteUserIDs.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
		
		switch remoteUserIDs.count {
			case 1:
				cell.frame.size.width = collectionView.frame.size.width - 20
				cell.frame.size.height = (collectionView.frame.size.height - 10)
			case 2:
				cell.frame.size.width = collectionView.frame.size.width - 20
				cell.frame.size.height = (collectionView.frame.size.height - 10) / 2
				
				if indexPath.row == 1 {
					temp = cell.frame.origin
					cell.frame.origin = CGPoint(x: 10, y: 297)
			}
				
			default:
				cell.frame.size.width = (collectionView.frame.size.width - 30) / 2
				cell.frame.size.height = (collectionView.frame.size.height - 10) / 2
			if indexPath.row == 1 {
					cell.frame.origin = temp
			}
		}
		
		let remoteID = remoteUserIDs[indexPath.row]
		
		if let videoCell = cell as? VideoCollectionViewCell {
			
			if remoteID == 0 {
				setUpVideo(videoCell: videoCell)
				return cell
			}
			
			let videoCanvas = AgoraRtcVideoCanvas()
			videoCanvas.uid = remoteID
			
			videoCanvas.view = videoCell.videoView
			videoCanvas.view?.frame.size = cell.frame.size
			videoCanvas.renderMode = .hidden
			getAgoraEngine().setupRemoteVideo(videoCanvas)
		}
		return cell
	}
}
