import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    function storeString(i) {
        var txt = str.text;
        if (!(txt > "")) {
            str.placeholderText = "empty string, not stored";
            return;
        }
        stringsModel.add(txt, i);

        updateStorage();

        return;
    }

    function updateStorage() {
        var i=0, list = [];
        while (i<stringsModel.count) {
            list.push(stringsModel.get(i).txt);
            i++;
        }
        stringStorage.value = list;
        stringStorage.sync();

        return;
    }

    ConfigurationValue {
        id: stringStorage
        key: "/apps/patchmanager/paste-stored-strings/strings"
        defaultValue: []
    }

    ConfigurationValue {
        id: useStringStorage
        key: "/apps/patchmanager/paste-stored-strings/enabled"
        defaultValue: 0 // 0 - false, 1 - true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator{}

        PullDownMenu {
            MenuItem {
                text: qsTr("store")
                onClicked: {
                    storeString()
                    str.text = ""
                }
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Store strings for pasting"
            }

            SectionHeader {
                text: qsTr("Description")
            }

            Label {
                text: qsTr("Press the paste button on the virtual keyboard for a long time " +
                           "to replace the list of word suggestions with the list below " +
                           "or to add the clipboard content to the list. Not compatible with " +
                           "chinese keyboard, nor with the number pad (yet).")
                color: Theme.highlightColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
            }

            Item {
                id: expandable
                property bool expanded: false
                width: parent.width
                height: expanded? expCol.height + expText.height : expText.height

                Label {
                    id: expText
                    text: qsTr("...")
                    x: Theme.horizontalPageMargin
                    MouseArea {
                        anchors.fill: parent
                        onClicked: expandable.expanded = !expandable.expanded
                    }
                }

                Column {
                    id: expCol
                    anchors.top: expText.bottom
                    width: parent.width
                    visible: expandable.expanded

                    Label {
                        text: qsTr("Restarting the keyboard (as user) is required for " +
                                   "activating the patch or updating changes.")
                        color: Theme.highlightColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        width: parent.width - 2*x
                        x: Theme.horizontalPageMargin
                    }

                    TextField {
                        text: "systemctl --user restart maliit-server.service"
                        label: qsTr("tap to copy")
                        color: Theme.secondaryColor
                        width: parent.width
                        readOnly: true
                        onClicked: {
                            Clipboard.text = text
                            label = qsTr("copied to clipboard")
                        }
                    }

                    Label {
                        text: qsTr("Modifies PasteButtonBase.qml, PasteButton.qml, " +
                                   "PasteButtonVertical.qml, VerticalPredictionListView.qml " +
                                   "and Xt9InputHandler.qml.")
                        color: Theme.highlightColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        width: parent.width - 2*x
                        x: Theme.horizontalPageMargin
                    }

                }

            }

            TextSwitch {
				id: onOrOff
                text: checked? qsTr("Stored visible by default.") : qsTr("Suggestions visible by default.")
				checked: false
				onCheckedChanged: {
					if (checked) {
						useStringStorage.value = 1
					} else {
						useStringStorage.value = 0
					}
					useStringStorage.sync()

				}
            }

            Row {
                width: parent.width

                TextField {
                    id: str
                    text: ""
                    placeholderText: qsTr("string to be stored")
                    width: parent.width - strClear.width - Theme.paddingMedium
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        storeString()
                        text = ""
                        focus = false
                    }
                }

                IconButton {
                    id: strClear
                    icon.source: "image://theme/icon-m-clear"
                    width: Theme.iconSizeMedium
                    height: width
                    onClicked: {
                        stringsView.currentIndex = -1
                        str.text = ""
                    }
                }
            }

            SectionHeader {
                text: qsTr("Stored strings")
            }

            SilicaListView {
                id: stringsView
                width: parent.width
                height: (page.height - y < 10*Theme.fontSizeMedium)? 10*Theme.fontSizeMedium : page.height - y
                clip: true
                highlight: Rectangle {
                    color: Theme.highlightBackgroundColor
                    height: stringsView.currentIndex >= 0 ?
                                stringsView.currentItem.height : Theme.fontSizeMedium
                    opacity: Theme.highlightBackgroundOpacity
                }

                highlightFollowsCurrentItem: true

                model: ListModel {
                    id: stringsModel
                    function add(s, i){
                        if (i < 0)
                            i = 0
                        if (i < count)
                            insert(i, {"txt": s})
                        else
                            append({"txt": s})
                        return;
                    }
                    function modify(i, s) {
                        if (i >= 0 && i < count)
                            setProperty(i, "txt", s);
                        return;
                    }
                }

                delegate: ListItem {
                    id: storedItem
                    propagateComposedEvents: true
                    _backgroundColor: "transparent" //does not flash - listviews highlight is enough
                    ListView.onRemove: animateRemoval(storedItem)
                    onClicked: {
                        str.text = txt
                        stringsView.currentIndex = stringsView.indexAt(mouseX, y + mouseY)
                    }
                    onPressAndHold: {
                        stringsView.currentIndex = stringsView.indexAt(mouseX, y + mouseY)
                    }

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("delete")
                            onClicked: {
                                var i=stringsView.currentIndex
                                remorseAction(qsTr("deleting"), function() {
                                    stringsModel.remove(i)
                                    updateStorage()
                                    return
                                })
                            }
                        }
                        MenuItem {
                            text: qsTr("modify")
                            onClicked: {
                                var i=stringsView.currentIndex
                                remorseAction(qsTr("modifying"), function() {
                                    stringsModel.modify(i, str.text)
                                    updateStorage()
                                    str.text = ""
                                    return
                                })
                            }
                        }
                        MenuItem {
                            text: qsTr("move up")
                            onClicked: {
                                var i = stringsView.currentIndex
                                if (i > 0) {
                                    stringsModel.move(i,i-1,1)
                                    updateStorage()
                                    str.text = ""
                                }
                            }
                        }
                        MenuItem {
                            text: qsTr("move down")
                            onClicked: {
                                var i = stringsView.currentIndex
                                if (i < stringsModel.count-1) {
                                    stringsModel.move(i,i+1,1)
                                    updateStorage()
                                    str.text = ""
                                }
                            }
                        }
                    }

                    Label {
                        color: Theme.secondaryColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        width: parent.width - 2*x
                        x: Theme.horizontalPageMargin
                        text: txt
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    Component.onCompleted: {
        var i=0
        stringsModel.clear()
        while (i<stringStorage.value.length) {
            if (stringStorage.value[i] > "") {
                stringsModel.add(stringStorage.value[i])
            }
            i++
        }
        stringsView.currentIndex = -1
		
		if (useStringStorage.value === 0)
			onOrOff.checked = false
		else
			onOrOff.checked = true
			
    }

}
