import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "GoogleAPIKey") ?? ""
    @State private var ttsApiKey: String = UserDefaults.standard.string(forKey: "GoogleTTSAPIKey") ?? ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Google AI API 设置")) {
                TextField("Google AI API 密钥", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section(header: Text("Google Text-to-Speech API 设置")) {
                TextField("Google TTS API 密钥", text: $ttsApiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Button("保存") {
                    saveSettings()
                }
                .foregroundColor(.blue)
                .controlSize(.large)
                
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                .controlSize(.large)
            }
        }
        .padding(20)
        .frame(width: 400, height: 200)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")) {
                if alertMessage == "设置已保存" {
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
    
    private func saveSettings() {
        if !apiKey.isEmpty && !ttsApiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: "GoogleAPIKey")
            UserDefaults.standard.set(ttsApiKey, forKey: "GoogleTTSAPIKey")
            alertMessage = "设置已保存"
            showAlert = true
            
            NotificationCenter.default.post(name: .updateTranslationSettings, object: nil)
        } else {
            alertMessage = "API Key 不能为空"
            showAlert = true
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
