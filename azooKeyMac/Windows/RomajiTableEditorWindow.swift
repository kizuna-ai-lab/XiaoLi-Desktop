import AppKit
import Core
import KanaKanjiConverterModule
import SwiftUI
import UniformTypeIdentifiers

struct RomajiTableEditorWindow: View {
    struct InputTableLine: Sendable, Equatable, Hashable {
        var key: String
        var value: String
    }

    private static func tableToLines(_ table: InputTable) -> [InputTableLine] {
        if let exported = try? InputStyleManager.exportTable(table) {
            exported.components(separatedBy: "\n").compactMap { (line: String) -> InputTableLine? in
                let keyValuePair = line.components(separatedBy: "\t")
                guard keyValuePair.count == 2 else {
                    return nil
                }
                return InputTableLine(key: keyValuePair[0], value: keyValuePair[1])
            }
        } else {
            []
        }
    }

    init(base: InputTable? = nil, onSave: @escaping ((String) -> Void)) {
        if let base {
            self.lines = Self.tableToLines(base)
        } else {
            self.lines = []
        }
        self.onSave = onSave

        self._mappings = .init(initialValue: lines)
        self._shouldOpenBasePickerOnAppear = .init(initialValue: base == nil)
    }

    private let lines: [InputTableLine]
    private let onSave: ((String) -> Void)

    @State private var mappings: [InputTableLine] = []
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var showingBasePicker = false
    @State private var shouldOpenBasePickerOnAppear = false
    @State private var showComplexFunctionalityPopover = false
    @Environment(\.dismiss) private var dismiss

    private var filteredMappings: [InputTableLine] {
        guard !searchText.isEmpty else {
            return mappings
        }

        return mappings.filter { mapping in
            mapping.key.localizedCaseInsensitiveContains(searchText) || mapping.value.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView
            mappingInputView
            Divider()
            searchView
            mappingListView
            footerView
        }
        .padding()
        .frame(width: 600, height: 600)
        .onAppear {
            loadMappings()
            if shouldOpenBasePickerOnAppear {
                showingBasePicker = true
                // 一度出したらもう出さない
                shouldOpenBasePickerOnAppear = false
            }
        }
        .sheet(isPresented: $showingBasePicker) {
            basePickerView
        }
        .alert("error.prefix", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private enum BasePreset: CaseIterable, Hashable {
        case `default`
        case kanaJIS
        case kanaUS
        case azik

        var title: String {
            switch self {
            case .default: return NSLocalizedString("settings.inputStyle.default", comment: "Default")
            case .kanaJIS: return NSLocalizedString("settings.inputStyle.kanaJIS", comment: "Kana JIS")
            case .kanaUS: return NSLocalizedString("settings.inputStyle.kanaUS", comment: "Kana US")
            case .azik: return "AZIK"
            }
        }
    }

    @ViewBuilder
    private var basePickerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("romajiTable.selectBase")
                .font(.headline)
            ForEach(BasePreset.allCases, id: \.self) { preset in
                Button(preset.title) {
                    applyPreset(preset)
                    showingBasePicker = false
                }
            }
            HStack {
                Spacer()
                Button("settings.cancel", role: .cancel) {
                    showingBasePicker = false
                }
            }
        }
        .padding()
        .frame(width: 360)
    }

    @ViewBuilder
    private var headerView: some View {
        Text("romajiTable.title")
            .font(.title)
            .bold()
    }

    @ViewBuilder
    private var mappingInputView: some View {
        VStack(alignment: .leading) {
            Text("romajiTable.addMapping")
                .font(.headline)

            HStack {
                TextField("romajiTable.romajiPlaceholder", text: $newKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)

                Image(systemName: "arrow.forward")

                TextField("romajiTable.hiraganaPlaceholder", text: $newValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
                    .onSubmit {
                        self.addMapping()
                    }

                Button("userDict.add") {
                    self.addMapping()
                }
                .disabled(newKey.isEmpty)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var searchView: some View {
        HStack {
            TextField("romajiTable.filter", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text(String(format: NSLocalizedString("romajiTable.mappingCount", comment: "Mapping count"), mappings.count))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var mappingListView: some View {
        VStack(alignment: .leading) {
            Text("romajiTable.currentMappings")
                .font(.headline)

            if mappings.isEmpty {
                VStack(spacing: 12) {
                    Text("romajiTable.empty")
                        .foregroundColor(.secondary)
                    HStack {
                        Button("romajiTable.loadBase") {
                            showingBasePicker = true
                        }
                        Button("romajiTable.loadFromFile") {
                            importFromFile()
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredMappings, id: \.self) { mapping in
                            mappingRow(for: mapping)
                        }
                    }
                }
                .frame(height: 300)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func mappingRow(for mapping: InputTableLine) -> some View {
        HStack {
            Text(mapping.key)
                .font(.system(.body, design: .monospaced))
                .frame(width: 200, alignment: .leading)

            Image(systemName: "arrow.forward")
                .foregroundColor(.secondary)

            Text(mapping.value)
                .frame(width: 200, alignment: .leading)

            Spacer()
            Button("romajiTable.delete", systemImage: "xmark.circle", role: .destructive) {
                removeMapping(mapping)
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .padding(.horizontal)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }

    @ViewBuilder
    private var footerView: some View {
        HStack {
            Button("settings.cancel", role: .cancel) {
                dismiss()
            }

            Spacer()

            Button("romajiTable.save") {
                saveChanges()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            Button("romajiTable.other", systemImage: "ellipsis") {
                self.showComplexFunctionalityPopover = true
            }
            .labelStyle(.iconOnly)
            .popover(isPresented: $showComplexFunctionalityPopover) {
                VStack(alignment: .leading) {
                    Button("romajiTable.resetToDefault", role: .destructive) {
                        loadMappings()
                    }
                    Button("romajiTable.clearAll", role: .destructive) {
                        clearAllMappings()
                    }
                    Divider()
                    Button("romajiTable.exportToFile") {
                        exportToFile()
                    }
                }
                .padding()
            }
        }
    }

    private func addMapping() {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            self.alertMessage = NSLocalizedString("romajiTable.keyRequired", comment: "Key is required")
            self.showingAlert = true
            return
        }

        let checkResult = InputStyleManager.checkFormat(content: "\(trimmedKey)\t\(trimmedValue)")
        switch checkResult {
        case .fullyValid:
            // マッピングを追加
            let newMapping = InputTableLine(key: trimmedKey, value: trimmedValue)
            self.mappings.insert(newMapping, at: 0)
            // フィールドをクリア
            self.newKey = ""
            self.newValue = ""
        case .invalidLines(let errors):
            self.alertMessage = errors.map {
                "\($0)"
            }.joined()
            self.showingAlert = true
        }
    }

    private func removeMapping(_ mapping: InputTableLine) {
        mappings.removeAll { $0 == mapping }
    }

    private func clearAllMappings() {
        mappings.removeAll()
    }

    private func saveChanges() {
        // 変更をエクスポートして保存側へ通知
        let exported = mappings.map { "\($0.key)\t\($0.value)" }.joined(separator: "\n")
        onSave(exported)
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    private func loadMappings() {
        self.mappings = self.lines
    }

    private func applyPreset(_ preset: BasePreset) {
        switch preset {
        case .default:
            self.mappings = Self.tableToLines(InputTable.defaultRomanToKana)
        case .kanaJIS:
            self.mappings = Self.tableToLines(InputTable.defaultKanaJIS)
        case .kanaUS:
            self.mappings = Self.tableToLines(InputTable.defaultKanaUS)
        case .azik:
            self.mappings = Self.tableToLines(InputTable.defaultAZIK)
        }
    }

    private static func parse(exported: String) -> [InputTableLine] {
        exported
            .components(separatedBy: "\n")
            .compactMap { line -> InputTableLine? in
                let pair = line.components(separatedBy: "\t")
                guard pair.count == 2 else {
                    return nil
                }
                return .init(key: pair[0], value: pair[1])
            }
    }

    private func importFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = NSLocalizedString("romajiTable.selectTSV", comment: "Select TSV file")

        let handler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                let parsed = Self.parse(exported: text)
                if parsed.isEmpty {
                    showAlert(NSLocalizedString("romajiTable.noValidMappings", comment: "No valid mappings found"))
                    return
                }
                self.mappings = parsed
            } catch {
                showAlert(String(format: NSLocalizedString("romajiTable.loadFailed", comment: "Load failed"), error.localizedDescription))
            }
        }

        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            panel.beginSheetModal(for: window, completionHandler: handler)
        } else {
            panel.begin(completionHandler: handler)
        }
    }

    private func exportToFile() {
        let exported = mappings.map { "\($0.key)\t\($0.value)" }.joined(separator: "\n")
        do {
            let url = try CustomInputTableStore.save(exported: exported)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            showAlert(String(format: NSLocalizedString("romajiTable.exportFailed", comment: "Export failed"), error.localizedDescription))
        }
    }
}

#Preview {
    RomajiTableEditorWindow(base: .defaultRomanToKana) { _ in }
}
