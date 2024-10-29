import QtQuick
import PipeFlow as My

Rectangle {
	id: root
	property int index
	property int nodeId
	property real value
	property real requestValue
	property bool muteVolume
	property bool requestMute
	property bool lockVolume
	property bool requestLock
	property int maxw: Math.round(width - thumb.width)
	property string infoText
	color: Theme.colorLayer0
	implicitWidth: valText.width
	implicitHeight: valText.height
	Rectangle {
		id: thumb
		property color baseColor: Theme.colorLayer2
		x: Math.round(maxw * value / Theme.maxVolume)
		height: root.height
		width: Theme.fontPixelSize
		color: mouseArea.containsMouse ? Theme.colorPriLow : baseColor
	}
	My.Text {
		id: valText
		text: Math.round(root.value * 100) + "%"
		width: root.width
		horizontalAlignment: Text.AlignHCenter
		color: Theme.colorLayer1
	}
	My.Text {
		property bool muteVolume: root.muteVolume
		property string a: muteVolume ? "M" : "U"
		text: a
		toolTip: [
			"(" + root.nodeId + (muteVolume ? ") Muted" : ") Unmuted"),
			"- Left click to toggle mute"
		].join("\n")
		color: muteVolume ? Theme.colorRedLow : Theme.colorLayer3
		width: root.width + 11
		horizontalAlignment: Text.AlignRight
		visible: root.index == 0
		MouseArea {
			width: parent.width
			height: parent.height
			hoverEnabled: false
			onClicked: requestMute = !requestMute
		}
		onMuteVolumeChanged: {
			color = muteVolume ? Theme.colorRedLow : Theme.colorLayer3
			if(requestMute != muteVolume)
				requestMute = muteVolume
			thumb.baseColor = muteVolume ? Theme.colorRedLow : Theme.colorLayer2
		}
	}
	My.Text {
		property bool lockVolume: root.lockVolume
		property string a: lockVolume ? "L" : "S"
		text: a
		toolTip: [
			"(" + root.nodeId + ") Channel Volumes " + (lockVolume ? "Locked Together" : "Separate"),
			"- Left click to toggle channel lock"
		].join("\n")
		color: lockVolume ? Theme.colorLayer3 : Theme.colorYellowLow
		width: root.width + 11
		horizontalAlignment: Text.AlignRight
		visible: root.index == 1
		MouseArea {
			width: parent.width
			height: parent.height
			onClicked: root.requestLock = !root.lockVolume
		}
		onLockVolumeChanged: {
			color = lockVolume ? Theme.colorLayer3 : Theme.colorYellowLow
			if(requestLock != lockVolume)
				requestLock = lockVolume
		}
	}
	MouseArea {
		id: mouseArea
		anchors.fill: parent
		hoverEnabled: true
		onEntered: {
			setInfoText(root.infoText)
		}
		onPressed: function () {
			hideToolTip()
			timer.start()
		}
		onReleased: function () {
			timer.stop()
		}
		Timer {
			id: timer
			interval: 100 // we dont want to call pw-cli faster than this
			triggeredOnStart: true
			repeat: true
			onTriggered: root.requestValue = clamp(mouseArea.mouseX / root.width * Theme.maxVolume, 0, Theme.maxVolume)
		}
	}
	Component.onCompleted: {
		requestValue = value
		requestMute = muteVolume
		requestLock = lockVolume
	}
}
