//
//  UserDictionaryEditorWindow.swift
//  azooKeyMac
//
//  Created by miwa on 2024/09/22.
//

import Core
import SwiftUI

struct UserDictionaryEditorWindow: View {

    @ConfigState private var userDictionary = Config.UserDictionary()

    @State private var editTargetID: UUID?
    @State private var undoItem: Config.UserDictionaryEntry?

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

    private var isAdditionDisabled: Bool {
        self.userDictionary.value.items.count >= 50
    }

    var body: some View {
        VStack {
            Text("userDict.title")
                .bold()
                .font(.title)
            Text("userDict.beta")
                .font(.caption)
            Spacer()
            if let editTargetID {
                let itemBinding = Binding(
                    get: {
                        self.userDictionary.value.items.first {
                            $0.id == editTargetID
                        } ?? .init(word: "", reading: "")
                    },
                    set: {
                        if let index = self.userDictionary.value.items.firstIndex(where: {
                            $0.id == editTargetID
                        }) {
                            self.userDictionary.value.items[index] = $0
                        }
                    }
                )
                Form {
                    TextField("userDict.word", text: itemBinding.word)
                    TextField("userDict.reading", text: itemBinding.reading)
                    TextField("userDict.hint", text: itemBinding.nonNullHint)
                    HStack {
                        Spacer()
                        Button("userDict.done", systemImage: "checkmark") {
                            self.editTargetID = nil
                        }
                        Spacer()
                    }
                }
            } else {
                HStack {
                    Spacer()
                    Button("userDict.add", systemImage: "plus") {
                        let newItem = Config.UserDictionaryEntry(word: "", reading: "", hint: nil)
                        self.userDictionary.value.items.append(newItem)
                        self.editTargetID = newItem.id
                        self.undoItem = nil
                    }
                    .disabled(self.isAdditionDisabled)
                    if self.isAdditionDisabled {
                        Label("userDict.limitExceeded", systemImage: "exclamationmark.octagon")
                            .foregroundStyle(.red)
                    }
                    if let undoItem {
                        Button("userDict.undo", systemImage: "arrow.uturn.backward") {
                            self.userDictionary.value.items.append(undoItem)
                            self.undoItem = nil
                        }
                    }
                    Spacer()
                }
            }
            HStack {
                Spacer()
                Table(self.userDictionary.value.items) {
                    TableColumn("") { item in
                        HStack {
                            Button("userDict.editButton", systemImage: "pencil") {
                                self.editTargetID = item.id
                                self.undoItem = nil
                            }
                            .buttonStyle(.bordered)
                            .labelStyle(.iconOnly)
                            Button("userDict.deleteButton", systemImage: "trash", role: .destructive) {
                                if let itemIndex = self.userDictionary.value.items.firstIndex(where: {
                                    $0.id == item.id
                                }) {
                                    self.undoItem = self.userDictionary.value.items[itemIndex]
                                    self.userDictionary.value.items.remove(at: itemIndex)
                                }
                            }
                            .buttonStyle(.bordered)
                            .labelStyle(.iconOnly)
                        }
                    }
                    TableColumn("userDict.word", value: \.word)
                    TableColumn("userDict.reading", value: \.reading)
                    TableColumn("userDict.hint", value: \.nonNullHint)
                }
                .disabled(editTargetID != nil)
                Spacer()
            }
            Spacer()
        }
        .frame(minHeight: 300, maxHeight: 600)
        .frame(minWidth: 600, maxWidth: 800)
    }
}

#Preview {
    UserDictionaryEditorWindow()
}
