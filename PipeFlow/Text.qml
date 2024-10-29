import QtQuick
import PipeFlow as My

Text {
	id: root
	property color defaultColor: Theme.colorLayer3
	property string toolTip
	property color setColor
	font.family: Theme.fontFamily
	font.pixelSize: Theme.fontPixelSize
	// TODO: this not working?!
	//color: mouseArea.containsMouse ? "magenta" : defaultColor
	color: defaultColor
	MouseArea {
		id: mouseArea
		width: parent.width
		height: parent.height
		enabled: root.toolTip.length > 0
		hoverEnabled: true
		onContainsMouseChanged: {
			if(root.color != Theme.colorPriHi)
				setColor = color
			root.color = mouseArea.containsMouse ? Theme.colorPriHi : setColor

			if (containsMouse) {
				if (root.toolTip) {
					//showToolTip(root)
					setInfoText(root.toolTip)
				}
			}
		}
	}
	onToolTipChanged: {
		if(mouseArea.containsMouse && root.toolTip) {
			setInfoText(root.toolTip)
		}
	}
}
