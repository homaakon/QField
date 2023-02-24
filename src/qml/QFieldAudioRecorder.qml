import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQuick.Shapes 1.14
import QtMultimedia 5.14

import org.qfield 1.0

import Theme 1.0

Popup {
  id : audioRecorder

  signal finished(string path)
  signal canceled()

  property bool preRecording: true
  property bool hasRecordedClip: !recorder.recording && player.duration > 0
  property int popupWidth: Math.min(400, mainWindow.width <= mainWindow.height ? mainWindow.width - Theme.popupScreenEdgeMargin : mainWindow.height - Theme.popupScreenEdgeMargin)

  width: popupWidth
  height: Math.min(mainWindow.height - Theme.popupScreenEdgeMargin, popupWidth + toolBar.height + recordButton.height)
  x: (parent.width - width) / 2
  y: (parent.height - height) / 2
  z: 10000 // 1000s are embedded feature forms, use a higher value to insure feature form popups always show above embedded feature formes
  padding: 0

  closePolicy: Popup.CloseOnEscape
  dim: true

  onAboutToShow: {
    preRecording = true;
    player.source = ''
  }

  AudioRecorder {
    id: recorder

    onRecordingLoaded: {
      var path = recorder.actualLocation.toString()
      // On Android, the file protocol prefix is present while on Linux it isn't
      var filePos = path.indexOf('file://')
      path = filePos == -1 ? 'file://' + path : path
      player.source = path
    }
  }

  Video {
    id: player

    visible: false

    anchors.left: parent.left
    anchors.top: parent.top

    width: parent.width
    height: parent.height - 54

    autoLoad: true

    onDurationChanged: {
      positionSlider.to = duration / 1000;
      positionSlider.value = 0;
    }

    onPositionChanged: {
      positionSlider.value = position / 1000;
    }
  }

  Page {
    width: parent.width
    height: parent.height
    padding: 10
    header: ToolBar {
      id: toolBar

      background: Rectangle {
        color: "transparent"
        height: 48
      }

      RowLayout {
        width: parent.width
        height: 48

        Label {
          Layout.leftMargin: 58
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          text: qsTr('Audio Recorder')
          font: Theme.strongFont
          color: Theme.mainColor
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        QfToolButton {
          id: closeButton
          Layout.rightMargin: 10
          Layout.alignment: Qt.AlignVCenter
          iconSource: Theme.getThemeIcon( 'ic_close_black_24dp' )
          bgcolor: "transparent"

          onClicked: {
            audioRecorder.canceled()
          }
        }
      }
    }

    ColumnLayout {
      width: parent.width
      height: parent.height

      Rectangle {
        id: audioFeedback
        Layout.fillWidth: true
        Layout.fillHeight: true

        color: "transparent"

        Rectangle {
          id: levelFeedback
          anchors.centerIn: parent
          width: 120 + (Math.min(audioFeedback.width, audioFeedback.height) - 120) * recorder.level
          height: width
          radius: width / 2
          color: "#44808080"

          SequentialAnimation {
            NumberAnimation {
              target:  levelFeedback
              property: "width"
              to: 120 + (Math.min(audioFeedback.width, audioFeedback.height) - 120)
              duration: 2000
              easing.type: Easing.InOutQuad
            }
            NumberAnimation {
              target:  levelFeedback
              property: "width"
              to: 120
              duration: 2000
              easing.type: Easing.InOutQuad
            }
            running: !recorder.hasLevel && recorder.recording
            loops: Animation.Infinite
          }

          QfToolButton {
            id: recordButton
            anchors.centerIn: parent
            width: 120
            height: 120
            iconSource: ''
            round: true
            bgcolor: !recorder.recording ? "#FF0000" : "#808080"

            onClicked: {
              if (preRecording) {
                recorder.record();
                preRecording = false;
              } else {
                if (recorder.recording) {
                  // As of Qt5.15, Android doesn't support pausing a recording, revisit in Qt6
                  recorder.stop();
                } else {
                  recorder.record();
                  player.source = ''
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        QfToolButton {
          id: playButton
          enabled: audioRecorder.hasRecordedClip
          opacity: enabled ? 1 : 0.25

          iconSource: player.playbackState == MediaPlayer.PlayingState
                      ? Theme.getThemeVectorIcon('ic_pause_black_24dp')
                      : Theme.getThemeVectorIcon('ic_play_black_24dp')
          bgcolor: "transparent"

          onClicked: {
            if (player.playbackState == MediaPlayer.PlayingState) {
              player.pause()
            } else {
              player.play()
            }
          }
        }

        Slider {
          id: positionSlider
          Layout.fillWidth: true

          from: 0
          to: 0

          enabled: audioRecorder.hasRecordedClip
          opacity: enabled ? 1 : 0.25

          onMoved: {
            player.seek(value * 1000)
          }
        }

        Label {
          id: durationLabel
          Layout.preferredWidth: durationLabelMetrics.boundingRect('00:00:00').width
          Layout.rightMargin: 14

          color: player.playbackState == MediaPlayer.PlayingState ? 'black' : 'gray'
          font: Theme.tipFont
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter

          text: {
            if (!preRecording && recorder.duration > 0) {
              var seconds = Math.ceil(recorder.duration / 1000);
              var hours = Math.floor(seconds / 60 / 60) + '';
              seconds -= hours * 60 * 60;
              var minutes = Math.floor(seconds / 60) + '';
              seconds = (seconds - minutes * 60) + '';
              return hours.padStart(2,'0') + ':' + minutes.padStart(2,'0') + ':' + seconds.padStart(2,'0');
            } else {
              return '-';
            }
          }
        }

        FontMetrics {
          id: durationLabelMetrics
          font: durationLabel.font
        }

        QfToolButton {
          id: acceptButton
          Layout.alignment: Qt.AlignVCenter
          iconSource: Theme.getThemeIcon( 'ic_check_black_48dp' )
          round: true
          bgcolor: "transparent"
          enabled: audioRecorder.hasRecordedClip
          opacity: enabled ? 1 : 0.25

          onClicked: {
            var path = recorder.actualLocation.toString()
            var filePos = path.indexOf('file://')
            audioRecorder.finished(filePos === 0 ? path.substring(7) : path)
            audioRecorder.close();
          }
        }
      }
    }
  }
}