import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:open_ai_voice_assistant/src/services/create_ephemeral_token.dart';
import 'package:permission_handler/permission_handler.dart';

class OpenAiAssistant {
  ///Created a singleton of OpenAiVoiceAssistant
  static final OpenAiAssistant _instance = OpenAiAssistant._();
  OpenAiAssistant._();
  static OpenAiAssistant get instance => _instance;
  final createEphemeralToken = CreateEphemeralToken();
  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  String? ephemeralKey;
  String? model;

  ///First you need to initialize assistant with this function [init], Remember: you need to pass your Open AI api key.
  ///You can pass your prefered [model]. You can check latest models on open ai playground.
  ///you can pass your [instructions] that AI follows.
  ///You can set [voice] and also check playground that how many voices available.
  ///You can set [speed] of AI TTS.
  Future<Map<String, dynamic>?> init({
    required String apiKey,
    String? model,
    String? instructions,
    String? voice,
    double? speed,
    List<Map<String, dynamic>>? tools,
  }) async {
    final sessionMap = await createEphemeralToken.createEmpheralToken(
      apiKey,
      instructions: instructions,
      model: model,
      speed: speed,
      tools: tools,
      voice: voice,
    );
    model = model??'gpt-4o-realtime-preview';
    if (sessionMap != null) {
      if (sessionMap['client_secret'] != null) {
        ephemeralKey = sessionMap['client_secret']['value'];
      }
    }
    return sessionMap;
  }

  Future<void> start() async {
    if (ephemeralKey == null) {
      throw ErrorDescription('You forget to call init()!');
    }
    if(Platform.isAndroid){
    final status = await Permission.microphone.request();
    if(status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied){
      throw ErrorDescription('Permission denied $status');
    }
    }else{
      await Permission.microphone.request();
    }
    await _initAudioSession();
    await _initWebRTC();
  }

  ///[_initAudioSession] enable main speaker on android and ios
  Future _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.setActive(true); // Activate session before playback
    await Future.delayed(const Duration(milliseconds: 300));

    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions
                .defaultToSpeaker | // or without this for earpiece
            AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  Future _initWebRTC({
    dynamic Function(RTCDataChannelMessage)? onDataChannelMessage,
  }) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    _pc = await createPeerConnection(config);
    _pc!.onIceConnectionState = (state) => print('ICE state: $state');
    _pc!.onConnectionState = (state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        Future.delayed(const Duration(milliseconds: 1000), () async {
          await Helper.setSpeakerphoneOn(true);
        });
      }
      debugPrint('PC state: $state');
    };
    // Create data channel for events & control messages
    _dataChannel = await _pc!.createDataChannel(
      'oai-events',
      RTCDataChannelInit(),
    );
    _dataChannel!.onMessage = onDataChannelMessage;
    _dataChannel!.onDataChannelState = (state) =>
        debugPrint('Data channel state: $state');
    // Get user media with AEC/NS/AGC enabled
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        // channelCount and sampleRate constraints may or may not be honored on all platforms
        'channelCount': 1,
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    // When remote tracks arrive, flutter_webrtc will play them automatically on most mobile platforms.
    _pc!.onTrack = (RTCTrackEvent event) {
      debugPrint('Remote track(s) received: ${event.streams.length}');
      // If you need to attach to a widget, you can create an RTCVideoRenderer for video.
    };
    // Add local audio tracks to PeerConnection
    _localStream!.getAudioTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });
    // Create SDP offer
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // POST offer to OpenAI Realtime WebRTC endpoint with ephemeral key
    final sdpUrl = 'https://api.openai.com/v1/realtime?model=$model';
    final resp = await http.post(
      Uri.parse(sdpUrl),
      headers: {
        'Authorization': 'Bearer $ephemeralKey',
        'Content-Type': 'application/sdp',
      },
      body: offer.sdp,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('SDP exchange failed: ${resp.statusCode} ${resp.body}');
    }

    final answerSdp = resp.body;
    // Future.delayed(const Duration(seconds: 2), () async {
    await _pc!.setRemoteDescription(RTCSessionDescription(answerSdp, 'answer'));
    // });

    debugPrint('WebRTC handshake completed. Data channel and audio should flow.');
  }

  Future<void> stop() async {
    try {
      await _localStream?.dispose();
      await _dataChannel?.close();
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    _localStream = null;
    _dataChannel = null;
  }
  Future disposeAll() async {
    await stop();
  }
}
