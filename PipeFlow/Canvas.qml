import QtQuick
import PipeFlow as My

Item {
	id: canvas
	clip: true
	MouseArea {
		id: canvasMouse
		anchors.fill: parent
		hoverEnabled: true
		onEntered: setInfoText("")
	}
	Flow {
		id: nodeItems
		property int sortMode: Theme.sortMode
		property bool groupVertically: Theme.groupVertically > 0
		anchors.fill: parent
		anchors.margins: 30
		spacing: 30
		flow: groupVertically ? Flow.LeftToRight : Flow.TopToBottom

		property list<string> columnTypes: Theme.typeOrder

		function chooseColumn(type) {
			var i = 0
			while (i < columnTypes.length && columnTypes[i] != type)
			    i++
			if (i == columnTypes.length)
				columnTypes.push(type)

			if (nodeItems.sortMode == 1)
				return i
			return 0
		}

		onPositioningComplete: {
			for (let column of nodeItems.children) {
				for (let node of column.children) {
					if (node instanceof My.Node) {
						node.x++
						node.x--
						node.y++
						node.y--

						if (node.parent == unassigned) {
							node.groupRoot = 0
							nodeItems.children[groupRoot]
						}
					}
				}
			}
			console.log(columnTypes)
		}
	}
	Item {
		id: unassigned
		Repeater {
			model: nodeItems.columnTypes
			delegate: Flow {
				flow: nodeItems.groupVertically ? Flow.TopToBottom : Flow.LeftToRight
				height: flow == Flow.TopToBottom ? parent.height : undefined
				width: flow == Flow.LeftToRight ? parent.width : undefined
				spacing: 10
				parent: nodeItems
			}
		}
		Repeater {
			model: NodeModel
			delegate: My.Node {
				visible: !Theme.hideNodes.includes(node_label)
				label: node_label
				nodeId: node_id
				nodeState: node_state
				nodeType: node_type
				nodeApi: node_api
				muteVolume: mute
				chnVols: chnvols
				chnMap: chnmap.split(",")
				inPorts: inports
				outPorts: outports
				groupRoot: nodeItems.chooseColumn(nodeType)
				parent: nodeItems.children[groupRoot]
			}
		}
	}
	Item {
		id: linkItems
		property var nodeLinks
		anchors.fill: parent
		layer.enabled: true
		layer.samples: 8
		Repeater {
			model: LinkModel
			delegate: My.Link {
				anchors.fill: parent
				index: index
				linkId: link_id
				inNode: input_node_id
				outNode: output_node_id
				inPort: findNodePortById(input_node_id, input_port_id)
				outPort: findNodePortById(output_node_id, output_port_id)
				visible: outPort && outPort.visible && inPort && inPort.visible
			}

			onItemAdded: {
				if(!linkItems.nodeLinks)
					linkItems.nodeLinks = new Map()

				if (item instanceof My.Link && item.outPort && item.inPort) {
					if (!linkItems.nodeLinks.has(item.outNode))
						linkItems.nodeLinks.set(item.outNode, [])
					if (!linkItems.nodeLinks.get(item.outNode).includes(item.inNode))
						linkItems.nodeLinks.get(item.outNode).push(item.inNode)

					if (!linkItems.nodeLinks.has(item.inNode))
						linkItems.nodeLinks.set(item.inNode, [])
					if (!linkItems.nodeLinks.get(item.inNode).includes(item.outNode))
						linkItems.nodeLinks.get(item.inNode).push(item.outNode)
				}
				if (nodeItems.sortMode == 2)
					timer.start()
			}
		}

		function groupNodes() {
			if (nodeItems.sortMode != 2)
				return

			var nodeGroups = []
			var visited = []
			for (const [node, links] of linkItems.nodeLinks) {
				if (!visited.includes(node)) {
					var current = node
					var currentSet = [node]
					while(currentSet.filter(link => !visited.includes(link)).length > 0) {
						for (let link of nodeLinks.get(current).filter(link => !visited.includes(link) && !currentSet.includes(link)))
							currentSet.push(link)
						visited.push(current)
						current = currentSet.filter(link => !visited.includes(link))[0]
					}
					nodeGroups.push(currentSet)
					console.log(currentSet)
				}
			}

			var i = 0
			for (let group of nodeGroups) {
				//while (i < nodeItems.columnTypes.length && nodeItems.columnTypes[i] != group[0])
				i++
				//if (i == nodeItems.columnTypes.length)
				//	nodeItems.columnTypes.push(group[0].toString())

				for (let column of nodeItems.children) {
					for (let node of column.children) {
						if (node instanceof My.Node && group.includes(node.nodeId)) {
							node.groupRoot = i
							node.parent = nodeItems.children[node.groupRoot]
						}
					}
				}
			}
		}
		Timer {
			id: timer
			interval: 100
			triggeredOnStart: false
			repeat: false
			onTriggered: linkItems.groupNodes()
		}
	}
	ToolTip {
		id: toolTip
		visible: false
	}
	enum ItemSide {
		Top,
		Right,
		Bottom,
		Left
	}
	function findSideWithMostSpace (x, y, w, h) {
		let l = x
		let ret = My.Canvas.ItemSide.Top
		if (canvas.width - x - w > l) {
			l = canvas.width - x - w
			ret = My.Canvas.ItemSide.Right
		}
		if (canvas.height - y - h > l) {
			l = canvas.height - y - h
			ret = My.Canvas.ItemSide.Bottom
		}
		if (canvas.width - y > l) {
			l = y
			ret = My.Canvas.ItemSide.Left
		}
		return ret
	}
	function showToolTip(item) {
		// TODO: position where most space
		let pos = item.parent.mapToGlobal(item.x, item.y)
		let side = findSideWithMostSpace(pos.x, pos.y, item.width, item.height)
		//console.log("HMMM", item.toolTip, side)
		toolTip.text = item.toolTip
		toolTip.x = pos.x + item.width
		toolTip.y = pos.y + Math.round((item.height/2) - (toolTip.height/2))
		toolTip.visible = true
	}
	function hideToolTip(){
		toolTip.visible = false
	}
	function findNodePortById(nodeId, portId) {
		for (let column of nodeItems.children) {
			for (let node of column.children) {
				if (node instanceof My.Node) {
					if (node.nodeId === nodeId) {
						if (node.findPortById) {
							return node.findPortById(portId)
						}
					}
				}
			}
		}
		return null
	}
	function findLinkIdsByPortId(portId) {
		let ret = []
		for (let link of linkItems.children) {
			if (link instanceof My.Link) {
				if (link.outPort && link.outPort.portId === portId) {
					ret.push(link.linkId)
				}
				if (link.inPort && link.inPort.portId === portId) {
					ret.push(link.linkId)
				}
			}
		}
		return ret
	}
	function findLinkId(linkDir, portId1, portId2) {
		for (let link of linkItems.children) {
			if (link instanceof My.Link) {
				if (linkDir === 0) {
					if (link.outPort && link.outPort.portId === portId1
					&& link.inPort && link.inPort.portId === portId2) {
						return link.linkId
					}
				} else {
					if (link.outPort && link.outPort.portId === portId2
					&& link.inPort && link.inPort.portId === portId1) {
						return link.linkId
					}
				}
			}
		}
		return null
	}
	property var linkBuffer: [[],[]]
	function linkAllTheThings (portDir, portId) {
		if (linkBuffer[portDir].includes(portId)) {
			linkBuffer[portDir] = linkBuffer[portDir].filter(x => x !== portId)
			linkBufferChanged()
		} else {
			if (linkBuffer[1-portDir].length > 0) {
				let pid = linkBuffer[1-portDir][0]
				let linkId = findLinkId(portDir, portId, pid)
				if (linkId) {
					PwLink.remove_link_by_id(linkId)
				} else {
					if (portDir === 0) {
						PwLink.crete_link(portId, pid)
					} else {
						PwLink.crete_link(pid, portId)
					}
				}
				linkBuffer[1-portDir].shift()
				linkBufferChanged()
			} else {
				linkBuffer[portDir].push(portId)
				linkBufferChanged()
			}
		}
	}
	function clamp(num, min, max) {
		return Math.min(Math.max(num, min), max);
	}
}
