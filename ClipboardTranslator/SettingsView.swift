import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "GoogleAPIKey") ?? ""
    @State private var ttsApiKey: String = UserDefaults.standard.string(forKey: "GoogleTTSAPIKey") ?? ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("google_ai_api_settings", comment: "Google AI API settings section header"))) {
                TextField(NSLocalizedString("google_ai_api_key", comment: "Google AI API key label"), text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section(header: Text(NSLocalizedString("google_tts_api_settings", comment: "Google TTS API settings section header"))) {
                TextField(NSLocalizedString("google_tts_api_key", comment: "Google TTS API key label"), text: $ttsApiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Button(NSLocalizedString("save_button", comment: "Save button text")) {
                    saveSettings()
                }
                .foregroundColor(.blue)
                .controlSize(.large)
                
                Button(NSLocalizedString("cancel_button", comment: "Cancel button text")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                .controlSize(.large)
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("alert_title", comment: "Alert title")),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("ok_button", comment: "OK button text"))) {
                    if alertMessage == NSLocalizedString("settings_saved", comment: "Settings saved message") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func saveSettings() {
        if !apiKey.isEmpty && !ttsApiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: "GoogleAPIKey")
            UserDefaults.standard.set(ttsApiKey, forKey: "GoogleTTSAPIKey")
            alertMessage = NSLocalizedString("settings_saved", comment: "Settings saved message")
            showAlert = true
            
            NotificationCenter.default.post(name: .updateTranslationSettings, object: nil)
        } else {
            alertMessage = NSLocalizedString("api_key_empty", comment: "API key empty error message")
            showAlert = true
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
