import SwiftUI
import AVFoundation

struct MainWindow: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @StateObject private var translationManager: TranslationManager
    @State private var showSettings = false
    @State private var selectedLanguage = "英语"
    @Environment(\.colorScheme) var colorScheme
    
    let languages = ["英语", "简体中文", "繁体中文", "日语", "韩语", "德语", "法语", "意大利语", "西班牙语", "葡萄牙语", "俄语", "拉丁语", "蒙古语", "藏文", "维吾尔语"]
    
    init() {
        let apiKey = UserDefaults.standard.string(forKey: "GoogleAPIKey") ?? ""
        let ttsApiKey = UserDefaults.standard.string(forKey: "GoogleTTSAPIKey") ?? ""
        _translationManager = StateObject(wrappedValue: TranslationManager(apiKey: apiKey, ttsApiKey: ttsApiKey, targetLanguage: "英语"))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                Spacer().frame(height: 0)
                
                TextEditor(text: .constant(clipboardManager.clipboardContent))
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(5)
                
                Button(action: {
                    translationManager.translate(clipboardManager.clipboardContent, to: selectedLanguage, force: true)
                }) {
                    if translationManager.isTranslating {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 36)
                            .background(translationManager.isTranslating ? Color.gray : Color.accentColor)
                    } else {
                        Text("翻译")
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 36)
                            .background(translationManager.isTranslating ? Color.gray : Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(translationManager.isTranslating)
                .controlSize(.large)
                .buttonStyle(.plain)
                
                TextEditor(text: .constant(translationManager.translatedText))
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(5)
                    .overlay(
                        Group {
                            if let error = translationManager.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding(4)
                                    .background(Color(nsColor: .textBackgroundColor).opacity(0.8))
                                    .cornerRadius(4)
                                    .padding(8)
                            }
                        },
                        alignment: .topLeading
                    )
                
                HStack {
                    Picker("目标语言", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) {
                            Text($0)
                        }
                    }
                    .frame(width: 150)
                    .onChange(of: selectedLanguage) { newValue in
                        translationManager.updateSettings(
                            apiKey: translationManager.getApiKey(),
                            ttsApiKey: UserDefaults.standard.string(forKey: "GoogleTTSAPIKey") ?? "",
                            targetLanguage: newValue
                        )
                        translationManager.translate(clipboardManager.clipboardContent, to: newValue)
                    }
                    
                    Button(action: speakTranslatedText) {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .disabled(translationManager.translatedText.isEmpty)
                    
                    Spacer()
                    
                    Button("设置") {
                        showSettings.toggle()
                    }
                    .frame(height: 18)
                    .controlSize(.large)
                }
                .padding(.top, 8)
                
                Spacer().frame(height: 8)
            }
            .frame(width: 400, height: 600)
            .padding(.horizontal, 8)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateTranslationSettings)) { _ in
            let apiKey = UserDefaults.standard.string(forKey: "GoogleAPIKey") ?? ""
            let ttsApiKey = UserDefaults.standard.string(forKey: "GoogleTTSAPIKey") ?? ""
            translationManager.updateSettings(apiKey: apiKey, ttsApiKey: ttsApiKey, targetLanguage: selectedLanguage)
        }
        .onAppear {
            checkAndTranslateClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkAndTranslateClipboard()
        }
    }
    
    private func speakTranslatedText() {
        translationManager.stopAudio()
        translationManager.speakTranslatedText()
    }
    
    private func checkAndTranslateClipboard() {
        if translationManager.isNewTranslation(clipboardManager.clipboardContent) {
            translationManager.translate(clipboardManager.clipboardContent, to: selectedLanguage)
        }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
