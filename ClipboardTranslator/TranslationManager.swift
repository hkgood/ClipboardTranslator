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
            self.error = "请输入要翻译的文本"
            return
        }
        
        if !force && text == lastTranslatedText && language == targetLanguage {
            return // 如果文本没有变化且目标语言相同，则不重新翻译
        }
        
        isTranslating = true
        error = nil
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=\(apiKey)")!
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "将以下文本翻译成\(language)，无论原文是什么语言：\n\n\(text)"]
                    ]
                ]
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
                    self?.error = "翻译失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] response in
                self?.translatedText = response.candidates.first?.content.parts.first?.text ?? "翻译失败"
                self?.lastTranslatedText = text
                self?.targetLanguage = language
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
                    self?.error = "语音合成失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] response in
                if let audioData = Data(base64Encoded: response.audioContent) {
                    self?.playAudio(data: audioData)
                    self?.lastSpokenText = self?.translatedText ?? ""
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
                self.error = "音频播放失败: \(error.localizedDescription)"
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
        switch language {
        case "英语": return "en-US"
        case "简体中文": return "zh-CN"
        case "繁体中文": return "zh-TW"
        case "日语": return "ja-JP"
        case "韩语": return "ko-KR"
        case "德语": return "de-DE"
        case "法语": return "fr-FR"
        case "意大利语": return "it-IT"
        case "西班牙语": return "es-ES"
        case "葡萄牙语": return "pt-PT"
        case "俄语": return "ru-RU"
        case "拉丁语": return "la"
        case "蒙古语": return "mn-MN"
        case "藏文": return "bo-CN"
        case "维吾尔语": return "ug-CN"
        default: return "en-US"
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
