import QtQuick 2.0
import SddmComponents 2.0

// Omarchy's stock greeter with one addition: an editable username line.
// The stock theme always logs in userModel.lastUser, which makes a second
// account unreachable. Up/Down cycles through local users, Tab moves between
// the username and password fields, Enter logs in.
Rectangle {
  id: root
  width: 640
  height: 480
  color: "#1a1b26"

  property string currentUser: username.text.trim()
  property bool loginFailed: false
  property var userNames: []
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  function loadUsers() {
    var names = []
    for (var i = 0; i < userModel.rowCount(); i++) {
      // UserModel::NameRole is Qt::UserRole + 1
      var n = (userModel.data(userModel.index(i, 0), Qt.UserRole + 1) || "").toString()
      if (n.length > 0)
        names.push(n)
    }
    userNames = names
  }

  function cycleUser(step) {
    if (userNames.length === 0)
      return
    var idx = userNames.indexOf(username.text.trim())
    if (idx < 0)
      idx = step > 0 ? -1 : 0
    idx = (idx + step + userNames.length) % userNames.length
    username.text = userNames[idx]
    root.loginFailed = false
    password.text = ""
  }

  function attemptLogin() {
    if (root.currentUser.length === 0) {
      username.forceActiveFocus()
      return
    }
    sddm.login(root.currentUser, password.text, root.sessionIndex)
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

  Column {
    anchors.centerIn: parent
    spacing: 40

    Image {
      id: logo
      source: "logo.png"
      width: Math.min(sourceSize.width, root.width * 0.8)
      height: sourceSize.width > 0 ? Math.round(width * sourceSize.height / sourceSize.width) : 0
      fillMode: Image.PreserveAspectFit
      anchors.horizontalCenter: parent.horizontalCenter
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 22

      // Username line: "> magnus_"
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Text {
          text: "›"
          color: root.loginFailed ? "#f7768e" : "#7aa2f7"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 26
          anchors.verticalCenter: parent.verticalCenter
        }

        TextInput {
          id: username
          width: entry.width - 20
          text: userModel.lastUser
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignLeft
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 24
          font.letterSpacing: 2
          color: activeFocus ? "#c0caf5" : "#a9b1d6"
          selectionColor: "#33467c"
          selectedTextColor: "#c0caf5"
          anchors.verticalCenter: parent.verticalCenter

          cursorDelegate: Rectangle {
            width: 12
            height: username.font.pixelSize
            color: "#7aa2f7"
            visible: username.activeFocus
            SequentialAnimation on opacity {
              running: username.activeFocus
              loops: Animation.Infinite
              NumberAnimation { to: 0; duration: 500 }
              NumberAnimation { to: 1; duration: 500 }
            }
          }

          onTextChanged: root.loginFailed = false

          Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) {
              password.forceActiveFocus()
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              root.cycleUser(-1)
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              root.cycleUser(1)
              event.accepted = true
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: { username.forceActiveFocus(); username.selectAll() }
          }
        }
      }

      // Password line: lock icon + entry box (stock Omarchy look)
      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 15

        Image {
          source: root.loginFailed ? "lock-failed.png" : "lock.png"
          width: 34
          height: 38
          fillMode: Image.PreserveAspectFit
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: entry.width
          height: entry.height

          Image {
            id: entry
            source: root.loginFailed ? "entry-failed.png" : "entry.png"
            anchors.centerIn: parent
          }

          Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Repeater {
              model: Math.min(password.text.length, 21)

              Image {
                source: "bullet.png"
                width: 7
                height: 7
              }
            }
          }

          TextInput {
            id: password
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            verticalAlignment: TextInput.AlignVCenter
            echoMode: TextInput.Password
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            font.letterSpacing: 5
            passwordCharacter: "•"
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorDelegate: Item {}

            onTextChanged: root.loginFailed = false

            Keys.onPressed: {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.attemptLogin()
                event.accepted = true
              } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                username.forceActiveFocus()
                username.selectAll()
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.cycleUser(-1)
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                root.cycleUser(1)
                event.accepted = true
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: password.forceActiveFocus()
            }
          }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "↑↓ switch user   ↹ edit name"
        color: "#3b4261"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
      }
    }
  }

  Component.onCompleted: {
    loadUsers()
    if (username.text.length > 0)
      password.forceActiveFocus()
    else
      username.forceActiveFocus()
  }
}
