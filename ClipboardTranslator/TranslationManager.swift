import Foundation
import Combine
import AVFoundation

class TranslationManager: ObservableObject {
    @Published var translatedText: String = ""
    @Published var isTranslating: Bool = false
    @Published var error: String?
    
    private var apiKey: String
    private var ttsApiKey: String
    private var targetLanguage: String
    private var cancellables = Set<AnyCancellable>()
    private var lastTranslatedText: String = ""
    private var lastSpokenText: String = ""
    private var audioPlayer: AVAudioPlayer?
    
    init(apiKey: String, ttsApiKey: String, targetLanguage: String) {
        self.apiKey = apiKey
        self.ttsApiKey = ttsApiKey
        self.targetLanguage = targetLanguage
    }
    
    func getApiKey() -> String {
        return apiKey
    }
    
    func updateSettings(apiKey: String, ttsApiKey: String, targetLanguage: String) {
        self.apiKey = apiKey
        self.ttsApiKey = ttsApiKey
        self.targetLanguage = targetLanguage
    }
    
    func translate(_ text: String, to language: String, force: Bool = false) {
        guard !text.isEmpty else {
            self.error = NSLocalizedString("enter_text_to_translate", comment: "Enter text to translate message")
            return
        }
        
        if !force && text == lastTranslatedText && language == targetLanguage {
            return // 如果文本没有变化且目标语言相同，则不重新翻译
        }
        
        isTranslating = true
        error = nil
        
        let languageCode = getLanguageCode(for: language)
        print("Translating to language: \(language), code: \(languageCode)")
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)")!
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Translate the following text to \(languageCode):\n\n\(text)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topP": 1,
                "topK": 1,
                "maxOutputTokens": 2048
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GeminiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isTranslating = false
                if case .failure(let error) = completion {
                    self?.error = NSLocalizedString("translation_failed", comment: "Translation failed message") + ": \(error.localizedDescription)"
                    print("Translation error: \(error)")
                }
            } receiveValue: { [weak self] response in
                self?.translatedText = response.candidates.first?.content.parts.first?.text ?? NSLocalizedString("translation_failed", comment: "Translation failed message")
                self?.lastTranslatedText = text
                self?.targetLanguage = language
                print("Translation successful. Response: \(response)")
            }
            .store(in: &cancellables)
    }
    
    func speakTranslatedText() {
        guard !translatedText.isEmpty else { return }
        
        if translatedText == lastSpokenText {
            // 如果文本没有变化，直接播放缓存的音频
            playAudio()
            return
        }
        
        let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(ttsApiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "input": ["text": translatedText],
            "voice": ["languageCode": getLanguageCode(for: targetLanguage)],
            "audioConfig": ["audioEncoding": "MP3"]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: TTSResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = NSLocalizedString("speech_synthesis_failed", comment: "Speech synthesis failed message") + ": \(error.localizedDescription)"
                    print("TTS error: \(error)")
                }
            } receiveValue: { [weak self] response in
                if let audioData = Data(base64Encoded: response.audioContent) {
                    self?.playAudio(data: audioData)
                    self?.lastSpokenText = self?.translatedText ?? ""
                    print("TTS successful")
                }
            }
            .store(in: &cancellables)
    }
    
    private func playAudio(data: Data? = nil) {
        stopAudio()
        
        if let data = data {
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.play()
            } catch {
                self.error = NSLocalizedString("audio_playback_failed", comment: "Audio playback failed message") + ": \(error.localizedDescription)"
                print("Audio playback error: \(error)")
            }
        } else if let player = audioPlayer {
            player.play()
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
    
    func isNewTranslation(_ text: String) -> Bool {
        return text != lastTranslatedText
    }
    
    private func getLanguageCode(for language: String) -> String {
        switch language.lowercased() {
        case NSLocalizedString("English", comment: "English language name").lowercased(): return "en-US"
        case NSLocalizedString("Simplified_Chinese", comment: "Simplified Chinese language name").lowercased(): return "zh-CN"
        case NSLocalizedString("Traditional_Chinese", comment: "Traditional Chinese language name").lowercased(): return "zh-TW"
        case NSLocalizedString("Japanese", comment: "Japanese language name").lowercased(): return "ja-JP"
        case NSLocalizedString("Korean", comment: "Korean language name").lowercased(): return "ko-KR"
        case NSLocalizedString("German", comment: "German language name").lowercased(): return "de-DE"
        case NSLocalizedString("French", comment: "French language name").lowercased(): return "fr-FR"
        case NSLocalizedString("Italian", comment: "Italian language name").lowercased(): return "it-IT"
        case NSLocalizedString("Spanish", comment: "Spanish language name").lowercased(): return "es-ES"
        case NSLocalizedString("Portuguese", comment: "Portuguese language name").lowercased(): return "pt-PT"
        case NSLocalizedString("Russian", comment: "Russian language name").lowercased(): return "ru-RU"
        case NSLocalizedString("Latin", comment: "Latin language name").lowercased(): return "la"
        case NSLocalizedString("Mongolian", comment: "Mongolian language name").lowercased(): return "mn-MN"
        case NSLocalizedString("Tibetan", comment: "Tibetan language name").lowercased(): return "bo-CN"
        case NSLocalizedString("Uyghur", comment: "Uyghur language name").lowercased(): return "ug-CN"
        default:
            print("Unknown language: \(language), defaulting to en-US")
            return "en-US"
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct TTSResponse: Codable {
    let audioContent: String
}
