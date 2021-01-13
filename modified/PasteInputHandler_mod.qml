// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Nemo.Configuration 1.0 // patch paste-stored-strings

InputHandler {
    id: pasteHandler

    function formatText(text) {
        return Theme.highlightText(text, MInputMethodQuick.surroundingText, Theme.highlightColor)
    }

    onSelect: {
        MInputMethodQuick.sendCommit(text, -MInputMethodQuick.cursorPosition, MInputMethodQuick.surroundingText.length)
    }

    onRemove: {
        // We're using an unused key modifier flag as a back channel.
        MInputMethodQuick.sendKey(Qt.Key_Delete, 0x80000000, text)
    }

    onPaste: {
        MInputMethodQuick.sendCommit(Clipboard.text)
    }

    topItem: Component {
        TopItem {
            SilicaListView {
                anchors.fill: parent
                model: storedStrings
                orientation: ListView.Horizontal
                spacing: Theme.paddingMedium
                visible: showStored

                header: PasteButton {
                    showStorage: true
                    storageSetUp: true
                    onClicked: {
                        MInputMethodQuick.sendCommit(Clipboard.text)
                        keyboard.expandedPaste = false
                    }
                    onActionSelected: {
                        actionSelector(action)
                    }
                }
                delegate: BackgroundItem {
                    id: backGround
                    onClicked: {
                        if (showStored)
                            MInputMethodQuick.sendCommit(model.text)
                    }
                    width: storedText.width + Theme.paddingMedium
                    height: parent.height

                    Text {
                        id: storedText
                        anchors.centerIn: parent
                        color: backGround.down ? Theme.highlightColor : Theme.primaryColor
                        font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                        text: model.text
                    }
                }
            }

            HorizontalPredictionListView {
                id: horizontalList

                handler: pasteHandler
                model: suggestionModel
                canRemove: !!MInputMethodQuick.extensions.autoFillCanRemove
                visible: !showStored
                patchSetUp: true
                onActionActivated: {
                    actionSelector(action)
                }

                Connections {
                    target: suggestionModel
                    onStringsChanged: horizontalList.showRemoveButton = false
                    onKeyClick: horizontalList.showRemoveButton = false
                }
            }
        }
    }

    verticalItem: Component {
        Item {
            SilicaListView {
                anchors.fill: parent
                model: storedStrings
                orientation: ListView.Vertical
                spacing: Theme.paddingMedium
                visible: showStored

                header: PasteButtonVertical {
                    showStorage: true
                    storageSetUp: true
                    height: geometry.keyHeightLandscape
                    width: parent.width
                    onClicked: {
                        MInputMethodQuick.sendCommit(Clipboard.text)
                        keyboard.expandedPaste = false
                    }
                    onActionSelected: {
                        actionSelector(action)
                    }
                }
                delegate: BackgroundItem {
                    id: backGround
                    onClicked: {
                        if (showStored)
                            MInputMethodQuick.sendCommit(model.text)
                    }
                    width: parent.width
                    height: storedText.height

                    Text {
                        id: storedText
                        anchors.centerIn: parent
                        color: backGround.down ? Theme.highlightColor : Theme.primaryColor
                        font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                        text: model.text
                    }
                }
            }

            VerticalPredictionListView {
                id: verticalList

                handler: pasteHandler
                model: suggestionModel
                canRemove: !!MInputMethodQuick.extensions.autoFillCanRemove
                visible: !showStored
                onActionActivated: {
                    actionSelector(action)
                }

                Connections {
                    target: suggestionModel
                    onStringsChanged: verticalList.showRemoveButton = false
                    onKeyClick: horizontalList.showRemoveButton = false
                }
            }
        }
    }

    SilicaPrivate.StringListModel {
        id: suggestionModel

        signal keyClick

        propertyName: "text"
        strings: MInputMethodQuick.extensions.autoFillSuggestions || []
    }

    function handleKeyClick() {
        keyboard.expandedPaste = false
        suggestionModel.keyClick()
        return false
    }

    onActiveChanged: {
        readStoredStrings()
        if (useStringStorage.value === 0)
            showStored = false
        else
            showStored = true
    }

    property bool showStored: true

    ConfigurationValue {
        id: stringStorage
        key: "/apps/patchmanager/paste-stored-strings/strings"
        defaultValue: []
    }

    ConfigurationValue {
        id: useStringStorage
        key: "/apps/patchmanager/paste-stored-strings/enabled"
        defaultValue: -1 // 0 - false, 1 - true
    }

    function actionSelector(act) {
        if (act === "store")
            saveClipboard()
        else if (act === "strings")
            showStored = true
        else if (act === "clear")
            Clipboard.text = ""
        else if (act === "suggestions")
            showStored = false
        return
    }

    function saveClipboard() {
        var list = []
        if (Clipboard.hasText) {
            list = stringStorage.value
            list.unshift(Clipboard.text)
            stringStorage.value = list
            stringStorage.sync()
            storedStrings.add(Clipboard.text, 0)
        }
        return
    }

    function readStoredStrings() {
        var i = 0;
        storedStrings.clear();
        if (stringStorage.value.length > 0) {
            while (i < stringStorage.value.length) {
                storedStrings.add(stringStorage.value[i]);
                i++;
            }
        } else {
            storedStrings.add("-");
        }

        return;
    }

    ListModel {
        id: storedStrings
        ListElement {
            text: "eka"
        }
        // { "text": "string" }
        function add(str, i) {
            if (i === undefined || i >= storedStrings.count || i < 0) {
                append({"text": str })
            } else {
                insert(i, {"text": str })
            }
        }
    }
}
