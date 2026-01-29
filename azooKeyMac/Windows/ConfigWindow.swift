import Cocoa
import Core
import SwiftUI

struct ConfigWindow: View {
    @ConfigState private var liveConversion = Config.LiveConversion()
    @ConfigState private var inputStyle = Config.InputStyle()
    @ConfigState private var typeBackSlash = Config.TypeBackSlash()
    @ConfigState private var punctuationStyle = Config.PunctuationStyle()
    @ConfigState private var typeHalfSpace = Config.TypeHalfSpace()
    @ConfigState private var zenzaiProfile = Config.ZenzaiProfile()
    @ConfigState private var zenzaiPersonalizationLevel = Config.ZenzaiPersonalizationLevel()
    @ConfigState private var openAiApiKey = Config.OpenAiApiKey()
    @ConfigState private var openAiModelName = Config.OpenAiModelName()
    @ConfigState private var openAiApiEndpoint = Config.OpenAiApiEndpoint()
    @ConfigState private var learning = Config.Learning()
    @ConfigState private var inferenceLimit = Config.ZenzaiInferenceLimit()
    @ConfigState private var debugWindow = Config.DebugWindow()
    @ConfigState private var debugPredictiveTyping = Config.DebugPredictiveTyping()
    @ConfigState private var userDictionary = Config.UserDictionary()
    @ConfigState private var systemUserDictionary = Config.SystemUserDictionary()
    @ConfigState private var keyboardLayout = Config.KeyboardLayout()
    @ConfigState private var aiBackend = Config.AIBackendPreference()
    @ConfigState private var enablePinyinLookup = Config.EnablePinyinLookup()

    @State private var selectedTab: Tab = .basic
    @State private var zenzaiProfileHelpPopover = false
    @State private var zenzaiInferenceLimitHelpPopover = false
    @State private var openAiApiKeyPopover = false
    @State private var connectionTestInProgress = false
    @State private var showingRomajiTableEditor = false
    @State private var connectionTestResult: String?
    @State private var systemUserDictionaryUpdateMessage: SystemUserDictionaryUpdateMessage?
    @State private var showingLearningResetConfirmation = false
    @State private var learningResetMessage: LearningResetMessage?
    @State private var foundationModelsAvailability: FoundationModelsAvailability?
    @State private var availabilityCheckDone = false

    private enum Tab: CaseIterable, Hashable {
        case basic
        case customize
        case advanced

        var title: String {
            switch self {
            case .basic: return NSLocalizedString("tab.basic", comment: "Basic tab")
            case .customize: return NSLocalizedString("tab.customize", comment: "Customize tab")
            case .advanced: return NSLocalizedString("tab.advanced", comment: "Advanced tab")
            }
        }

        var icon: String {
            switch self {
            case .basic: return "star"
            case .customize: return "slider.horizontal.3"
            case .advanced: return "gearshape.2"
            }
        }
    }

    private enum LearningResetMessage {
        case success
        case error(String)
    }

    private enum SystemUserDictionaryUpdateMessage {
        case error(any Error)
        case successfulUpdate
    }

    private func getErrorMessage(for error: OpenAIError) -> String {
        switch error {
        case .invalidURL:
            return NSLocalizedString("error.invalidURL", comment: "Invalid URL error")
        case .noServerResponse:
            return NSLocalizedString("error.noResponse", comment: "No server response error")
        case .invalidResponseStatus(let code, let body):
            return getHTTPErrorMessage(code: code, body: body)
        case .parseError(let message):
            return String(format: NSLocalizedString("error.parseFailed", comment: "Parse error"), message)
        case .invalidResponseStructure:
            return NSLocalizedString("error.unexpectedFormat", comment: "Unexpected format error")
        }
    }

    private func getHTTPErrorMessage(code: Int, body: String) -> String {
        switch code {
        case 401:
            return NSLocalizedString("error.invalidAPIKey", comment: "Invalid API key error")
        case 403:
            return NSLocalizedString("error.accessDenied", comment: "Access denied error")
        case 404:
            return NSLocalizedString("error.endpointNotFound", comment: "Endpoint not found error")
        case 429:
            return NSLocalizedString("error.rateLimit", comment: "Rate limit error")
        case 500...599:
            return String(format: NSLocalizedString("error.serverError", comment: "Server error"), code)
        default:
            return String(format: NSLocalizedString("error.httpStatus", comment: "HTTP status error"), code, String(body.prefix(100)))
        }
    }

    func testConnection() async {
        connectionTestInProgress = true
        connectionTestResult = nil

        do {
            let testRequest = OpenAIRequest(
                prompt: "テスト",
                target: "",
                modelName: openAiModelName.value.isEmpty ? Config.OpenAiModelName.default : openAiModelName.value
            )
            _ = try await OpenAIClient.sendRequest(
                testRequest,
                apiKey: openAiApiKey.value,
                apiEndpoint: openAiApiEndpoint.value
            )

            connectionTestResult = NSLocalizedString("settings.connectionSuccess", comment: "Connection test success")
        } catch let error as OpenAIError {
            connectionTestResult = getErrorMessage(for: error)
        } catch {
            connectionTestResult = "\(NSLocalizedString("error.prefix", comment: "Error prefix")): \(error.localizedDescription)"
        }

        connectionTestInProgress = false
    }

    @MainActor
    private func resetLearningData() {
        guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
            learningResetMessage = .error(NSLocalizedString("error.learningResetFailed", comment: "Learning reset failed"))
            Task {
                try? await Task.sleep(for: .seconds(30))
                if case .error = learningResetMessage {
                    learningResetMessage = nil
                }
            }
            return
        }

        appDelegate.kanaKanjiConverter.resetMemory()
        learningResetMessage = .success

        // 10秒後にメッセージを消す
        Task {
            try? await Task.sleep(for: .seconds(10))
            if case .success = learningResetMessage {
                learningResetMessage = nil
            }
        }
    }

    @ViewBuilder
    private func helpButton(helpContent: LocalizedStringKey, isPresented: Binding<Bool>) -> some View {
        if #available(macOS 14, *) {
            Button("common.help", systemImage: "questionmark") {
                isPresented.wrappedValue = true
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .popover(isPresented: isPresented) {
                Text(helpContent).padding()
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // カスタムタブバー
            HStack(spacing: 4) {
                ForEach([Tab.basic, Tab.customize, Tab.advanced], id: \.self) { tab in
                    Button(
                        action: {
                            selectedTab = tab
                        },
                        label: {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? Color(nsColor: .controlAccentColor) : Color(nsColor: .secondaryLabelColor))
                                Text(tab.title)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .medium : .regular))
                                    .foregroundColor(selectedTab == tab ? Color(nsColor: .labelColor) : Color(nsColor: .secondaryLabelColor))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTab == tab ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        selectedTab == tab ? Color(nsColor: .separatorColor).opacity(0.5) : Color.clear,
                                        lineWidth: 0.5
                                    )
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                    )
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .unemphasizedSelectedContentBackgroundColor).opacity(0.3))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // コンテンツエリア（選択されたタブのみ表示）
            Group {
                if selectedTab == .basic {
                    basicTabView
                } else if selectedTab == .customize {
                    customizeTabView
                } else {
                    advancedTabView
                }
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingRomajiTableEditor) {
            RomajiTableEditorWindow(base: CustomInputTableStore.loadTable()) { exported in
                do {
                    _ = try CustomInputTableStore.save(exported: exported)
                    CustomInputTableStore.registerIfExists()
                } catch {
                    print("Failed to save custom input table: \(error)")
                }
            }
        }
    }

    // MARK: - Basic Tab
    @ViewBuilder
    private var basicTabView: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Picker("settings.smartConversion", selection: $aiBackend) {
                        Text("settings.smartConversion.off").tag(Config.AIBackendPreference.Value.off)

                        if let availability = foundationModelsAvailability, availability.isAvailable {
                            Text("Foundation Models").tag(Config.AIBackendPreference.Value.foundationModels)
                        }

                        Text("OpenAI API").tag(Config.AIBackendPreference.Value.openAI)
                    }
                    .onAppear {
                        if !availabilityCheckDone {
                            foundationModelsAvailability = FoundationModelsClientCompat.checkAvailability()
                            availabilityCheckDone = true

                            let hasSetAIBackend = UserDefaults.standard.bool(forKey: "hasSetAIBackendManually")
                            if !hasSetAIBackend,
                               aiBackend.value == .off,
                               let availability = foundationModelsAvailability,
                               availability.isAvailable {
                                aiBackend.value = .foundationModels
                                UserDefaults.standard.set(true, forKey: "hasSetAIBackendManually")
                            }

                            if aiBackend.value == .foundationModels,
                               let availability = foundationModelsAvailability,
                               !availability.isAvailable {
                                aiBackend.value = .off
                            }
                        }
                    }
                    .onChange(of: aiBackend.value) { _ in
                        UserDefaults.standard.set(true, forKey: "hasSetAIBackendManually")
                    }
                }

                if aiBackend.value == .openAI {
                    HStack {
                        SecureField("settings.apiKey", text: $openAiApiKey, prompt: Text("settings.apiKey.placeholder"))
                        helpButton(
                            helpContent: "settings.apiKey.help",
                            isPresented: $openAiApiKeyPopover
                        )
                    }
                    TextField("settings.modelName", text: $openAiModelName, prompt: Text("settings.modelName.placeholder"))
                    TextField("settings.endpoint", text: $openAiApiEndpoint, prompt: Text("settings.endpoint.placeholder"))
                        .help(NSLocalizedString("settings.endpoint.help", comment: "Endpoint help"))

                    HStack {
                        Button("settings.connectionTest") {
                            Task {
                                await testConnection()
                            }
                        }
                        .disabled(connectionTestInProgress || openAiApiKey.value.isEmpty)

                        if connectionTestInProgress {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if let result = connectionTestResult {
                        Text(result)
                            .foregroundColor(result.contains(NSLocalizedString("settings.connectionSuccess", comment: "")) ? .green : .red)
                            .font(.caption)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } header: {
                Label("settings.smartConversion", systemImage: "sparkles")
            }

            Section {
                LabeledContent {
                    HStack {
                        Text(String(format: NSLocalizedString("settings.userDictionary.items", comment: "Items count"), self.userDictionary.value.items.count))
                        Button("settings.edit") {
                            (NSApplication.shared.delegate as? AppDelegate)!.openUserDictionaryEditorWindow()
                        }
                    }
                } label: {
                    Text("settings.userDictionary.xiaoli")
                }
                LabeledContent {
                    HStack {
                        switch self.systemUserDictionaryUpdateMessage {
                        case .none:
                            if let updated = self.systemUserDictionary.value.lastUpdate {
                                let date = updated.formatted(date: .omitted, time: .omitted)
                                Text(String(format: NSLocalizedString("settings.userDictionary.lastUpdate", comment: "Last update"), date, self.systemUserDictionary.value.items.count))
                            } else {
                                Text("settings.userDictionary.notSet")
                            }
                        case .error(let error):
                            Text(String(format: NSLocalizedString("settings.userDictionary.loadError", comment: "Load error"), error.localizedDescription))
                        case .successfulUpdate:
                            Text(String(format: NSLocalizedString("settings.userDictionary.loadSuccess", comment: "Load success"), self.systemUserDictionary.value.items.count))
                        }
                        Button("settings.load") {
                            do {
                                let systemUserDictionaryEntries = try SystemUserDictionaryHelper.fetchEntries()
                                self.systemUserDictionary.value.items = systemUserDictionaryEntries.map {
                                    .init(word: $0.phrase, reading: $0.shortcut)
                                }
                                self.systemUserDictionary.value.lastUpdate = .now
                                self.systemUserDictionaryUpdateMessage = .successfulUpdate
                            } catch {
                                self.systemUserDictionaryUpdateMessage = .error(error)
                            }
                        }
                        Button("settings.reset") {
                            self.systemUserDictionary.value.lastUpdate = nil
                            self.systemUserDictionary.value.items = []
                            self.systemUserDictionaryUpdateMessage = nil
                        }
                    }
                } label: {
                    Text("settings.userDictionary.system")
                }
            } header: {
                Label("settings.userDictionary", systemImage: "book.closed")
            }

            Section {
                Toggle("settings.liveConversion.enable", isOn: $liveConversion)
                HStack {
                    TextField("settings.conversionProfile", text: $zenzaiProfile, prompt: Text("settings.conversionProfile.placeholder"))
                    helpButton(
                        helpContent: "settings.conversionProfile.help",
                        isPresented: $zenzaiProfileHelpPopover
                    )
                }
            } header: {
                Label("settings.conversion", systemImage: "brain")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Customize Tab
    @ViewBuilder
    private var customizeTabView: some View {
        Form {
            Section {
                Toggle("settings.backslash", isOn: $typeBackSlash)
                Toggle("settings.halfWidthSpace", isOn: $typeHalfSpace)
                Picker("settings.punctuation", selection: $punctuationStyle) {
                    Text("settings.punctuation.kutenToten").tag(Config.PunctuationStyle.Value.`kutenAndToten`)
                    Text("settings.punctuation.periodToten").tag(Config.PunctuationStyle.Value.periodAndToten)
                    Text("settings.punctuation.kutenComma").tag(Config.PunctuationStyle.Value.kutenAndComma)
                    Text("settings.punctuation.periodComma").tag(Config.PunctuationStyle.Value.periodAndComma)
                }
            } header: {
                Label("settings.inputOptions", systemImage: "character.cursor.ibeam")
            }

            Section {
                Picker("settings.learning.history", selection: $learning) {
                    Text("settings.learning.inputAndOutput").tag(Config.Learning.Value.inputAndOutput)
                    Text("settings.learning.onlyOutput").tag(Config.Learning.Value.onlyOutput)
                    Text("settings.learning.nothing").tag(Config.Learning.Value.nothing)
                }
                LabeledContent {
                    HStack {
                        switch learningResetMessage {
                        case .none:
                            EmptyView()
                        case .success:
                            Text("settings.learning.resetSuccess")
                                .foregroundColor(.green)
                        case .error(let message):
                            Text("\(NSLocalizedString("error.prefix", comment: "")): \(message)")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Button("settings.reset") {
                            showingLearningResetConfirmation = true
                        }
                        .confirmationDialog(
                            "settings.learning.resetConfirm",
                            isPresented: $showingLearningResetConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("settings.reset", role: .destructive) {
                                resetLearningData()
                            }
                            Button("settings.cancel", role: .cancel) {}
                        }
                    }
                } label: {
                    Text("settings.learning.data")
                }
            } header: {
                Label("settings.learning", systemImage: "memorychip")
            }

            Section {
                Picker("settings.inputStyle", selection: $inputStyle) {
                    Text("settings.inputStyle.default").tag(Config.InputStyle.Value.default)
                    Text("settings.inputStyle.kanaJIS").tag(Config.InputStyle.Value.defaultKanaJIS)
                    Text("settings.inputStyle.kanaUS").tag(Config.InputStyle.Value.defaultKanaUS)
                    Text("AZIK").tag(Config.InputStyle.Value.defaultAZIK)
                    Text("settings.inputStyle.custom").tag(Config.InputStyle.Value.custom)
                }
                if inputStyle.value == .custom {
                    LabeledContent {
                        Button("settings.edit") {
                            showingRomajiTableEditor = true
                        }
                    } label: {
                        Text("settings.inputStyle.customTable")
                    }
                }
            } header: {
                Label("settings.inputStyle", systemImage: "keyboard")
            }

            Section {
                Picker("settings.keyboardLayout", selection: $keyboardLayout) {
                    Text("QWERTY").tag(Config.KeyboardLayout.Value.qwerty)
                    Text("Australian").tag(Config.KeyboardLayout.Value.australian)
                    Text("Colemak").tag(Config.KeyboardLayout.Value.colemak)
                    Text("Dvorak").tag(Config.KeyboardLayout.Value.dvorak)
                    Text("Dvorak - QWERTY ⌘").tag(Config.KeyboardLayout.Value.dvorakQwertyCommand)
                }
            } header: {
                Label("settings.keyboardLayout", systemImage: "keyboard.badge.ellipsis")
            }

            Section {
                Toggle("settings.pinyinLookup.enable", isOn: $enablePinyinLookup)
                    .help(NSLocalizedString("settings.pinyinLookup.help", comment: "Pinyin lookup help"))
            } header: {
                Label("settings.pinyinLookup", systemImage: "character.book.closed.zh")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Advanced Tab
    @ViewBuilder
    private var advancedTabView: some View {
        Form {
            Section {
                HStack {
                    TextField("settings.conversionProfile", text: $zenzaiProfile, prompt: Text("settings.conversionProfile.placeholder"))
                    helpButton(
                        helpContent: "settings.conversionProfile.help",
                        isPresented: $zenzaiProfileHelpPopover
                    )
                }
                HStack {
                    TextField(
                        "settings.zenzai.inferenceLimit",
                        text: Binding(
                            get: {
                                String(self.$inferenceLimit.wrappedValue)
                            },
                            set: {
                                if let value = Int($0), (1 ... 50).contains(value) {
                                    self.$inferenceLimit.wrappedValue = value
                                }
                            }
                        )
                    )
                    Stepper("", value: $inferenceLimit, in: 1 ... 50)
                        .labelsHidden()
                    helpButton(helpContent: "settings.zenzai.inferenceLimit.help", isPresented: $zenzaiInferenceLimitHelpPopover)
                }
            } header: {
                Label("settings.zenzai", systemImage: "cpu")
            }

            Section {
                Toggle("settings.developer.debugWindow", isOn: $debugWindow)
                Toggle("settings.developer.predictiveTyping", isOn: $debugPredictiveTyping)
                Picker("settings.personalization", selection: $zenzaiPersonalizationLevel) {
                    Text("settings.personalization.off").tag(Config.ZenzaiPersonalizationLevel.Value.off)
                    Text("settings.personalization.soft").tag(Config.ZenzaiPersonalizationLevel.Value.soft)
                    Text("settings.personalization.normal").tag(Config.ZenzaiPersonalizationLevel.Value.normal)
                    Text("settings.personalization.hard").tag(Config.ZenzaiPersonalizationLevel.Value.hard)
                }
            } header: {
                Label("settings.developer", systemImage: "hammer")
            }

            Section {
                LabeledContent("Version") {
                    Text(PackageMetadata.gitTag ?? PackageMetadata.gitCommit ?? "Unknown Version")
                        .monospaced()
                        .bold()
                        .copyable([
                            PackageMetadata.gitTag ?? PackageMetadata.gitCommit ?? "Unknown Version"
                        ])
                }
                .textSelection(.enabled)
            } header: {
                Label("settings.appInfo", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    ConfigWindow()
}
