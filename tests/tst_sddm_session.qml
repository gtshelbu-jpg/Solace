import QtQuick 2.15
import QtTest 1.3

Item {
  id: fixture
  width: 1280
  height: 900

  property var sessionModel: QtObject {
    property int lastIndex: 0
    property var names: ["Solace Lua Test (snapshot)", "Hyprland", "Solace (Hyprland uwsm)"]
    function rowCount() { return names.length }
    function index(row, column) { return row }
    // Match the actual SDDM model: DisplayRole is deliberately unsupported.
    function data(row, role) { return role === Qt.UserRole + 4 ? names[row] : "" }
  }
  property var userModel: QtObject {
    property string lastUser: "testuser"
  }
  property var sddm: QtObject {
    property int selectedSession: -1
    signal loginFailed()
    signal loginSucceeded()
    function login(user, password, session) { selectedSession = session }
  }

  TestCase {
    id: test
    name: "SolaceSessionSelector"
    when: windowShown
    property var theme: null

    function initTestCase() {
      var component = Qt.createComponent("../Thinkpad/local/share/solace/default/sddm/solace/Main.qml")
      compare(component.status, Component.Ready, component.errorString())
      theme = component.createObject(fixture, { width: 1280, height: 900 })
      verify(theme !== null)
    }

    function cleanupTestCase() {
      if (theme !== null)
        theme.destroy()
    }

    function test_01_normal_session_is_default_not_first_solace_match() {
      compare(sessionModel.data(0, Qt.DisplayRole), "")
      compare(theme.sessionIndex, 2)
      compare(theme.sessionName(), "Solace (Hyprland uwsm)")
    }

    function test_02_mouse_can_select_test_session() {
      var selector = findChild(theme, "sessionSelector")
      verify(selector !== null)
      mouseClick(selector, selector.width / 2, selector.height / 2)
      compare(theme.sessionIndex, 0)
      compare(theme.sessionName(), "Solace Lua Test (snapshot)")
    }

    function test_03_keyboard_cycles_and_wraps() {
      var selector = findChild(theme, "sessionSelector")
      selector.forceActiveFocus()
      keyClick(Qt.Key_Left)
      compare(theme.sessionIndex, 2)
      keyClick(Qt.Key_Right)
      compare(theme.sessionIndex, 0)
    }

    function test_04_login_uses_selected_session() {
      var password = findChild(theme, "password")
      password.forceActiveFocus()
      keyClick(Qt.Key_Return)
      compare(sddm.selectedSession, 0)
    }
  }
}
