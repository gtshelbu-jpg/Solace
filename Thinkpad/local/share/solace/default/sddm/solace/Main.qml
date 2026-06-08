import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1920
  height: 1080
  color: "#07090f"

  function defaultUserName() {
    var last = (userModel.lastUser || "").toString()
    if (last.length > 0)
      return last

    if (userModel.rowCount && userModel.rowCount() > 0) {
      var first = userModel.data(userModel.index(0, 0), Qt.DisplayRole)
      return (first || "").toString()
    }

    return ""
  }

  property string currentUser: defaultUserName()
  property bool loginFailed: false
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("Solace") !== -1 || name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  Image {
    anchors.fill: parent
    source: "background.jpg"
    fillMode: Image.PreserveAspectCrop
    smooth: true
  }

  Rectangle {
    anchors.fill: parent
    color: "#07090f"
    opacity: 0.56
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#22070b12" }
      GradientStop { position: 0.58; color: "#99070b12" }
      GradientStop { position: 1.0; color: "#dd070b12" }
    }
  }

  Text {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 44
    anchors.topMargin: 34
    text: "Solace"
    color: "#f6f7fb"
    opacity: 0.92
    font.family: "Inter"
    font.pixelSize: 24
    font.weight: Font.DemiBold
  }

  Text {
    id: clock
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 44
    anchors.topMargin: 34
    text: Qt.formatDateTime(new Date(), "ddd  h:mm AP")
    color: "#f6f7fb"
    opacity: 0.78
    font.family: "Inter"
    font.pixelSize: 18
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd  h:mm AP")
  }

  Rectangle {
    id: panel
    width: Math.min(440, root.width - 64)
    height: 500
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: Math.max(38, root.width * 0.09)
    radius: 18
    color: "#d90b0f17"
    border.color: root.loginFailed ? "#d96b6b" : "#33ffffff"
    border.width: 1

    Column {
      anchors.fill: parent
      anchors.margins: 34
      spacing: 18

      Image {
        id: logo
        source: "logo.png"
        width: Math.min(sourceSize.width, parent.width)
        height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
        fillMode: Image.PreserveAspectFit
        smooth: true
      }

      Text {
        text: "Welcome back"
        color: "#f6f7fb"
        font.family: "Inter"
        font.pixelSize: 28
        font.weight: Font.DemiBold
      }

      Text {
        text: "Username"
        color: "#8d98ad"
        font.family: "Inter"
        font.pixelSize: 13
      }

      Rectangle {
        width: parent.width
        height: 46
        radius: 10
        color: "#66070b12"
        border.color: username.activeFocus ? "#8bb8ff" : "#26ffffff"
        border.width: 1

        TextInput {
          id: username
          anchors.fill: parent
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          verticalAlignment: TextInput.AlignVCenter
          text: root.currentUser
          color: "#f6f7fb"
          selectionColor: "#3b6aa5"
          selectedTextColor: "#ffffff"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
          selectByMouse: true

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              password.forceActiveFocus()
              event.accepted = true
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 54
        radius: 10
        color: "#99070b12"
        border.color: password.activeFocus ? "#8bb8ff" : "#26ffffff"
        border.width: 1

        TextInput {
          id: password
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 18
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          passwordCharacter: "\u2022"
          color: "#f6f7fb"
          selectionColor: "#3b6aa5"
          selectedTextColor: "#ffffff"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 22
          focus: true

          onTextChanged: root.loginFailed = false

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              sddm.login(username.text, password.text, root.sessionIndex)
              event.accepted = true
            }
          }
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 18
          anchors.verticalCenter: parent.verticalCenter
          visible: password.text.length === 0 && !password.activeFocus
          text: "Password"
          color: "#647086"
          font.family: "Inter"
          font.pixelSize: 16
        }
      }

      Text {
        width: parent.width
        text: root.loginFailed ? "Password was not accepted" : "Press Enter to start Solace"
        color: root.loginFailed ? "#ff9f9f" : "#8d98ad"
        font.family: "Inter"
        font.pixelSize: 14
      }
    }
  }

  Text {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 44
    anchors.bottomMargin: 34
    text: "Solace Hyprland"
    color: "#f6f7fb"
    opacity: 0.58
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 14
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      password.text = ""
      password.forceActiveFocus()
    }
    function onLoginSucceeded() {
      root.loginFailed = false
    }
  }

  Component.onCompleted: {
    if (username.text.length > 0)
      password.forceActiveFocus()
    else
      username.forceActiveFocus()
  }
}
