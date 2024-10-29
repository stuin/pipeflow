import QtQuick
import QtQuick.Layouts
import PipeFlow as My

Rectangle {
	id: root
	property string label
	property int nodeId
	property string nodeState
	property string nodeType
	property string nodeApi
	property bool muteVolume
	property bool lockVolume: false
	property var chnVols: []
	property list<string> chnMap
	property var inPorts
	property var outPorts
	color: Theme.colorLayer1
	width: childrenRect.width
	height: childrenRect.height
	radius: Theme.margin

	function findPortById (portId) {
		for (let port of inPortLayout.children) {
			if (port && port instanceof My.Port && port.portId === portId) return port
		}
		for (let port of outPortLayout.children) {
			if (port && port instanceof My.Port && port.portId === portId) return port
		}
	}

	ColumnLayout {
		spacing: 1
		My.NodeHeader {
			Layout.fillWidth: true
			label: root.label
			nodeId: root.nodeId
			nodeState: root.nodeState
			nodeType: root.nodeType
			nodeApi: root.nodeApi
			chnVols: root.chnVols
			MouseArea {
				width: parent.width
				height: parent.height
				drag.target: root
				drag.smoothed: false
				drag.threshold: 0
				onPressed: hideToolTip()
			}
		}
		ColumnLayout {
			id: channelVolumes
		}
		Repeater {
			model: root.chnVols
			My.Slider {
				Layout.fillWidth: true
				Layout.leftMargin: Theme.margin
				Layout.rightMargin: Theme.margin + 10
				parent: channelVolumes
				index: -1
				nodeId: root.nodeId
				value: val
				muteVolume: root.muteVolume
				lockVolume: root.lockVolume
				infoText: [
					"("+root.nodeId+") Channel " + chnMap[index] + " Volume : " + modelData + " " + root.groupRoot,
					"- Left click to set volume at cursor"
				].join("\n")
				onRequestValueChanged: {
					var volumes = channelVolumes.children.map(slider => slider.requestValue)
					if(lockVolume)
						volumes = channelVolumes.children.map(slider => requestValue)
					PwCli.set_channel_volumes(root.nodeId, volumes)
				}
				onRequestMuteChanged: {
					PwCli.set_mute(root.nodeId, requestMute)
				}
				onRequestLockChanged: {
					root.lockVolume = requestLock
					for(let slider of channelVolumes.children)
						slider.requestValue = channelVolumes.children[0].value
				}
			}
		}
		Item {
			visible: root.chnVols.rowCount() > 0 // TODO: should we implement count attribute in python?
			width: 10
			height: Theme.margin
		}
		RowLayout {
			width: parent.width
			spacing: Theme.margin
			ColumnLayout {
				id: inPortLayout
				Layout.fillWidth: true
				spacing: 1
				Repeater {
					model: root.inPorts
					My.Port {
						Layout.fillWidth: true
						label: port_label
						portId: port_id
						align: Text.AlignHCenter
						node: root
						portDir: 1
					}
				}
			}

			ColumnLayout {
				id: outPortLayout
				Layout.fillWidth: true
				spacing: 1
				Repeater {
					model: root.outPorts
					My.Port {
						Layout.fillWidth: true
						label: port_label
						portId: port_id
						align: Text.AlignHCenter
						node: root
						portDir: 0
					}
				}
			}
		}
		// spacer for rounded corners
		Item {
			height: root.radius
			width: 1
		}
	}
	Component.onCompleted: {
		var lock = true
		var volume = -1
		for(var i = 0; i < channelVolumes.children.length; i++) {
			if(volume == -1)
				volume = channelVolumes.children[i].value
			if(volume != channelVolumes.children[i].value)
				lock = false
			channelVolumes.children[i].index = i
		}
		root.lockVolume = lock
	}
	component TheText: My.Text {
		topPadding: Theme.padding
		bottomPadding: Theme.padding
		leftPadding: Theme.padding * 2
		rightPadding: Theme.padding * 2
		defaultColor: Theme.colorLayer2
	}
}
