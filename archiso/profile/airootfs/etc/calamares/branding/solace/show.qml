import QtQuick 2.15

Rectangle {
    id: root
    color: "#f5f7f8"

    function onActivate() {
        rotationTimer.start()
    }

    function onLeave() {
        rotationTimer.stop()
    }

    property int slide: 0
    property var titles: [
        "Installing Solace",
        "Building the desktop",
        "Preparing first boot"
    ]
    property var bodies: [
        "The installer is writing the base system and applying the selected layout.",
        "Solace will add the Hyprland workflow, themes, tools, and login experience after the base install.",
        "When installation finishes, reboot into the new system and let the post-install bootstrap complete."
    ]

    Timer {
        id: rotationTimer
        interval: 4500
        repeat: true
        running: true
        onTriggered: root.slide = (root.slide + 1) % root.titles.length
    }

    Image {
        id: logo
        source: "logo.png"
        width: 96
        height: 96
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 54
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Text {
        id: title
        text: root.titles[root.slide]
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: 28
        color: "#0a1018"
        font.pixelSize: 30
        font.bold: true
    }

    Text {
        text: root.bodies[root.slide]
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: title.bottom
        anchors.topMargin: 16
        width: Math.min(parent.width - 120, 680)
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        color: "#42505d"
        font.pixelSize: 17
        lineHeight: 1.18
    }

    Rectangle {
        width: 220
        height: 4
        radius: 2
        color: "#2c8478"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 54
    }
}
