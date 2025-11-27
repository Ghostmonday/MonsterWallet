import SwiftUI
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Preload common sounds if needed, or load on demand
    }
    
    func playSound(named soundName: String?) {
        guard let soundName = soundName, !soundName.isEmpty else { return }
        
        // Check if we already have a player for this sound
        if let player = players[soundName] {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
            player.play()
            return
        }
        
        // Try to find the sound file in the bundle
        // We support .mp3, .wav, .m4a
        let extensions = ["mp3", "wav", "m4a", "caf"]
        var soundURL: URL?
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: soundName, withExtension: ext) {
                soundURL = url
                break
            }
        }
        
        guard let url = soundURL else {
            print("⚠️ SoundManager: Could not find sound file named '\(soundName)'")
            // Fallback to a system sound for feedback if custom sound is missing
            // SystemSoundID 1104 is a standard "Tock"
            AudioServicesPlaySystemSound(1104)
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            players[soundName] = player
        } catch {
            print("❌ SoundManager: Error playing sound '\(soundName)': \(error.localizedDescription)")
        }
    }
    
    func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
