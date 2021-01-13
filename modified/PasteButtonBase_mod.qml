// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0

BackgroundItem {
    id: pasteContainer

    property int popupAnchor // 0 -> left, 1 -> right, 2 -> center
    property alias popupParent: popup.parent

    signal actionSelected(string action) //"store", "strings", "clear", "suggestions"
    property bool showStorage: false
    property bool storageSetUp: false

    height: parent ? parent.height : 0
    width: keyboard.expandedPaste ? pasteRow.width + 2*Theme.paddingMedium
                                                       : pasteIcon.width + Theme.paddingMedium

    preventStealing: popup.visible
    highlighted: down || popup.visible

    onPressAndHold: {
        popup.visible = true
        keyboard.cancelGesture()
    }
    onReleased: {
        if (popup.visible && popup.containsMouse) {
            if (mouseY < -0.5 * popup.height) {
                if (showStorage) {
                    actionSelected("store")
                } else {
                    actionSelected("clear")
                }
            } else {
                if (showStorage) {
                    actionSelected("suggestions")
                } else {
                    actionSelected("strings")
                }
            }
        }
        popup.visible = false
    }
    onCanceled: popup.visible = false
    onPositionChanged: {
        if (!popup.visible) {
            return
        }

        var pos = mapToItem(popup, mouse.x, mouse.y)
        var wasSelected = popup.containsMouse
        popup.containsMouse = popup.contains(Qt.point(pos.x, pos.y - geometry.clearPasteTouchDelta))
        if (wasSelected != popup.containsMouse) {
            SampleCache.play("/usr/share/sounds/jolla-ambient/stereo/keyboard_letter.wav")
            buttonPressEffect.play()
        }
    }

    Rectangle {
        id: popup

        property bool containsMouse
        property int _widerWidth: clearLabel.width > chooseModel.width ? clearLabel.width : chooseModel.width

        visible: false
        width: _widerWidth + geometry.clearPasteMargin
        height: clearLabel.height + chooseModel.height + Theme.paddingMedium
        anchors.right: pasteContainer.popupAnchor == 1 ? parent.right : undefined
        anchors.horizontalCenter: pasteContainer.popupAnchor == 2 ? parent.horizontalCenter : undefined
        anchors.bottom: parent.top
        radius: geometry.popperRadius
        color: keyboard.popperBackgroundColor

        onVisibleChanged: containsMouse = false

        Label {
            id: clearLabel
            anchors {
                top: parent.top
                topMargin: 0.5*Theme.paddingSmall
            }
            color: (parent.containsMouse && mouseY < -0.5*parent.height) ? Theme.highlightColor : Theme.primaryColor
            opacity: Clipboard.hasText? 1 : Theme.opacityLow
            //% "Clear clipboard"
            text: showStorage? qsTr("store clipboard") : qsTrId("text_input-la-clear_clipboard")
            x: 0.5*(parent.width - width)
        }

        Label {
            id: chooseModel
            anchors {
                bottom: parent.bottom
                bottomMargin: 0.5*Theme.paddingSmall
            }
            color: (parent.containsMouse && mouseY > -0.5*parent.height) ? Theme.highlightColor : Theme.primaryColor
            text: storageSetUp? (showStorage? qsTr("suggestions") : qsTr("stored strings")) : qsTr("patch problem")
            x: 0.5*(parent.width - width)
        }
    }
}
